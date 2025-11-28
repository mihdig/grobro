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
    private let eventStore: EventStore?

    public init(plantStore: PlantStore, wateringService: WateringService, eventStore: EventStore? = nil) {
        self.plantStore = plantStore
        self.wateringService = wateringService
        self.eventStore = eventStore
    }

    /// Convenience initializer for when EventStore is available
    public convenience init(plantStore: PlantStore, eventStore: EventStore) {
        let wateringService = WateringService(eventStore: eventStore)
        self.init(plantStore: plantStore, wateringService: wateringService, eventStore: eventStore)
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

    /// Creates a demo plant with sample events if one does not already exist.
    /// Returns true if a demo plant exists or was created successfully.
    @discardableResult
    public func createDemoPlantIfNeeded() -> Bool {
        do {
            // If a demo plant already exists, just reload data.
            let existingPlants = try plantStore.fetchPlants()
            if existingPlants.contains(where: { $0.name == "GroBro Demo Plant" }) {
                plants = existingPlants
                loadWateringStatuses()
                return true
            }

            // Create demo plant
            let demoPlant = Plant(
                name: "GroBro Demo Plant",
                strainName: "Onboarding Sample",
                stage: .vegetative,
                potSizeLiters: 11,
                substrateType: .soil,
                notes: "Sample plant used to demonstrate GroBro features."
            )

            let createdPlant = try plantStore.createPlant(demoPlant)

            // Attach a few sample events if EventStore is available.
            if let eventStore {
                let now = Date()
                let events: [Event] = [
                    Event(
                        plantId: createdPlant.id,
                        type: .note,
                        timestamp: now.addingTimeInterval(-7 * 24 * 60 * 60),
                        noteText: "Demo plant created. Explore the diary and analytics tabs to see how GroBro works."
                    ),
                    Event(
                        plantId: createdPlant.id,
                        type: .watering,
                        timestamp: now.addingTimeInterval(-3 * 24 * 60 * 60),
                        volumeLiters: 1.2,
                        noteText: "Watered with pH‑adjusted water."
                    ),
                    Event(
                        plantId: createdPlant.id,
                        type: .feeding,
                        timestamp: now.addingTimeInterval(-1 * 24 * 60 * 60),
                        noteText: "Fed according to week 3 veg schedule.",
                        nutrientData: NutrientEventData(
                            brand: "Demo Nutrients",
                            productLine: "Grow",
                            dosages: [
                                ProductDosage(productName: "Demo Grow A/B", amount: 2.0, unit: "ml/L")
                            ]
                        )
                    )
                ]

                for event in events {
                    _ = try eventStore.createEvent(event)
                }
            }

            plants = try plantStore.fetchPlants()
            loadWateringStatuses()
            return true
        } catch {
            errorMessage = "Failed to create demo plant: \(error.localizedDescription)"
            showError = true
            return false
        }
    }
}
