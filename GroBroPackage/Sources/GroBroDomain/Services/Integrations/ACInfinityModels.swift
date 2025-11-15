import Foundation

/// Represents an AC Infinity device from API responses (controller or sensor)
/// Note: This is a lightweight API model. For full app model, see ACInfinityDevice in Models/
public struct ACInfinityAPIDevice: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let type: String

    public init(id: String, name: String, type: String) {
        self.id = id
        self.name = name
        self.type = type
    }
}

/// Environmental sensor readings from an AC Infinity device
public struct ACInfinitySensorReading: Codable, Sendable {
    public let temperatureFahrenheit: Double
    public let humidityPercent: Double
    public let vpdKilopascal: Double

    public init(temperatureFahrenheit: Double, humidityPercent: Double, vpdKilopascal: Double) {
        self.temperatureFahrenheit = temperatureFahrenheit
        self.humidityPercent = humidityPercent
        self.vpdKilopascal = vpdKilopascal
    }
}

