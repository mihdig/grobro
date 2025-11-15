import CoreData
import Foundation

/// Store responsible for CRUD operations on Plant entities.
///
/// This is a thin abstraction over Core Data to keep persistence details
/// out of views and view models.
final class PlantStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchAllActivePlants() throws -> [Plant] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Plant")
        request.predicate = NSPredicate(format: "isArchived == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let results = try context.fetch(request)
        return results.compactMap { Self.mapManagedObjectToPlant($0) }
    }

    func createPlant(name: String,
                     strainName: String?,
                     stage: PlantStage,
                     potSizeLiters: Double?,
                     substrateType: SubstrateType?) throws {
        guard let entity = NSEntityDescription.entity(forEntityName: "Plant", in: context) else {
            throw NSError(domain: "PlantStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing Plant entity in model"])
        }

        let object = NSManagedObject(entity: entity, insertInto: context)
        let now = Date()
        object.setValue(UUID(), forKey: "id")
        object.setValue(name, forKey: "name")
        object.setValue(strainName, forKey: "strainName")
        object.setValue(now, forKey: "createdAt")
        object.setValue(now, forKey: "startDate")
        object.setValue(stage.rawValue, forKey: "stageRaw")
        object.setValue(potSizeLiters, forKey: "potSizeLiters")
        object.setValue(substrateType?.rawValue, forKey: "substrateTypeRaw")
        object.setValue(false, forKey: "isArchived")
        object.setValue(nil, forKey: "photoAssetId")
        object.setValue(nil, forKey: "notes")

        try context.save()
    }

    func deletePlant(id: UUID) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Plant")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let results = try context.fetch(request)
        for object in results {
            context.delete(object)
        }
        if context.hasChanges {
            try context.save()
        }
    }

    // MARK: - Mapping

    private static func mapManagedObjectToPlant(_ object: NSManagedObject) -> Plant? {
        guard
            let id = object.value(forKey: "id") as? UUID,
            let name = object.value(forKey: "name") as? String,
            let createdAt = object.value(forKey: "createdAt") as? Date,
            let startDate = object.value(forKey: "startDate") as? Date,
            let stageRaw = object.value(forKey: "stageRaw") as? Int16,
            let isArchived = object.value(forKey: "isArchived") as? Bool
        else {
            return nil
        }

        let strainName = object.value(forKey: "strainName") as? String
        let potSizeLiters = object.value(forKey: "potSizeLiters") as? Double
        let substrateTypeRaw = object.value(forKey: "substrateTypeRaw") as? Int16
        let substrateType = substrateTypeRaw.flatMap(SubstrateType.init(rawValue:))
        let notes = object.value(forKey: "notes") as? String
        let photoAssetId = object.value(forKey: "photoAssetId") as? String
        let stage = PlantStage(rawValue: stageRaw) ?? .vegetative

        return Plant(
            id: id,
            name: name,
            strainName: strainName,
            createdAt: createdAt,
            startDate: startDate,
            stage: stage,
            potSizeLiters: potSizeLiters,
            substrateType: substrateType,
            notes: notes,
            isArchived: isArchived,
            photoAssetId: photoAssetId
        )
    }
}

