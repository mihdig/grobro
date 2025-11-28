import SwiftUI
import GroBroDomain

@available(iOS 17.0, macOS 14.0, *)
public struct VivosunSettingsView: View {

    @Environment(ProEntitlementManager.self) private var proManager
    @State private var syncService: VivosunSyncService

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLinking: Bool = false
    @State private var plants: [Plant] = []

    private let plantStore: PlantStore

    public init() {
        let plantStore = PlantStore()
        self.plantStore = plantStore
        _syncService = State(initialValue: VivosunSyncService())
    }

    public var body: some View {
        List {
            if !proManager.isPro {
                Section {
                    Text("Vivosun integration is available for GroBro Pro subscribers.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        // Upgrade handled upstream
                    } label: {
                        HStack {
                            Spacer()
                            Text("Upgrade to Pro")
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
                }
            } else {
                accountSection
                devicesSection
                preferencesSection
                manualFallbackSection

                if let error = syncService.lastErrorMessage, !error.isEmpty {
                    Section("Errors") {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("Vivosun")
        .task {
            loadInitialPlants()
        }
    }

    private var accountSection: some View {
        Section("Account") {
            if syncService.isLinked {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connected as \(syncService.linkedEmail ?? "Unknown")")
                    if let lastSync = syncService.lastSyncDate {
                        Text("Last sync: \(lastSync, style: .relative) ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No syncs have run yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button(role: .destructive) {
                    syncService.unlinkAccount()
                } label: {
                    Text("Disconnect Account")
                }

                Button {
                    Task { await syncService.syncNow() }
                } label: {
                    HStack {
                        if syncService.isSyncing {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("Sync Now")
                        Spacer()
                    }
                }
                .disabled(syncService.isSyncing)
            } else {
                TextField("Email", text: $email)
                    .emailKeyboard()
                    .autocorrectionDisabled(true)

                SecureField("Password", text: $password)

                Button {
                    Task { await linkAccount() }
                } label: {
                    HStack {
                        if isLinking {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("Connect")
                        Spacer()
                    }
                }
                .disabled(isLinking || email.isEmpty || password.isEmpty)
            }
        }
    }

    private var devicesSection: some View {
        Section("Devices") {
            if !syncService.isLinked {
                Text("Connect your Vivosun account to see controllers and sensors.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if syncService.devices.isEmpty {
                Text("No devices found. After linking, tap Sync Now to refresh the device list.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(syncService.devices) { device in
                    NavigationLink {
                        VivosunDeviceAssociationView(
                            device: device,
                            plants: plants,
                            initialSelection: Set(syncService.deviceToPlantIds[device.id] ?? []),
                            onSave: { selection in
                                syncService.updateMapping(for: device.id, plantIds: Array(selection))
                            }
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(device.name)
                            HStack(spacing: 6) {
                                Text(device.deviceType.rawValue.capitalized)
                                if let location = device.location, !location.isEmpty {
                                    Text("•")
                                    Text(location)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            let statusText = device.isOnline ? "Online" : "Offline"
                            Text(statusText)
                                .font(.caption2)
                                .foregroundStyle(device.isOnline ? .green : .secondary)

                            if let mapped = syncService.deviceToPlantIds[device.id],
                               !mapped.isEmpty {
                                let names = plants
                                    .filter { mapped.contains($0.id) }
                                    .map(\.name)
                                    .joined(separator: ", ")
                                Text("Linked to: \(names)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Not linked to any plants")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var preferencesSection: some View {
        Section("Sync Preferences") {
            Picker("Sync Frequency", selection: Binding(
                get: { syncService.syncIntervalMinutes },
                set: { syncService.updateSyncInterval(minutes: $0) }
            )) {
                ForEach([5, 10, 15], id: \.self) { value in
                    Text("Every \(value) min").tag(value)
                }
            }

            if plants.isEmpty {
                Text("Add plants to manage per-plant sync preferences.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(plants) { plant in
                    Toggle(isOn: Binding(
                        get: { !syncService.disabledPlantIds.contains(plant.id) },
                        set: { syncService.setSyncEnabled($0, for: plant.id) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plant.name)
                            Text("Sync environmental data for this plant")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var manualFallbackSection: some View {
        Section("Manual Logging") {
            Text("If the Vivosun API is unavailable, you can still log temperature, humidity, or notes directly from the Diary tab. Those manual entries appear alongside synced events.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        }
    }

    // MARK: - Helpers

    private func loadInitialPlants() {
        do {
            plants = try plantStore.fetchPlants()
        } catch {
            // Soft fail; settings screen will simply not show plant list
        }
    }

    private func linkAccount() async {
        isLinking = true
        await syncService.linkAccount(email: email, password: password)
        isLinking = false
        if syncService.isLinked {
            email = ""
            password = ""
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct VivosunDeviceAssociationView: View {
    let device: VivosunDevice
    let plants: [Plant]
    @State private var selection: Set<UUID>
    let onSave: (Set<UUID>) -> Void

    init(
        device: VivosunDevice,
        plants: [Plant],
        initialSelection: Set<UUID>,
        onSave: @escaping (Set<UUID>) -> Void
    ) {
        self.device = device
        self.plants = plants
        self._selection = State(initialValue: initialSelection)
        self.onSave = onSave
    }

    var body: some View {
        List {
            Section {
                ForEach(plants) { plant in
                    Button {
                        toggleSelection(for: plant.id)
                    } label: {
                        HStack {
                            Text(plant.name)
                            Spacer()
                            if selection.contains(plant.id) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(device.name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(selection)
                }
            }
        }
    }

    private func toggleSelection(for id: UUID) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }
}

#if DEBUG
@available(iOS 17.0, macOS 14.0, *)
#Preview {
    NavigationStack {
        VivosunSettingsView()
            .environment(ProEntitlementManager())
    }
}
#endif
