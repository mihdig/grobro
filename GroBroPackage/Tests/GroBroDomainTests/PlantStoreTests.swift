import XCTest
@testable import GroBroDomain
@testable import GroBroPersistence

@MainActor
final class PlantStoreTests: XCTestCase {

    var persistenceController: PersistenceController!
    var plantStore: PlantStore!

    override func setUp() async throws {
        // Use in-memory store for testing
        persistenceController = PersistenceController(inMemory: true)
        plantStore = PlantStore(persistenceController: persistenceController)
    }

    override func tearDown() async throws {
        persistenceController = nil
        plantStore = nil
    }

    /// Test creating a new plant
    func testCreatePlant() throws {
        let plant = Plant(
            name: "Test Plant",
            stage: .seedling,
            potSizeLiters: 10.0,
            substrateType: .soil
        )

        let createdPlant = try plantStore.createPlant(plant)

        XCTAssertEqual(createdPlant.name, "Test Plant")
        XCTAssertEqual(createdPlant.stage, .seedling)
        XCTAssertEqual(createdPlant.potSizeLiters, 10.0)
        XCTAssertEqual(createdPlant.substrateType, .soil)
        XCTAssertFalse(createdPlant.isArchived)
    }

    /// Test fetching all plants
    func testFetchPlants() throws {
        // Create multiple plants
        let plant1 = Plant(name: "Plant 1", stage: .seedling)
        let plant2 = Plant(name: "Plant 2", stage: .vegetative)
        let plant3 = Plant(name: "Plant 3", stage: .flowering)

        _ = try plantStore.createPlant(plant1)
        _ = try plantStore.createPlant(plant2)
        _ = try plantStore.createPlant(plant3)

        let plants = try plantStore.fetchPlants()

        XCTAssertEqual(plants.count, 3)
        XCTAssertTrue(plants.contains(where: { $0.name == "Plant 1" }))
        XCTAssertTrue(plants.contains(where: { $0.name == "Plant 2" }))
        XCTAssertTrue(plants.contains(where: { $0.name == "Plant 3" }))
    }

    /// Test fetching a single plant by ID
    func testFetchPlantById() throws {
        let plant = Plant(name: "Unique Plant", stage: .vegetative)
        let createdPlant = try plantStore.createPlant(plant)

        let fetchedPlant = try plantStore.fetchPlant(id: createdPlant.id)

        XCTAssertNotNil(fetchedPlant)
        XCTAssertEqual(fetchedPlant?.id, createdPlant.id)
        XCTAssertEqual(fetchedPlant?.name, "Unique Plant")
    }

    /// Test updating a plant
    func testUpdatePlant() throws {
        var plant = Plant(name: "Original Name", stage: .seedling)
        plant = try plantStore.createPlant(plant)

        // Update the plant
        var updatedPlant = plant
        updatedPlant.name = "Updated Name"
        updatedPlant.stage = .vegetative
        updatedPlant.potSizeLiters = 15.0

        try plantStore.updatePlant(updatedPlant)

        let fetchedPlant = try plantStore.fetchPlant(id: plant.id)

        XCTAssertEqual(fetchedPlant?.name, "Updated Name")
        XCTAssertEqual(fetchedPlant?.stage, .vegetative)
        XCTAssertEqual(fetchedPlant?.potSizeLiters, 15.0)
    }

    /// Test archiving a plant (soft delete)
    func testArchivePlant() throws {
        let plant = Plant(name: "Plant to Archive", stage: .flowering)
        let createdPlant = try plantStore.createPlant(plant)

        try plantStore.archivePlant(id: createdPlant.id)

        // Archived plants should not appear in regular fetch
        let plants = try plantStore.fetchPlants()
        XCTAssertFalse(plants.contains(where: { $0.id == createdPlant.id }))

        // But should still exist when fetched by ID
        let archivedPlant = try plantStore.fetchPlant(id: createdPlant.id)
        XCTAssertNotNil(archivedPlant)
        XCTAssertTrue(archivedPlant?.isArchived == true)
    }

