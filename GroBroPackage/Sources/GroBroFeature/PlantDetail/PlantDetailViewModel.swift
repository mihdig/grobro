import Foundation
import GroBroDomain

@MainActor
public final class PlantDetailViewModel: ObservableObject {
    @Published public var plant: Plant
    @Published public var wateringStatus: WateringStatus?

    private let plantStore: PlantStore
    private let eventStore: EventStore
    private let wateringService: WateringService

    public init(
        plant: Plant,
        plantStore: PlantStore,
        eventStore: EventStore = EventStore(),
        wateringService: WateringService? = nil
    ) {
        self.plant = plant
        self.plantStore = plantStore
        self.eventStore = eventStore
        self.wateringService = wateringService ?? WateringService(eventStore: eventStore)

        loadWateringStatus()
    }

    public func refresh() {
        // Reload plant data from store
        if let updated = try? plantStore.fetchPlant(id: plant.id) {
            plant = updated
        }
        loadWateringStatus()
    }

    /// Loads the watering status for the current plant
    private func loadWateringStatus() {
        do {
            wateringStatus = try wateringService.getWateringStatus(for: plant)
        } catch {
            print("Failed to load watering status: \(error)")
            wateringStatus = nil
        }
    }

    /// Applies user feedback about watering timing
    /// - Parameter feedback: The user's feedback
    public func applyWateringFeedback(_ feedback: WateringFeedback) {
        do {
            try wateringService.applyFeedback(for: plant, feedback: feedback)
            loadWateringStatus()
        } catch {
            print("Failed to apply watering feedback: \(error)")
        }
    }

    public func makeDiaryViewModel() -> DiaryViewModel {
        DiaryViewModel(plantId: plant.id, eventStore: eventStore)
    }

    public func makeDiagnosticsViewModel() -> DiagnosticsViewModel {
        DiagnosticsViewModel(plant: plant)
    }

    public func makeDebugConsoleViewModel() -> DebugConsoleViewModel {
        DebugConsoleViewModel(plant: plant)
    }
}
