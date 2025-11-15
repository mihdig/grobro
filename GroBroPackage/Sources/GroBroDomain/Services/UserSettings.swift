import Foundation

// MARK: - Notification Names

public extension Notification.Name {
    static let environmentalDataFilterChanged = Notification.Name("environmentalDataFilterChanged")
}

/// User preferences and settings
@Observable
public final class UserSettings: @unchecked Sendable {
    private static let temperatureUnitKey = "preferredTemperatureUnit"
    private static let showEnvironmentalDataKey = "showEnvironmentalData"

    public enum TemperatureUnit: String, Codable, CaseIterable {
        case fahrenheit = "°F"
        case celsius = "°C"

        public var displayName: String {
            switch self {
            case .fahrenheit: return "Fahrenheit (°F)"
            case .celsius: return "Celsius (°C)"
            }
        }
    }

    /// Preferred temperature unit (Fahrenheit or Celsius)
    public var preferredTemperatureUnit: TemperatureUnit {
        didSet {
            UserDefaults.standard.set(preferredTemperatureUnit.rawValue, forKey: Self.temperatureUnitKey)
        }
    }

    /// Whether to show environmental data in timeline by default
    public var showEnvironmentalData: Bool {
        didSet {
            UserDefaults.standard.set(showEnvironmentalData, forKey: Self.showEnvironmentalDataKey)
            // Post notification for views to update
            NotificationCenter.default.post(name: .environmentalDataFilterChanged, object: nil)
        }
    }

    public static let shared = UserSettings()

    private init() {
        // Load from UserDefaults
        if let savedUnit = UserDefaults.standard.string(forKey: Self.temperatureUnitKey),
           let unit = TemperatureUnit(rawValue: savedUnit) {
            self.preferredTemperatureUnit = unit
        } else {
            // Default to Fahrenheit for US market
            self.preferredTemperatureUnit = .fahrenheit
        }

        self.showEnvironmentalData = UserDefaults.standard.object(forKey: Self.showEnvironmentalDataKey) as? Bool ?? true
    }

    /// Convert temperature from Fahrenheit to preferred unit
    public func convertTemperature(_ fahrenheit: Double) -> Double {
        switch preferredTemperatureUnit {
        case .fahrenheit:
            return fahrenheit
        case .celsius:
            return (fahrenheit - 32) * 5 / 9
        }
    }

    /// Format temperature with preferred unit
    public func formatTemperature(_ fahrenheit: Double, precision: Int = 1) -> String {
        let converted = convertTemperature(fahrenheit)
        return String(format: "%.\(precision)f%@", converted, preferredTemperatureUnit.rawValue)
    }

    /// Format humidity
    public func formatHumidity(_ percent: Double) -> String {
        return String(format: "%.0f%%", percent)
    }

    /// Format VPD
    public func formatVPD(_ vpd: Double) -> String {
        return String(format: "%.2f kPa", vpd)
    }
}
