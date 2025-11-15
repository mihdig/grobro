import Foundation
import GroBroDomain

@MainActor
public final class GardenViewModel: ObservableObject {
    @Published public var plants: [Plant] = []
    @Published public var showError: Bool = false
    @Published public var errorMessage: String = ""
    @Published public var wateringStatuses: [UUID: WateringStatus] = [:]

    private let plantStore: PlantStore
    private let wateringService: WateringService

    public init(plantStore: PlantStore, wateringService: WateringService) {
        self.plantStore = plantStore
        self.wateringService = wateringService
    }

    /// Convenience initializer for when EventStore is available
    public convenience init(plantStore: PlantStore, eventStore: EventStore) {
        let wateringService = WateringService(eventStore: eventStore)
        self.init(plantStore: plantStore, wateringService: wateringService)
    }

    public func loadPlants() {
        do {
            plants = try plantStore.fetchPlants()
            loadWateringStatuses()
        } catch {
            errorMessage = "Failed to load plants: \(error.localizedDescription)"
            showError = true
        }
    }

    /// Loads watering statuses for all plants
    private func loadWateringStatuses() {
        for plant in plants {
            do {
                if let status = try wateringService.getWateringStatus(for: plant) {
                    wateringStatuses[plant.id] = status
                }
            } catch {
                // Log error but don't fail the whole load
                print("Failed to load watering status for plant \(plant.id): \(error)")
            }
        }
    }

    /// Gets the watering status message for a plant
    /// - Parameter plant: The plant to check
    /// - Returns: User-friendly status message or nil if no watering scheduled yet
    public func wateringStatusMessage(for plant: Plant) -> String? {
        wateringStatuses[plant.id]?.statusMessage
    }

    public func makeCreationViewModel() -> PlantCreationViewModel {
        let viewModel = PlantCreationViewModel(plantStore: plantStore)
        viewModel.onPlantCreated = { [weak self] _ in
            self?.loadPlants()
        }
        return viewModel
    }

    public func makeDetailViewModel(for plant: Plant) -> PlantDetailViewModel {
        PlantDetailViewModel(plant: plant, plantStore: plantStore, wateringService: wateringService)
    }
}
