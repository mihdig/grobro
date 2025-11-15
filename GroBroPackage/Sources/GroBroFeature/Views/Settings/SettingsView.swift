import SwiftUI
import GroBroDomain

struct SettingsView: View {
    @Environment(ProEntitlementManager.self) private var proManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.deepBackground.ignoresSafeArea()

            List {
                Section("Integrations") {
                    NavigationLink {
                        DeviceIntegrationsView()
                    } label: {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.electricGreen)

                            Text("Device Integrations")
                                .foregroundColor(.primaryText)
                        }
                    }
                    .listRowBackground(Color.surfaceDark.opacity(0.5))
                }

                Section("Account") {
                    HStack {
                        Text("Subscription")
                            .foregroundColor(.primaryText)

                        Spacer()

                        Text(proManager.isPro ? "Pro" : "Free")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    .listRowBackground(Color.surfaceDark.opacity(0.5))
                }

                Section("About") {
                    HStack {
                        Text("App Version")
                            .foregroundColor(.primaryText)

                        Spacer()

                        Text("1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    .listRowBackground(Color.surfaceDark.opacity(0.5))
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        let deviceStore = DeviceStore.preview
        let envStore = EnvironmentalDataStore(deviceStore: deviceStore)

        SettingsView()
            .environment(ProEntitlementManager())
            .environment(deviceStore)
            .environment(envStore)
    }
}
