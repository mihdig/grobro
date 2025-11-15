import Foundation

/// Represents the type of event in a plant's diary
public enum EventType: String, Codable, CaseIterable, Sendable {
    case watering
    case feeding
    case flush
    case note
    case photo
    case stress
    case environment
    case lightCheck

    /// User-friendly display name
    public var displayName: String {
        switch self {
        case .watering:
            return "Watering"
        case .feeding:
            return "Feeding"
        case .flush:
            return "Flush"
        case .note:
            return "Note"
        case .photo:
            return "Photo"
        case .stress:
            return "Stress"
        case .environment:
            return "Environment"
        case .lightCheck:
            return "Light Check"
        }
    }

    /// SF Symbol icon name for the event type
    public var iconName: String {
        switch self {
        case .watering:
            return "drop.fill"
        case .feeding:
            return "leaf.fill"
        case .flush:
            return "arrow.clockwise"
        case .note:
            return "note.text"
        case .photo:
            return "camera.fill"
        case .stress:
            return "exclamationmark.triangle.fill"
        case .environment:
            return "thermometer.sun"
        case .lightCheck:
            return "sun.max.fill"
        }
    }
}
