import SwiftUI
import GroBroFeature
import GroBroDomain
import GroBroPersistence

@main
struct AppEntry: App {
    // Initialize persistence controller once at app startup
    @MainActor
    private let persistenceController = PersistenceController.shared

    // Initialize Pro entitlement manager
    @MainActor
    @State private var proManager = ProEntitlementManager()

    // NEW: Smart Greenhouse stores
    @MainActor
    @State private var deviceStore = DeviceStore()

    @MainActor
    @State private var environmentalDataStore: EnvironmentalDataStore

    // Onboarding manager
    @MainActor
    @State private var onboardingManager = OnboardingManager()

    @MainActor
    private var plantStore: PlantStore {
        PlantStore(persistenceController: persistenceController)
    }

    @MainActor
    private var eventStore: EventStore {
        EventStore(persistenceController: persistenceController)
    }

    init() {
        // Initialize device store first
        let deviceStore = DeviceStore()
        self._deviceStore = State(initialValue: deviceStore)

        // Initialize environmental data store with device store dependency
        self._environmentalDataStore = State(
            initialValue: EnvironmentalDataStore(deviceStore: deviceStore)
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Smart Greenhouse dark background
                Color.deepBackground
                    .ignoresSafeArea()

                if onboardingManager.shouldShowOnboarding {
                    WelcomeView()
                } else {
                    GardenContainerView(plantStore: plantStore, eventStore: eventStore)
                }
            }
            .environment(\.managedObjectContext, persistenceController.viewContext)
            .environment(proManager)
            .environment(deviceStore)              // Smart Greenhouse
            .environment(environmentalDataStore)   // Smart Greenhouse
            .environment(onboardingManager)        // Onboarding
            .preferredColorScheme(.dark)  // Force dark mode for Smart Greenhouse aesthetic
        }
    }
}
