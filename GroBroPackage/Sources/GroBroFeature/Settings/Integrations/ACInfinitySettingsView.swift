import SwiftUI
import GroBroDomain

@available(iOS 17.0, macOS 14.0, *)
public struct ACInfinitySettingsView: View {

    @Environment(ProEntitlementManager.self) private var proManager
    @State private var syncService: ACInfinitySyncService

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLinking: Bool = false
    @State private var plants: [Plant] = []

    private let plantStore: PlantStore

    public init() {
        let plantStore = PlantStore()
        self.syncService = ACInfinitySyncService(plantStore: plantStore)
        self.plantStore = plantStore
    }

    public var body: some View {
        List {
            if !proManager.isPro {
                Section {
                    Text("AC Infinity integration is available for GroBro Pro subscribers.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        // Upgrade handled by parent sheet
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

                if let error = syncService.lastErrorMessage, !error.isEmpty {
                    Section("Errors") {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("AC Infinity")
        .task {
            loadInitialState()
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
                    }
                }

                Button(role: .destructive) {
                    syncService.unlinkAccount()
                } label: {
                    Text("Disconnect Account")
                }

                Button {
                    Task {
                        await syncService.syncNow()
                    }
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
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)

                SecureField("Password", text: $password)

                Button {
                    Task {
                        await linkAccount()
                    }
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
            if syncService.devices.isEmpty {
                Text("No devices found. After connecting your account, pull to refresh or tap Sync Now.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(syncService.devices) { device in
                    NavigationLink {
                        DeviceToPlantAssociationView(
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
                            Text(device.type)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let mapped = syncService.deviceToPlantIds[device.id],
                               !mapped.isEmpty {
                                let names = plants
                                    .filter { mapped.contains($0.id) }
                                    .map { $0.name }
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

    private func loadInitialState() {
        do {
            plants = try plantStore.fetchPlants()
        } catch {
            // For settings screen we fail soft; error surfaced via sync service if needed
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
struct DeviceToPlantAssociationView: View {

    let device: ACInfinityAPIDevice
    let plants: [Plant]
    @State var selection: Set<UUID>
    let onSave: (Set<UUID>) -> Void

    init(
        device: ACInfinityAPIDevice,
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
                    MultipleSelectionRow(
                        title: plant.name,
                        isSelected: selection.contains(plant.id)
                    ) {
                        toggleSelection(for: plant.id)
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

@available(iOS 17.0, macOS 14.0, *)
private struct MultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 17.0, macOS 14.0, *)
#Preview {
    NavigationStack {
        ACInfinitySettingsView()
            .environment(ProEntitlementManager())
    }
}
#endif

