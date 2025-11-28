import SwiftUI
import GroBroDomain

struct SettingsView: View {
    @Environment(ProEntitlementManager.self) private var proManager
    @Environment(OnboardingManager.self) private var onboardingManager
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

                Section("Onboarding") {
                    HStack {
                        Text("Onboarding Status")
                            .foregroundColor(.primaryText)

                        Spacer()

                        Text(onboardingManager.isOnboardingComplete ? "Complete" : "In Progress")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    .listRowBackground(Color.surfaceDark.opacity(0.5))

                    Button {
                        onboardingManager.resetOnboarding()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.electricGreen)
                            Text("Restart Onboarding")
                                .foregroundColor(.electricGreen)
                        }
                    }
                    .listRowBackground(Color.surfaceDark.opacity(0.5))

                    NavigationLink {
                        if #available(iOS 17.0, *) {
                            LegalDisclaimerView()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.electricGreen)

                            Text("View Legal & Terms")
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
        .inlineNavigationTitle()
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
