import SwiftUI
import GroBroDomain
import GroBroPersistence

/// Settings view for managing Pro subscription
@available(iOS 17.0, macOS 14.0, *)
public struct SubscriptionSettingsView: View {

    @Environment(ProEntitlementManager.self) private var proManager
    @State private var syncService: CloudKitSyncService
    @State private var viewModel: SubscriptionSettingsViewModel
    @State private var showUpgradeSheet = false

    public init() {
        self._viewModel = State(initialValue: SubscriptionSettingsViewModel())
        // Default sync service uses the shared persistence controller container
        let container = PersistenceController.shared.container
        self._syncService = State(
            initialValue: CloudKitSyncService(container: container)
        )
    }

    public var body: some View {
        List {
            // Current Status Section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(proManager.statusMessage)
                            .font(.headline)

                        if let verificationDate = proManager.lastVerificationDate {
                            Text("Last verified: \(verificationDate, style: .relative) ago")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: proManager.isPro ? "checkmark.seal.fill" : "person.circle")
                        .font(.title)
                        .foregroundStyle(proManager.isPro ? .green : .secondary)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Current Plan")
            }

            // Pro Features Section
            if !proManager.isPro {
                Section {
                    ForEach([ProFeature.unlimitedPlants, .advancedAnalytics, .dataExport, .prioritySupport], id: \.displayName) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: featureIcon(for: feature))
                                .font(.title3)
                                .foregroundStyle(.green)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text(feature.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Pro Features")
                } footer: {
                    Text("Unlock all features with GroBro Pro")
                }
            }

            // Subscription Actions Section
            Section {
                if !proManager.isPro {
                    // Upgrade to Pro button
                    Button {
                        showUpgradeSheet = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Upgrade to Pro")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                } else {
                    // Manage Subscription button (for Pro users)
                    Button {
                        viewModel.showManageSubscription = true
                    } label: {
                        HStack {
                            Text("Manage Subscription")
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.caption)
                        }
                    }
                }

                // Restore Purchases button
                Button {
                    Task {
                        await viewModel.restorePurchases()
                    }
                } label: {
                    HStack {
                        if viewModel.isRestoring {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("Restore Purchases")
                        Spacer()
                    }
                }
                .disabled(viewModel.isRestoring)

                // Refresh Status button
                Button {
                    Task {
                        await viewModel.refreshStatus()
                    }
                } label: {
                    HStack {
                        if viewModel.isRefreshing {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("Refresh Status")
                        Spacer()
                    }
                }
                .disabled(viewModel.isRefreshing)
            } header: {
                Text("Subscription Management")
            }

            // iCloud Sync Section (Pro users)
            Section {
                Toggle(isOn: Binding(
                    get: { syncService.isSyncEnabled && proManager.isPro },
                    set: { newValue in
                        if proManager.isPro {
                            if newValue {
                                syncService.enableSync()
                            } else {
                                syncService.disableSync()
                            }
                        } else {
                            showUpgradeSheet = true
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("iCloud Sync")
                        Text(syncStatusSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!proManager.isPro)

                if syncService.isSyncEnabled && proManager.isPro {
                    Button {
                        Task {
                            await syncService.performManualSync()
                        }
                    } label: {
                        HStack {
                            if syncService.status.state == .syncing {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text("Sync Now")
                            Spacer()
                        }
                    }
                    .disabled(syncService.status.state == .syncing)
                }
            } header: {
                Text("Sync & iCloud")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    if !proManager.isPro {
                        Text("iCloud sync is available for GroBro Pro subscribers.")
                    }
                    if let lastDate = syncService.status.lastSyncDate {
                        Text("Last sync: \(lastDate, style: .relative) ago")
                    }
                    if let error = syncService.status.lastError,
                       syncService.status.state == .error {
                        Text("Last error: \(error)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Data & Export Section
            Section {
                NavigationLink {
                    DataExportView()
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
            } header: {
                Text("Data & Export")
            }

            // Integrations Section
            Section {
                NavigationLink {
                    ACInfinitySettingsView()
                } label: {
                    Label("AC Infinity", systemImage: "dot.radiowaves.up.forward")
                }
                NavigationLink {
                    VivosunSettingsView()
                } label: {
                    Label("Vivosun", systemImage: "leaf.circle")
                }
            } header: {
                Text("Integrations")
            }

            // Debug Section (for development builds)
            #if DEBUG
            Section {
                NavigationLink {
                    SyncDebugLogView(syncService: syncService)
                } label: {
                    Label("Sync Debug Log", systemImage: "list.bullet.rectangle")
                }

                Text("Product ID: \(SubscriptionManager.proSubscriptionID)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Status: \(proManager.subscriptionStatus.description)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Debug Info")
            }
            #endif
        }
        .navigationTitle("Subscription")
        .alert("Error", isPresented: Binding(
            get: { viewModel.showError },
            set: { _ in }
        )) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .alert("Success", isPresented: Binding(
            get: { viewModel.showSuccess },
            set: { _ in }
        )) {
            Button("OK") {
                viewModel.successMessage = nil
            }
        } message: {
            if let successMessage = viewModel.successMessage {
                Text(successMessage)
            }
        }
        .task {
            await viewModel.loadProducts()
        }
        #if os(iOS)
        .manageSubscriptionsSheet(isPresented: $viewModel.showManageSubscription)
        #endif
            .sheet(isPresented: $showUpgradeSheet) {
                if #available(iOS 18.0, macOS 15.0, *) {
                    UpgradeToProView()
                }
            }
    }

    private var syncStatusSubtitle: String {
        switch syncService.status.state {
        case .disabled:
            return "Turn on to sync plants and events via iCloud."
        case .idle:
            return "Sync is enabled. Changes sync automatically when online."
        case .syncing:
            return "Syncing with iCloud..."
        case .error:
            return "Last sync encountered an error. Tap Sync Now to retry."
        }
    }

    private func featureIcon(for feature: ProFeature) -> String {
        switch feature {
        case .unlimitedPlants:
            return "leaf.fill"
        case .advancedAnalytics:
            return "chart.xyaxis.line"
        case .dataExport:
            return "square.and.arrow.up"
        case .prioritySupport:
            return "headphones"
        }
    }
}

// MARK: - View Model

@available(iOS 17.0, macOS 14.0, *)
@MainActor
@Observable
final class SubscriptionSettingsViewModel {

    private let subscriptionManager = SubscriptionManager()
    private let proManager = ProEntitlementManager()

    var isLoading = false
    var isRestoring = false
    var isRefreshing = false
    var showManageSubscription = false

    var errorMessage: String?
    var successMessage: String?

    var showError: Bool {
        errorMessage != nil
    }

    var showSuccess: Bool {
        successMessage != nil
    }

    func loadProducts() async {
        await subscriptionManager.loadProducts()
    }

    func upgradeToPro() async {
        guard let product = subscriptionManager.products.first else {
            errorMessage = "Unable to load subscription product. Please try again later."
            return
        }

        isLoading = true
        let success = await subscriptionManager.purchase(product)
        isLoading = false

        if success {
            // Refresh Pro status
            await proManager.refreshProStatus(force: true)
            successMessage = "Welcome to GroBro Pro! You now have unlimited plants and all Pro features."
        } else if let error = subscriptionManager.lastError {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isRestoring = true
        let success = await subscriptionManager.restorePurchases()
        isRestoring = false

        if success {
            // Refresh Pro status
            await proManager.refreshProStatus(force: true)
            successMessage = "Purchases restored successfully! Your Pro subscription is now active."
        } else {
            if let error = subscriptionManager.lastError {
                errorMessage = error.localizedDescription
            } else {
                errorMessage = "No active subscription found to restore."
            }
        }
    }

    func refreshStatus() async {
        isRefreshing = true
        await proManager.refreshProStatus(force: true)
        isRefreshing = false

        successMessage = "Subscription status updated: \(proManager.subscriptionStatus.description)"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubscriptionSettingsView()
            .environment(ProEntitlementManager())
    }
}
