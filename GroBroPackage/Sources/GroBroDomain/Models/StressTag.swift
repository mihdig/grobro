import Foundation

/// Tags for marking stress or important events
public enum StressTag: String, Codable, CaseIterable, Sendable {
    case heatStress
    case lightStress
    case overwatering
    case underwatering
    case pests
    case training
    case transplant
    case other

    /// User-friendly display name
    public var displayName: String {
        switch self {
        case .heatStress:
            return "Heat Stress"
        case .lightStress:
            return "Light Stress"
        case .overwatering:
            return "Overwatering"
        case .underwatering:
            return "Underwatering"
        case .pests:
            return "Pests"
        case .training:
            return "Training"
        case .transplant:
            return "Transplant"
        case .other:
            return "Other"
        }
    }
}
