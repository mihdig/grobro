import Foundation

/// Environmental health score measuring time spent in optimal conditions
public struct EnvironmentalHealthScore: Sendable {
    public let overall: Double // 0-100
    public let tempScore: Double
    public let humidityScore: Double
    public let vpdScore: Double
    public let trend: Trend

    public enum Trend: String, Codable, Sendable {
        case improving
        case stable
        case declining

        public var displayName: String {
            switch self {
            case .improving: return "Improving"
            case .stable: return "Stable"
            case .declining: return "Declining"
            }
        }

        public var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .stable: return "arrow.right"
            case .declining: return "arrow.down.right"
            }
        }
    }

    public init(
        overall: Double,
        tempScore: Double,
        humidityScore: Double,
        vpdScore: Double,
        trend: Trend
    ) {
        self.overall = overall
        self.tempScore = tempScore
        self.humidityScore = humidityScore
        self.vpdScore = vpdScore
        self.trend = trend
    }

    /// Score color based on overall percentage
    public var scoreColor: String {
        switch overall {
        case 90...100: return "successGreen"
        case 70..<90: return "electricGreen"
        case 50..<70: return "warningOrange"
        default: return "criticalRed"
        }
    }

    /// Breakdown text for display
    public var breakdown: String {
        String(format: "Temp: %.0f%%, Humidity: %.0f%%, VPD: %.0f%%",
               tempScore, humidityScore, vpdScore)
    }
}
