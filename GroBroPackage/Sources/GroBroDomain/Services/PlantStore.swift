import Foundation
import CoreData
import GroBroPersistence

/// Service responsible for CRUD operations on Plant entities
@available(iOS 17.0, macOS 14.0, *)
@MainActor
public final class PlantStore: ObservableObject {

    private let persistenceController: PersistenceController
    private let proEntitlementManager: ProEntitlementManager?

    public init(
        persistenceController: PersistenceController = .shared,
        proEntitlementManager: ProEntitlementManager? = nil
    ) {
        self.persistenceController = persistenceController
        self.proEntitlementManager = proEntitlementManager
    }

    /// Fetch all non-archived plants
    /// - Returns: Array of Plant domain models
    public func fetchPlants() throws -> [Plant] {
        let request = PlantEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PlantEntity.createdAt, ascending: false)]

        let entities = try persistenceController.viewContext.fetch(request)
        return entities.compactMap { toDomain($0) }
    }

    /// Fetch a single plant by ID
    /// - Parameter id: The plant's UUID
    /// - Returns: Plant domain model if found
    public func fetchPlant(id: UUID) throws -> Plant? {
        let request = PlantEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let entities = try persistenceController.viewContext.fetch(request)
        guard let entity = entities.first else { return nil }
        return toDomain(entity)
    }

    /// Create a new plant
    /// - Parameter plant: The Plant domain model to create
    /// - Returns: The created Plant with persisted ID
    /// - Throws: PlantStoreError.freeLimitReached if user is on Free tier and has reached plant limit
    public func createPlant(_ plant: Plant) throws -> Plant {
        // Check Free tier plant limit if ProEntitlementManager is available
        if let proManager = proEntitlementManager {
            let currentCount = try fetchPlants().count
            if !proManager.canCreatePlant(currentPlantCount: currentCount) {
                throw PlantStoreError.freeLimitReached
            }
        }

        let entity = PlantEntity(context: persistenceController.viewContext)
        toEntity(plant, entity: entity)

        try persistenceController.save()
        return toDomain(entity)!
    }

    /// Update an existing plant
    /// - Parameter plant: The Plant domain model with updated fields
    public func updatePlant(_ plant: Plant) throws {
        let request = PlantEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", plant.id as CVarArg)
        request.fetchLimit = 1

        let entities = try persistenceController.viewContext.fetch(request)
        guard let entity = entities.first else {
            throw PlantStoreError.plantNotFound
        }

        toEntity(plant, entity: entity)
        try persistenceController.save()
    }

    /// Delete a plant (soft delete by archiving)
    /// - Parameter id: The plant's UUID
    public func archivePlant(id: UUID) throws {
        let request = PlantEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let entities = try persistenceController.viewContext.fetch(request)
        guard let entity = entities.first else {
            throw PlantStoreError.plantNotFound
        }

        entity.isArchived = true
        try persistenceController.save()
    }

    /// Hard delete a plant from the store
    /// - Parameter id: The plant's UUID
    public func deletePlant(id: UUID) throws {
        let request = PlantEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let entities = try persistenceController.viewContext.fetch(request)
        guard let entity = entities.first else {
            throw PlantStoreError.plantNotFound
        }

        persistenceController.viewContext.delete(entity)
        try persistenceController.save()
    }

    // MARK: - Mapping Helpers

    private func toDomain(_ entity: PlantEntity) -> Plant? {
        guard let stage = PlantStage(rawValue: entity.stage) else {
            return nil
        }

        let substrate: SubstrateType? = if let rawSubstrate = entity.substrateType {
            SubstrateType(rawValue: rawSubstrate)
        } else {
            nil
        }

        return Plant(
            id: entity.id,
            name: entity.name,
            strainName: entity.strainName,
            createdAt: entity.createdAt,
            startDate: entity.startDate,
            stage: stage,
            potSizeLiters: entity.potSizeLiters > 0 ? entity.potSizeLiters : nil,
            substrateType: substrate,
            lightHoursPerDay: entity.lightHoursPerDay > 0 ? entity.lightHoursPerDay : nil,
            notes: entity.notes,
            isArchived: entity.isArchived,
            photoAssetId: entity.photoAssetId
        )
    }

    private func toEntity(_ plant: Plant, entity: PlantEntity) {
        entity.id = plant.id
        entity.name = plant.name
        entity.strainName = plant.strainName
        entity.createdAt = plant.createdAt
        entity.startDate = plant.startDate
        entity.stage = plant.stage.rawValue
        entity.potSizeLiters = plant.potSizeLiters ?? 0
        entity.substrateType = plant.substrateType?.rawValue
        entity.lightHoursPerDay = plant.lightHoursPerDay ?? 0
        entity.notes = plant.notes
        entity.isArchived = plant.isArchived
        entity.photoAssetId = plant.photoAssetId
    }
}

public enum PlantStoreError: Error, LocalizedError, Equatable {
    case plantNotFound
    case saveFailed
    case freeLimitReached

    public var errorDescription: String? {
        switch self {
        case .plantNotFound:
            return "Plant not found"
        case .saveFailed:
            return "Failed to save plant"
        case .freeLimitReached:
            return "You've reached the Free plan limit of 3 plants. Upgrade to Pro for unlimited plants."
        }
    }
}
