import Foundation
import CoreData

extension PlantEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlantEntity> {
        return NSFetchRequest<PlantEntity>(entityName: "PlantEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var strainName: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var startDate: Date
    @NSManaged public var stage: String
    @NSManaged public var potSizeLiters: Double
    @NSManaged public var substrateType: String?
    @NSManaged public var lightHoursPerDay: Double
    @NSManaged public var notes: String?
    @NSManaged public var isArchived: Bool
    @NSManaged public var photoAssetId: String?
}

extension PlantEntity: Identifiable {}
