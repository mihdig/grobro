import Foundation

/// Real-time environmental data from AC Infinity Controller or other devices
/// Note: For event-stored environmental data, see EnvironmentalData struct in Event.swift
@Observable
public final class RealtimeEnvironmentalData: @unchecked Sendable {
    public var temperature: Double // Fahrenheit
    public var humidity: Double // Percentage (0-100)
    public var vpd: Double // kPa (Vapor Pressure Deficit)
    public var timestamp: Date
    public var deviceId: String?
    public var isConnected: Bool

    public init(
        temperature: Double = 0,
        humidity: Double = 0,
        vpd: Double = 0,
        timestamp: Date = Date(),
        deviceId: String? = nil,
        isConnected: Bool = false
    ) {
        self.temperature = temperature
        self.humidity = humidity
        self.vpd = vpd
        self.timestamp = timestamp
        self.deviceId = deviceId
        self.isConnected = isConnected
    }

    /// Calculate VPD from temperature and humidity
    public static func calculateVPD(temperature: Double, humidity: Double) -> Double {
        // Convert Fahrenheit to Celsius
        let tempC = (temperature - 32) * 5 / 9

        // Calculate saturation vapor pressure (kPa)
        let svp = 0.6108 * exp((17.27 * tempC) / (tempC + 237.3))

        // Calculate actual vapor pressure
        let avp = svp * (humidity / 100)

        // VPD = SVP - AVP
        return svp - avp
    }

    /// Update with new readings and auto-calculate VPD
    public func update(temperature: Double, humidity: Double) {
        self.temperature = temperature
        self.humidity = humidity
        self.vpd = Self.calculateVPD(temperature: temperature, humidity: humidity)
        self.timestamp = Date()
    }

    /// Environmental status based on VPD and temperature
    public var status: EnvironmentStatus {
        // VPD optimal range: 0.8 - 1.2 kPa
        // Temperature optimal range: 70-80°F
        let vpdOptimal = vpd >= 0.8 && vpd <= 1.2
        let tempOptimal = temperature >= 70 && temperature < 80

        if vpdOptimal && tempOptimal {
            return .optimal
        }

        let vpdCritical = vpd < 0.4 || vpd > 1.8
        let tempCritical = temperature < 60 || temperature > 90

        if vpdCritical || tempCritical {
            return .critical
        }

        return .caution
    }

    public enum EnvironmentStatus: String, Sendable {
        case optimal = "Optimal"
        case caution = "Caution"
        case critical = "Critical"
        case offline = "Offline"
    }
}

/// Historical environmental data point
public struct EnvironmentalDataPoint: Identifiable, Sendable {
    public let id = UUID()
    public let timestamp: Date
    public let temperature: Double
    public let humidity: Double
    public let vpd: Double

    public init(timestamp: Date, temperature: Double, humidity: Double, vpd: Double) {
        self.timestamp = timestamp
        self.temperature = temperature
        self.humidity = humidity
        self.vpd = vpd
    }

    public init(from data: RealtimeEnvironmentalData) {
        self.timestamp = data.timestamp
        self.temperature = data.temperature
        self.humidity = data.humidity
        self.vpd = data.vpd
    }
}

/// Environmental alert threshold configuration
public struct EnvironmentalThresholds: Sendable {
    public var temperatureMin: Double = 70
    public var temperatureMax: Double = 80
    public var humidityMin: Double = 50
    public var humidityMax: Double = 70
    public var vpdMin: Double = 0.8
    public var vpdMax: Double = 1.2

    public init() {}

    /// Check if current data exceeds thresholds
    public func checkAlerts(for data: RealtimeEnvironmentalData) -> [EnvironmentalAlert] {
        var alerts: [EnvironmentalAlert] = []

        if data.temperature < temperatureMin {
            alerts.append(.temperatureLow(data.temperature, temperatureMin))
        } else if data.temperature > temperatureMax {
            alerts.append(.temperatureHigh(data.temperature, temperatureMax))
        }

        if data.humidity < humidityMin {
            alerts.append(.humidityLow(data.humidity, humidityMin))
        } else if data.humidity > humidityMax {
            alerts.append(.humidityHigh(data.humidity, humidityMax))
        }

        if data.vpd < vpdMin {
            alerts.append(.vpdLow(data.vpd, vpdMin))
        } else if data.vpd > vpdMax {
            alerts.append(.vpdHigh(data.vpd, vpdMax))
        }

        return alerts
    }
}

/// Environmental alert types
public enum EnvironmentalAlert: Identifiable, Sendable {
    case temperatureLow(Double, Double)
    case temperatureHigh(Double, Double)
    case humidityLow(Double, Double)
    case humidityHigh(Double, Double)
    case vpdLow(Double, Double)
    case vpdHigh(Double, Double)

    public var id: String {
        switch self {
        case .temperatureLow: return "temp_low"
        case .temperatureHigh: return "temp_high"
        case .humidityLow: return "humidity_low"
        case .humidityHigh: return "humidity_high"
        case .vpdLow: return "vpd_low"
        case .vpdHigh: return "vpd_high"
        }
    }

    public var title: String {
        switch self {
        case .temperatureLow: return "Temperature Too Low"
        case .temperatureHigh: return "Temperature Too High"
        case .humidityLow: return "Humidity Too Low"
        case .humidityHigh: return "Humidity Too High"
        case .vpdLow: return "VPD Too Low"
        case .vpdHigh: return "VPD Too High"
        }
    }

    public var message: String {
        switch self {
        case .temperatureLow(let current, let min):
            return String(format: "%.1f°F is below minimum of %.1f°F", current, min)
        case .temperatureHigh(let current, let max):
            return String(format: "%.1f°F exceeds maximum of %.1f°F", current, max)
        case .humidityLow(let current, let min):
            return String(format: "%.0f%% is below minimum of %.0f%%", current, min)
        case .humidityHigh(let current, let max):
            return String(format: "%.0f%% exceeds maximum of %.0f%%", current, max)
        case .vpdLow(let current, let min):
            return String(format: "%.2f kPa is below minimum of %.2f kPa", current, min)
        case .vpdHigh(let current, let max):
            return String(format: "%.2f kPa exceeds maximum of %.2f kPa", current, max)
        }
    }
}
