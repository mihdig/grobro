import Foundation

/// Alert threshold configuration for environmental monitoring
public struct AlertThreshold: Identifiable, Sendable, Codable {
    public let id: UUID
    public var plantId: UUID
    public var metric: EnvironmentalMetric
    public var min: Double?
    public var max: Double?
    public var enabled: Bool
    public var sensitivity: AlertSensitivity

    public enum EnvironmentalMetric: String, Codable, Sendable, CaseIterable {
        case temperature
        case humidity
        case vpd

        public var displayName: String {
            switch self {
            case .temperature: return "Temperature"
            case .humidity: return "Humidity"
            case .vpd: return "VPD"
            }
        }

        public var unit: String {
            switch self {
            case .temperature: return "°F"
            case .humidity: return "%"
            case .vpd: return "kPa"
            }
        }

        public var icon: String {
            switch self {
            case .temperature: return "thermometer.medium"
            case .humidity: return "drop.fill"
            case .vpd: return "gauge.medium"
            }
        }
    }

    public enum AlertSensitivity: String, Codable, Sendable, CaseIterable {
        case immediate
        case fifteenMinutes
        case oneHour

        public var displayName: String {
            switch self {
            case .immediate: return "Immediate"
            case .fifteenMinutes: return "After 15 minutes"
            case .oneHour: return "After 1 hour"
            }
        }

        public var delaySeconds: TimeInterval {
            switch self {
            case .immediate: return 0
            case .fifteenMinutes: return 15 * 60
            case .oneHour: return 60 * 60
            }
        }
    }

    public init(
        id: UUID = UUID(),
        plantId: UUID,
        metric: EnvironmentalMetric,
        min: Double? = nil,
        max: Double? = nil,
        enabled: Bool = true,
        sensitivity: AlertSensitivity = .fifteenMinutes
    ) {
        self.id = id
        self.plantId = plantId
        self.metric = metric
        self.min = min
        self.max = max
        self.enabled = enabled
        self.sensitivity = sensitivity
    }

    /// Check if a value violates this threshold
    public func isViolated(by value: Double) -> Bool {
        guard enabled else { return false }

        if let min = min, value < min {
            return true
        }

        if let max = max, value > max {
            return true
        }

        return false
    }

    /// Check if a violation is critical (overrides quiet hours)
    public static func isCritical(value: Double, metric: EnvironmentalMetric) -> Bool {
        switch metric {
        case .temperature:
            return value < 50 || value > 95
        case .humidity:
            return value < 20 || value > 90
        case .vpd:
            return value < 0.2 || value > 2.5
        }
    }
}
