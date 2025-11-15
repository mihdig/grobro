import SwiftUI
import GroBroDomain

@available(iOS 17.0, macOS 14.0, *)
struct SyncDebugLogView: View {

    @State var syncService: CloudKitSyncService

    var body: some View {
        List {
            Section {
                Button {
                    syncService.runIntegrityCheck()
                } label: {
                    Label("Run Integrity Check", systemImage: "stethoscope")
                }

                Button(role: .destructive) {
                    syncService.clearConflicts()
                } label: {
                    Label("Clear Log", systemImage: "trash")
                }
            }

            if syncService.conflicts.isEmpty {
                Section {
                    Text("No conflicts recorded yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Conflicts") {
                    ForEach(syncService.conflicts) { conflict in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(conflict.entityName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                if conflict.isCritical {
                                    Text("Critical")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundStyle(.red)
                                        .clipShape(Capsule())
                                }
                            }

                            Text(conflict.description)
                                .font(.caption)

                            HStack {
                                if let id = conflict.entityId {
                                    Text("ID: \(id.uuidString)")
                                }
                                Spacer()
                                Text(conflict.date, style: .relative)
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Sync Debug Log")
    }
}

#if DEBUG
import GroBroPersistence

@available(iOS 17.0, macOS 14.0, *)
#Preview {
    let container = PersistenceController.shared.container
    let service = CloudKitSyncService(container: container)
    NavigationStack {
        SyncDebugLogView(syncService: service)
    }
}
#endif

