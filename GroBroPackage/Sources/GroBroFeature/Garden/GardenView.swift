import SwiftUI
import GroBroDomain

@available(iOS 17.0, *)
public struct GardenView: View {
    fileprivate enum LegalAction {
        case none
        case createPlant
        case createDemoPlant
    }

    private enum GardenRoute: Hashable {
        case plantDetail(id: UUID, tab: DeepLinkDestination.PlantTab?)
    }

    @StateObject private var viewModel: GardenViewModel
    @Environment(ProEntitlementManager.self) private var proManager
    @Environment(OnboardingManager.self) private var onboardingManager
    @Environment(WidgetSyncService.self) private var widgetSyncService
    @AppStorage("hasSeenAddPlantTooltip") private var hasSeenAddPlantTooltip: Bool = false
    private let deepLinkBinding: Binding<DeepLinkDestination?>
    @State private var navigationPath = NavigationPath()
    @State private var showingCreatePlant = false
    @State private var showingUpgradePrompt = false
    @State private var showingSettings = false
    @State private var showingLegalDisclaimer = false
    @State private var showAddPlantTooltip = false
    @State private var pendingLegalAction: LegalAction = .none
    @State private var pendingDeepLink: DeepLinkDestination?

    public init(
        viewModel: GardenViewModel,
        deepLink: Binding<DeepLinkDestination?> = .constant(nil)
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.deepLinkBinding = deepLink
    }

    public var body: some View {
        navigationStackView
    }

    private var navigationStackView: some View {
        NavigationStack(path: $navigationPath) {
            contentView
                .navigationTitle("My Garden")
                .toolbar { toolbarContent() }
                .modifier(SheetsModifier(
                    showingCreatePlant: $showingCreatePlant,
                    showingLegalDisclaimer: $showingLegalDisclaimer,
                    showingUpgradePrompt: $showingUpgradePrompt,
                    showingSettings: $showingSettings,
                    pendingLegalAction: $pendingLegalAction,
                    viewModel: viewModel,
                    onboardingManager: onboardingManager
                ))
                .modifier(LifecycleModifier(
                    viewModel: viewModel,
                    showAddTooltip: maybeShowAddPlantTooltip
                ))
                .modifier(ObserversModifier(
                    deepLinkBinding: deepLinkBinding,
                    plants: viewModel.plants,
                    wateringStatuses: viewModel.wateringStatuses,
                    isPro: proManager.isPro,
                    onDeepLinkChange: { destination in
                        guard let destination else { return }
                        pendingDeepLink = destination
                        processPendingDeepLinkIfNeeded()
                    },
                    onPlantsChange: {
                        syncWidgetsIfPossible()
                        processPendingDeepLinkIfNeeded()
                    },
                    onWateringChange: syncWidgetsIfPossible,
                    onProChange: syncWidgetsIfPossible
                ))
                .navigationDestination(for: GardenRoute.self, destination: navigationDestination)
        }
    }

