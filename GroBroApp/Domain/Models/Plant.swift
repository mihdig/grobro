import Foundation

/// Domain model representing a plant in the garden.
struct Plant: Identifiable, Equatable {
    let id: UUID
    var name: String
    var strainName: String?
    var createdAt: Date
    var startDate: Date
    var stage: PlantStage
    var potSizeLiters: Double?
    var substrateType: SubstrateType?
    var notes: String?
    var isArchived: Bool
    var photoAssetId: String?

    var ageInDays: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }
}

enum PlantStage: Int16, CaseIterable {
    case seedling
    case vegetative
    case flowering

    var displayName: String {
        switch self {
        case .seedling: return "Seedling"
        case .vegetative: return "Vegetative"
        case .flowering: return "Flowering"
        }
    }
}

enum SubstrateType: Int16, CaseIterable {
    case soil
    case coco
    case hydro
    case soilless
    case other

    var displayName: String {
        switch self {
        case .soil: return "Soil"
        case .coco: return "Coco"
        case .hydro: return "Hydro"
        case .soilless: return "Soilless"
        case .other: return "Other"
        }
    }
}

