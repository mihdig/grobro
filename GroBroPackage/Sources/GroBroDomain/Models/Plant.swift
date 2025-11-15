import Foundation

/// Domain model representing a single plant in the user's garden
public struct Plant: Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var strainName: String?
    public let createdAt: Date
    public var startDate: Date
    public var stage: PlantStage
    public var potSizeLiters: Double?
    public var substrateType: SubstrateType?
    public var lightHoursPerDay: Double?
    public var lightDistance: Double? // Distance from light to canopy in inches
    public var lightType: LightType?
    public var notes: String?
    public var isArchived: Bool
    public var photoAssetId: String?

    /// Computed property: age in days since grow started
    public var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }

    public init(
        id: UUID = UUID(),
        name: String,
        strainName: String? = nil,
        createdAt: Date = Date(),
        startDate: Date = Date(),
        stage: PlantStage,
        potSizeLiters: Double? = nil,
        substrateType: SubstrateType? = nil,
        lightHoursPerDay: Double? = nil,
        lightDistance: Double? = nil,
        lightType: LightType? = nil,
        notes: String? = nil,
        isArchived: Bool = false,
        photoAssetId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.strainName = strainName
        self.createdAt = createdAt
        self.startDate = startDate
        self.stage = stage
        self.potSizeLiters = potSizeLiters
        self.substrateType = substrateType
        self.lightHoursPerDay = lightHoursPerDay
        self.lightDistance = lightDistance
        self.lightType = lightType
        self.notes = notes
        self.isArchived = isArchived
        self.photoAssetId = photoAssetId
    }
}
