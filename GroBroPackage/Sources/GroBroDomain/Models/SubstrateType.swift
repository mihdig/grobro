import Foundation

/// Represents the type of growing substrate/medium
public enum SubstrateType: String, Codable, CaseIterable, Sendable {
    case soil
    case coco
    case hydro
    case soilless
    case other

    /// User-friendly display name
    public var displayName: String {
        switch self {
        case .soil:
            return "Soil"
        case .coco:
            return "Coco Coir"
        case .hydro:
            return "Hydroponic"
        case .soilless:
            return "Soilless Mix"
        case .other:
            return "Other"
        }
    }
}