    private var contentView: some View {
        ZStack {
            if viewModel.plants.isEmpty {
                emptyStateView
            } else {
                plantListView
            }
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
        }
        #else
        ToolbarItem {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
        }
        #endif

        if !proManager.isPro && !viewModel.plants.isEmpty {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("My Garden")
                        .font(.headline)
                    Text("\(viewModel.plants.count) of \(ProEntitlementManager.freeTierPlantLimit) plants")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                handleAddPlant()
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    private func navigationDestination(for route: GardenRoute) -> some View {
        Group {
            switch route {
            case let .plantDetail(id, tab):
                if let plant = viewModel.plants.first(where: { $0.id == id }) {
                    PlantDetailView(
                        viewModel: viewModel.makeDetailViewModel(for: plant),
                        initialTab: tabIndex(for: tab)
                    )
                } else {
                    MissingPlantView()
                }
            }
        }
    }

    private func handleAddPlant() {
        if !onboardingManager.hasAcceptedTerms {
            pendingLegalAction = .createPlant
            showingLegalDisclaimer = true
            return
        }

        let currentCount = viewModel.plants.count
        if proManager.canCreatePlant(currentPlantCount: currentCount) {
            showingCreatePlant = true
        } else {
            showingUpgradePrompt = true
        }
    }

    private func maybeShowAddPlantTooltip() {
        guard viewModel.plants.isEmpty,
              !hasSeenAddPlantTooltip,
              onboardingManager.hasCompletedWelcome,
              !onboardingManager.hasCreatedFirstPlant
        else { return }

        showAddPlantTooltip = true
    }

    private func handleAddDemoPlant() {
        if !onboardingManager.hasAcceptedTerms {
            pendingLegalAction = .createDemoPlant
            showingLegalDisclaimer = true
            return
        }

        let didCreate = viewModel.createDemoPlantIfNeeded()
        if didCreate {
            onboardingManager.completeFirstPlant()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 64))
                .foregroundColor(.electricGreen)
                .shadow(color: .electricGreen.opacity(0.4), radius: 20)

            Text("No Plants Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)

            Text("Create your first plant to start tracking your grow")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if showAddPlantTooltip {
                GlassCard(elevation: .subtle, cornerRadius: 14, padding: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.electricGreen)
                            .font(.system(size: 20))

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Start with your first plant")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primaryText)

                            Text("Tap “Add First Plant” to walk through the guided setup and see how GroBro tracks your grow.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondaryText)

                            Button {
                                hasSeenAddPlantTooltip = true
                                showAddPlantTooltip = false
                            } label: {
                                Text("Got it")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.electricGreen)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            NeonButton("Add First Plant", style: .primary, fullWidth: false) {
                handleAddPlant()
            }
            .padding(.horizontal, 40)

            NeonButton("Explore Demo Plant", style: .secondary, fullWidth: false) {
                handleAddDemoPlant()
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }

    private var plantListView: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.plants) { plant in
                        NavigationLink(value: GardenRoute.plantDetail(id: plant.id, tab: nil)) {
                            PlantRowView(
                                plant: plant,
                                wateringStatusMessage: viewModel.wateringStatusMessage(for: plant)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            if viewModel.plants.count >= ProEntitlementManager.freeTierPlantLimit && !proManager.isPro {
                VStack {
                    Spacer()
                    if #available(iOS 18.0, macOS 15.0, *) {
                        ProFeaturePromptView(promptType: .gardenPlantLimit) {
                            showingUpgradePrompt = true
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .background(
                            LinearGradient(
                                colors: [.clear, Color(red: 1, green: 1, blue: 1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 100)
                            .allowsHitTesting(false),
                            alignment: .bottom
                        )
                    }
                }
            }
        }
    }

    private func processPendingDeepLinkIfNeeded() {
        guard let destination = pendingDeepLink else { return }
        if viewModel.plants.isEmpty && destination.requiresPlant {
            return
        }

        navigate(to: destination)
        pendingDeepLink = nil
        deepLinkBinding.wrappedValue = nil
    }

    private func navigate(to destination: DeepLinkDestination) {
        switch destination {
        case .garden:
            navigationPath = NavigationPath()
        case .createPlant:
            handleAddPlant()
        case let .plantDetail(id, tab):
            openPlantDetail(id: id, tab: tab)
        case let .watering(plantID):
            let resolvedID = plantID ?? viewModel.plants.first?.id
            openPlantDetail(id: resolvedID, tab: .watering)
        case let .diagnostics(plantID):
            let resolvedID = plantID ?? viewModel.plants.first?.id
            openPlantDetail(id: resolvedID, tab: .diagnostics)
        }
    }

    private func openPlantDetail(id: UUID?, tab: DeepLinkDestination.PlantTab?) {
        guard let id else { return }
        if !viewModel.plants.contains(where: { $0.id == id }) {
            pendingDeepLink = .plantDetail(id: id, tab: tab)
            return
        }

        navigationPath = NavigationPath()
        let route = GardenRoute.plantDetail(id: id, tab: tab)
        navigationPath.append(route)
    }

    private func tabIndex(for tab: DeepLinkDestination.PlantTab?) -> Int {
        switch tab {
        case .watering:
            return 1
        case .diagnostics:
            return 2
        case .diary:
            return 6
        default:
            return 0
        }
    }

    private func syncWidgetsIfPossible() {
        widgetSyncService.publish(
            plants: viewModel.plants,
            wateringStatuses: viewModel.wateringStatuses,
            isProUser: proManager.isPro
        )
    }
}

private extension DeepLinkDestination {
    var requiresPlant: Bool {
        switch self {
        case .plantDetail, .watering, .diagnostics:
            return true
        default:
            return false
        }
    }
}

private struct MissingPlantView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.slash")
                .font(.largeTitle)
                .foregroundColor(.tertiaryText)
            Text("Plant Not Found")
                .font(.headline)
            Text("It may have been deleted or archived.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
 
@available(iOS 17.0, *)
struct PlantRowView: View {
    let plant: Plant
    let wateringStatusMessage: String?

    var body: some View {
        GlassCard(padding: 16) {
            HStack(spacing: 16) {
                // Plant photo with glassmorphic border
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.electricGreen.opacity(0.3), Color.sageGreen.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.electricGreen)
                        }

                    // Health status indicator
                    Circle()
                        .fill(Color.successGreen)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.surfaceDark, lineWidth: 2)
                        )
                        .shadow(color: .successGreen.opacity(0.6), radius: 4)
                        .offset(x: 4, y: 4)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(plant.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primaryText)

                    Text(plant.stage.displayName)
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)

                    HStack(spacing: 12) {
                        Label {
                            Text("Day \(plant.ageInDays)")
                                .font(.system(size: 12, design: .monospaced))
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .foregroundColor(.tertiaryText)

                        if let wateringMessage = wateringStatusMessage {
                            Label {
                                Text(wateringMessage)
                                    .font(.system(size: 12))
                            } icon: {
                                Image(systemName: "drop.fill")
                            }
                            .foregroundColor(wateringMessage.contains("overdue") ? .criticalRed : .cyanBright)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.tertiaryText)
            }
        }
    }
}

// MARK: - Sheets Modifier

private struct SheetsModifier: ViewModifier {
    @Binding var showingCreatePlant: Bool
    @Binding var showingLegalDisclaimer: Bool
    @Binding var showingUpgradePrompt: Bool
    @Binding var showingSettings: Bool
    @Binding var pendingLegalAction: GardenView.LegalAction
    let viewModel: GardenViewModel
    let onboardingManager: OnboardingManager

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showingCreatePlant) {
                PlantCreationView(viewModel: viewModel.makeCreationViewModel())
            }
            .sheet(isPresented: $showingLegalDisclaimer) {
                if #available(iOS 17.0, *) {
                    LegalDisclaimerView {
                        switch pendingLegalAction {
                        case .createPlant:
                            showingCreatePlant = true
                        case .createDemoPlant:
                            let didCreate = viewModel.createDemoPlantIfNeeded()
                            if didCreate {
                                onboardingManager.completeFirstPlant()
                            }
                        case .none:
                            break
                        }
                        pendingLegalAction = .none
                    }
                }
            }
            .sheet(isPresented: $showingUpgradePrompt) {
                if #available(iOS 18.0, macOS 15.0, *) {
                    UpgradeToProView()
                } else {
                    UpgradePromptView()
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                }
            }
    }
}

// MARK: - Lifecycle Modifier

private struct LifecycleModifier: ViewModifier {
    let viewModel: GardenViewModel
    let showAddTooltip: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                viewModel.loadPlants()
                showAddTooltip()
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.showError },
                set: { viewModel.showError = $0 }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
    }
}

// MARK: - Observers Modifier

private struct ObserversModifier: ViewModifier {
    let deepLinkBinding: Binding<DeepLinkDestination?>
    let plants: [Plant]
    let wateringStatuses: [UUID: WateringStatus]
    let isPro: Bool
    let onDeepLinkChange: (DeepLinkDestination?) -> Void
    let onPlantsChange: () -> Void
    let onWateringChange: () -> Void
    let onProChange: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: deepLinkBinding.wrappedValue, perform: onDeepLinkChange)
            .onChange(of: plants.count) { _ in onPlantsChange() }
            .onChange(of: wateringStatuses.count) { _ in onWateringChange() }
            .onChange(of: isPro) { _ in onProChange() }
    }
}
