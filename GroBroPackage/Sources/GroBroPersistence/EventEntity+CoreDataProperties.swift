import Foundation
import CoreData

extension EventEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventEntity> {
        return NSFetchRequest<EventEntity>(entityName: "EventEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var plantId: UUID
    @NSManaged public var type: String
    @NSManaged public var timestamp: Date
    @NSManaged public var volumeLiters: Double
    @NSManaged public var nutrientProfileId: UUID?
    @NSManaged public var noteText: String?
    @NSManaged public var photoAssetId: String?
    @NSManaged public var stressTags: String?
    @NSManaged public var metadataJSON: String?
}

extension EventEntity: Identifiable {}