    /// Test hard deleting a plant
    func testDeletePlant() throws {
        let plant = Plant(name: "Plant to Delete", stage: .seedling)
        let createdPlant = try plantStore.createPlant(plant)

        try plantStore.deletePlant(id: createdPlant.id)

        // Plant should not exist anymore
        let fetchedPlant = try plantStore.fetchPlant(id: createdPlant.id)
        XCTAssertNil(fetchedPlant)

        let plants = try plantStore.fetchPlants()
        XCTAssertFalse(plants.contains(where: { $0.id == createdPlant.id }))
    }

    /// Test age calculation
    func testPlantAgeCalculation() throws {
        let startDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let plant = Plant(
            name: "Age Test Plant",
            startDate: startDate,
            stage: .vegetative
        )

        XCTAssertEqual(plant.ageInDays, 10)
    }

    /// Test creating plant with optional fields
    func testCreatePlantWithOptionalFields() throws {
        let plant = Plant(
            name: "Full Plant",
            strainName: "Blue Dream",
            stage: .vegetative,
            potSizeLiters: 20.0,
            substrateType: .coco,
            lightHoursPerDay: 18.0,
            notes: "Looking healthy"
        )

        let createdPlant = try plantStore.createPlant(plant)

        XCTAssertEqual(createdPlant.strainName, "Blue Dream")
        XCTAssertEqual(createdPlant.lightHoursPerDay, 18.0)
        XCTAssertEqual(createdPlant.notes, "Looking healthy")
    }

    // MARK: - Subscription Gating Tests

    /// Test Free tier allows creating up to 3 plants
    func testFreeTierAllowsThreePlants() throws {
        let proManager = ProEntitlementManager()
        proManager.isPro = false

        let plantStore = PlantStore(
            persistenceController: persistenceController,
            proEntitlementManager: proManager
        )

        // Should allow creating 3 plants
        let plant1 = Plant(name: "Plant 1", stage: .seedling)
        let plant2 = Plant(name: "Plant 2", stage: .vegetative)
        let plant3 = Plant(name: "Plant 3", stage: .flowering)

        _ = try plantStore.createPlant(plant1)
        _ = try plantStore.createPlant(plant2)
        _ = try plantStore.createPlant(plant3)

        let plants = try plantStore.fetchPlants()
        XCTAssertEqual(plants.count, 3)
    }

    /// Test Free tier blocks creating 4th plant
    func testFreeTierBlocksFourthPlant() throws {
        let proManager = ProEntitlementManager()
        proManager.isPro = false

        let plantStore = PlantStore(
            persistenceController: persistenceController,
            proEntitlementManager: proManager
        )

        // Create 3 plants first
        for i in 1...3 {
            let plant = Plant(name: "Plant \(i)", stage: .seedling)
            _ = try plantStore.createPlant(plant)
        }

        // 4th plant should throw freeLimitReached error
        let fourthPlant = Plant(name: "Plant 4", stage: .seedling)
        XCTAssertThrowsError(try plantStore.createPlant(fourthPlant)) { error in
            XCTAssertEqual(error as? PlantStoreError, .freeLimitReached)
        }

        // Verify only 3 plants exist
        let plants = try plantStore.fetchPlants()
        XCTAssertEqual(plants.count, 3)
    }

    /// Test Pro tier allows unlimited plants
    func testProTierAllowsUnlimitedPlants() throws {
        let proManager = ProEntitlementManager()
        proManager.isPro = true

        let plantStore = PlantStore(
            persistenceController: persistenceController,
            proEntitlementManager: proManager
        )

        // Should allow creating 10 plants (well beyond free limit)
        for i in 1...10 {
            let plant = Plant(name: "Plant \(i)", stage: .seedling)
            _ = try plantStore.createPlant(plant)
        }

        let plants = try plantStore.fetchPlants()
        XCTAssertEqual(plants.count, 10)
    }

    /// Test plantStore without ProEntitlementManager allows unlimited (backward compatibility)
    func testPlantStoreWithoutProManagerAllowsUnlimited() throws {
        let plantStore = PlantStore(
            persistenceController: persistenceController,
            proEntitlementManager: nil
        )

        // Should allow creating any number of plants when no ProManager is injected
        for i in 1...5 {
            let plant = Plant(name: "Plant \(i)", stage: .seedling)
            _ = try plantStore.createPlant(plant)
        }

        let plants = try plantStore.fetchPlants()
        XCTAssertEqual(plants.count, 5)
    }
}
