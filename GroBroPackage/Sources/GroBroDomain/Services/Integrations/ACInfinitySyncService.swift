import Foundation

/// Service responsible for orchestrating AC Infinity data sync and mapping devices to plants.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
@Observable
public final class ACInfinitySyncService {

    private enum Keys {
        static let deviceMappings = "com.grobro.integrations.acinfinity.deviceMappings"
        static let linkedEmail = "com.grobro.integrations.acinfinity.email"
    }

    // MARK: - Dependencies

    private let apiClient: ACInfinityAPIClient
    private let eventStore: EventStore
    private let plantStore: PlantStore
    private let keychain: KeychainManager
    private let userDefaults: UserDefaults

    // MARK: - Published state

    public private(set) var isLinked: Bool
    public private(set) var linkedEmail: String?
    public private(set) var devices: [ACInfinityAPIDevice]
    public private(set) var deviceToPlantIds: [String: [UUID]]
    public private(set) var isSyncing: Bool
    public private(set) var lastSyncDate: Date?
    public private(set) var lastErrorMessage: String?

    // MARK: - Initialization

    public init(
        apiClient: ACInfinityAPIClient = ACInfinityAPIClient(),
        eventStore: EventStore = EventStore(),
        plantStore: PlantStore = PlantStore(),
        keychain: KeychainManager = KeychainManager(service: "com.grobro.integrations.acinfinity"),
        userDefaults: UserDefaults = .standard
    ) {
        self.apiClient = apiClient
        self.eventStore = eventStore
        self.plantStore = plantStore
        self.keychain = keychain
        self.userDefaults = userDefaults

        self.devices = []
        self.isSyncing = false
        self.lastSyncDate = nil
        self.lastErrorMessage = nil

        self.deviceToPlantIds = (userDefaults.object(forKey: Keys.deviceMappings) as? [String: [String]])?
            .reduce(into: [String: [UUID]]()) { result, entry in
                let uuids = entry.value.compactMap { UUID(uuidString: $0) }
                result[entry.key] = uuids
            } ?? [:]

        self.linkedEmail = userDefaults.string(forKey: Keys.linkedEmail)
        self.isLinked = (try? keychain.retrievePassword(account: "token")) != nil
    }

    // MARK: - Account Management

    public func linkAccount(email: String, password: String) async {
        do {
            let token = try await apiClient.login(email: email, password: password)
            try keychain.store(password: token, account: "token")
            try keychain.store(password: email, account: "email")

            userDefaults.set(email, forKey: Keys.linkedEmail)
            linkedEmail = email
            isLinked = true
            lastErrorMessage = nil

            try await loadDevices()
        } catch {
            lastErrorMessage = error.localizedDescription
            isLinked = false
        }
    }

    public func unlinkAccount() {
        do {
            try keychain.deletePassword(account: "token")
            try keychain.deletePassword(account: "email")
        } catch {
            lastErrorMessage = error.localizedDescription
        }

        userDefaults.removeObject(forKey: Keys.linkedEmail)
        linkedEmail = nil
        isLinked = false
        devices = []
        deviceToPlantIds = [:]
        persistMappings()
    }

    // MARK: - Device Management

    public func loadDevices() async throws {
        guard let token = try keychain.retrievePassword(account: "token") else {
            throw ACInfinityAPIClient.APIError.unauthorized
        }

        do {
            let fetchedDevices = try await apiClient.fetchDevices(token: token)
            devices = fetchedDevices
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

    // MARK: - Sync

    public func syncNow() async {
        guard !isSyncing else { return }
        guard let token = try? keychain.retrievePassword(account: "token") ?? nil else {
            lastErrorMessage = "AC Infinity account not linked."
            return
        }

        isSyncing = true
        lastErrorMessage = nil

        do {
            if devices.isEmpty {
                try await loadDevices()
            }

            for device in devices {
                let mappedPlantIds = deviceToPlantIds[device.id] ?? []
                guard !mappedPlantIds.isEmpty else { continue }

                let reading = try await apiClient.fetchSensorReading(token: token, deviceId: device.id)

                for plantId in mappedPlantIds {
                    try createEnvironmentEvent(
                        plantId: plantId,
                        device: device,
                        reading: reading
                    )
                }
            }

            lastSyncDate = Date()
        } catch {
            lastErrorMessage = error.localizedDescription
        }

        isSyncing = false
    }

    private func createEnvironmentEvent(
        plantId: UUID,
        device: ACInfinityAPIDevice,
        reading: ACInfinitySensorReading
    ) throws {
        let event = Event(
            plantId: plantId,
            type: .environment,
            timestamp: Date(),
            noteText: "AC Infinity reading from \(device.name)",
            stressTags: [],
            source: .acInfinity,
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
            lastErrorMessage = "Failed to create environment event: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private func persistMappings() {
        let stringMappings: [String: [String]] = deviceToPlantIds.mapValues { ids in
            ids.map { $0.uuidString }
        }
        userDefaults.set(stringMappings, forKey: Keys.deviceMappings)
    }
}

