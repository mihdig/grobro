import CoreData
import Foundation

/// Store responsible for CRUD operations on Event entities.
final class EventStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func createEvent(for plantId: UUID,
                     type: EventType,
                     timestamp: Date = Date(),
                     volumeLiters: Double? = nil,
                     noteText: String? = nil,
                     photoAssetId: String? = nil,
                     stressTags: [StressTag] = []) throws {
        guard let entity = NSEntityDescription.entity(forEntityName: "Event", in: context) else {
            throw NSError(domain: "EventStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing Event entity in model"])
        }

        let object = NSManagedObject(entity: entity, insertInto: context)
        object.setValue(UUID(), forKey: "id")
        object.setValue(plantId, forKey: "plantId")
        object.setValue(type.rawValue, forKey: "typeRaw")
        object.setValue(timestamp, forKey: "timestamp")
        object.setValue(volumeLiters, forKey: "volumeLiters")
        object.setValue(noteText, forKey: "noteText")
        object.setValue(photoAssetId, forKey: "photoAssetId")
        object.setValue(stressTags.map { $0.rawValue }, forKey: "stressTagsRaw")

        try context.save()
    }

    func events(for plantId: UUID, typeFilter: EventType? = nil) throws -> [Event] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Event")
        var predicates: [NSPredicate] = [NSPredicate(format: "plantId == %@", plantId as CVarArg)]
        if let typeFilter {
            predicates.append(NSPredicate(format: "typeRaw == %d", typeFilter.rawValue))
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let results = try context.fetch(request)
        return results.compactMap { Self.mapManagedObjectToEvent($0) }
    }

    private static func mapManagedObjectToEvent(_ object: NSManagedObject) -> Event? {
        guard
            let id = object.value(forKey: "id") as? UUID,
            let plantId = object.value(forKey: "plantId") as? UUID,
            let typeRaw = object.value(forKey: "typeRaw") as? Int16,
            let timestamp = object.value(forKey: "timestamp") as? Date
        else {
            return nil
        }

        let volumeLiters = object.value(forKey: "volumeLiters") as? Double
        let noteText = object.value(forKey: "noteText") as? String
        let photoAssetId = object.value(forKey: "photoAssetId") as? String
        let tagsRaw = object.value(forKey: "stressTagsRaw") as? [Int16] ?? []
        let stressTags = tagsRaw.compactMap(StressTag.init(rawValue:))

        guard let type = EventType(rawValue: typeRaw) else {
            return nil
        }

        return Event(
            id: id,
            plantId: plantId,
            type: type,
            timestamp: timestamp,
            volumeLiters: volumeLiters,
            noteText: noteText,
            photoAssetId: photoAssetId,
            stressTags: stressTags
        )
    }
}

