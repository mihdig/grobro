import Foundation

/// Service responsible for linking Vivosun accounts, scheduling syncs, and creating events.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
@Observable
public final class VivosunSyncService {

    private enum DefaultsKeys {
        static let deviceMappings = "com.grobro.integrations.vivosun.deviceMappings"
        static let disabledPlants = "com.grobro.integrations.vivosun.disabledPlants"
        static let linkedEmail = "com.grobro.integrations.vivosun.email"
        static let syncInterval = "com.grobro.integrations.vivosun.syncInterval"
    }

    private enum KeychainKeys {
        static let token = "token"
        static let email = "email"
    }

    nonisolated private let apiClient: VivosunAPIProviding
    private let eventStore: EventStore
    private let keychain: KeychainManaging
    private let userDefaults: UserDefaults
    private var backgroundTask: Task<Void, Never>?

    // MARK: - Published state

    public private(set) var isLinked: Bool
    public private(set) var linkedEmail: String?
    public private(set) var devices: [VivosunDevice]
    public private(set) var deviceToPlantIds: [String: [UUID]]
    public private(set) var disabledPlantIds: Set<UUID>
    public private(set) var syncIntervalMinutes: Int
    public private(set) var isSyncing: Bool
    public private(set) var lastSyncDate: Date?
    public private(set) var lastErrorMessage: String?

    private let minimumIntervalMinutes = 5
    private let maximumIntervalMinutes = 15
    private let defaultIntervalMinutes = 10

    // MARK: - Initialization

    public init(
        apiClient: VivosunAPIProviding = VivosunAPIClient(),
        eventStore: EventStore = EventStore(),
        keychain: KeychainManaging = KeychainManager(service: "com.grobro.integrations.vivosun"),
        userDefaults: UserDefaults = .standard
    ) {
        self.apiClient = apiClient
        self.eventStore = eventStore
        self.keychain = keychain
        self.userDefaults = userDefaults

        self.devices = []
        self.deviceToPlantIds = Self.restoreMappings(from: userDefaults.object(forKey: DefaultsKeys.deviceMappings))
        self.disabledPlantIds = Self.restoreDisabledPlants(from: userDefaults.array(forKey: DefaultsKeys.disabledPlants))
        let storedInterval = userDefaults.integer(forKey: DefaultsKeys.syncInterval)
        self.syncIntervalMinutes = storedInterval > 0 ? storedInterval : defaultIntervalMinutes
        self.isSyncing = false
        self.lastSyncDate = nil
        self.lastErrorMessage = nil
        self.linkedEmail = userDefaults.string(forKey: DefaultsKeys.linkedEmail)

        let hasToken = (try? keychain.retrievePassword(account: KeychainKeys.token)) != nil
        self.isLinked = hasToken

        if isLinked {
            startAutomaticSync()
        }
    }

    // Note: backgroundTask is automatically cancelled when service is deallocated

    // MARK: - Account Management

    public func linkAccount(email: String, password: String) async {
        do {
            let token = try await apiClient.authenticate(email: email, password: password)
            try keychain.store(password: token, account: KeychainKeys.token)
            try keychain.store(password: email, account: KeychainKeys.email)
            userDefaults.set(email, forKey: DefaultsKeys.linkedEmail)

            linkedEmail = email
            isLinked = true
            lastErrorMessage = nil

            try await loadDevices()
            startAutomaticSync()
        } catch {
            lastErrorMessage = error.localizedDescription
            isLinked = false
        }
    }

    public func unlinkAccount() {
        backgroundTask?.cancel()
        backgroundTask = nil

        do {
            try keychain.deletePassword(account: KeychainKeys.token)
            try keychain.deletePassword(account: KeychainKeys.email)
        } catch {
            lastErrorMessage = error.localizedDescription
        }

        linkedEmail = nil
        isLinked = false
        devices = []
        deviceToPlantIds.removeAll()
        persistMappings()

        disabledPlantIds.removeAll()
        persistDisabledPlants()
    }

    // MARK: - Device Management

