import Foundation

/// Represents the current growth stage of a plant
public enum PlantStage: String, Codable, CaseIterable, Sendable {
    case seedling
    case vegetative
    case flowering

    /// User-friendly display name
    public var displayName: String {
        switch self {
        case .seedling:
            return "Seedling"
        case .vegetative:
            return "Vegetative"
        case .flowering:
            return "Flowering"
        }
    }
}
