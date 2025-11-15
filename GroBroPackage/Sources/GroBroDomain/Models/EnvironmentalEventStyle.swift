import Foundation

/// Visual styling for events in the timeline
public enum EnvironmentalEventStyle: String, Codable, Sendable {
    /// Manually entered by user
    case manual

    /// Automatically synced from device integration
    case automatic

    /// Alert or warning event
    case alert
}