    public func loadDevices() async throws {
        guard let token = try keychain.retrievePassword(account: KeychainKeys.token) else {
            throw VivosunAPIClient.APIError.unauthorized
        }

        do {
            let fetched = try await apiClient.fetchDevices(token: token)
            devices = fetched
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    public func updateMapping(for deviceId: String, plantIds: [UUID]) {
        deviceToPlantIds[deviceId] = plantIds
        persistMappings()
    }

    public func setSyncEnabled(_ isEnabled: Bool, for plantId: UUID) {
        if isEnabled {
            disabledPlantIds.remove(plantId)
        } else {
            disabledPlantIds.insert(plantId)
        }
        persistDisabledPlants()
    }

    public func updateSyncInterval(minutes: Int) {
        let clamped = min(max(minutes, minimumIntervalMinutes), maximumIntervalMinutes)
        syncIntervalMinutes = clamped
        userDefaults.set(clamped, forKey: DefaultsKeys.syncInterval)
        startAutomaticSync()
    }

    // MARK: - Syncing

    public func syncNow() async {
        guard !isSyncing else { return }
        guard isLinked else {
            lastErrorMessage = "Connect your Vivosun account to start syncing."
            return
        }
        guard let token = try? keychain.retrievePassword(account: KeychainKeys.token) else {
            lastErrorMessage = "Missing Vivosun credentials."
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        do {
            if devices.isEmpty {
                try await loadDevices()
            }

            for device in devices {
                let mappedPlants = deviceToPlantIds[device.id] ?? []
                guard !mappedPlants.isEmpty else { continue }

                let reading = try await apiClient.fetchSensorReading(token: token, deviceId: device.id)

                for plantId in mappedPlants where isPlantSyncEnabled(plantId) {
                    try createEnvironmentEvent(
                        plantId: plantId,
                        device: device,
                        reading: reading
                    )
                }
            }

            lastSyncDate = Date()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func createEnvironmentEvent(
        plantId: UUID,
        device: VivosunDevice,
        reading: VivosunSensorReading
    ) throws {
        let event = Event(
            plantId: plantId,
            type: .environment,
            timestamp: Date(),
            noteText: "Vivosun reading from \(device.name)",
            source: .vivosun,
            environmentalData: EnvironmentalData(
                temperatureFahrenheit: reading.temperatureFahrenheit,
                humidityPercent: reading.humidityPercent,
                vpdKilopascal: reading.vpdKilopascal
            ),
            lightMeasurement: nil
        )

        do {
            _ = try eventStore.createEvent(event)
        } catch {
            lastErrorMessage = "Failed to log Vivosun data: \(error.localizedDescription)"
        }
    }

    private func isPlantSyncEnabled(_ plantId: UUID) -> Bool {
        !disabledPlantIds.contains(plantId)
    }

    private func startAutomaticSync() {
        backgroundTask?.cancel()
        backgroundTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled && self.isLinked {
                try? await Task.sleep(nanoseconds: UInt64(self.syncIntervalMinutes) * 60 * 1_000_000_000)
                await self.syncNow()
            }
        }
    }

    // MARK: - Persistence Helpers

    private func persistMappings() {
        let stringMappings = deviceToPlantIds.mapValues { ids in
            ids.map { $0.uuidString }
        }
        userDefaults.set(stringMappings, forKey: DefaultsKeys.deviceMappings)
    }

    private func persistDisabledPlants() {
        let ids = disabledPlantIds.map { $0.uuidString }
        userDefaults.set(ids, forKey: DefaultsKeys.disabledPlants)
    }

    private static func restoreMappings(from value: Any?) -> [String: [UUID]] {
        guard let data = value as? [String: [String]] else { return [:] }
        return data.reduce(into: [String: [UUID]]()) { result, entry in
            let uuids = entry.value.compactMap { UUID(uuidString: $0) }
            result[entry.key] = uuids
        }
    }

    private static func restoreDisabledPlants(from value: Any?) -> Set<UUID> {
        guard let strings = value as? [String] else { return [] }
        return Set(strings.compactMap { UUID(uuidString: $0) })
    }
}
