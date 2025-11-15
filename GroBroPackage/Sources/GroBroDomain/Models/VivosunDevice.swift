import Foundation

/// Represents a Vivosun controller or sensor returned from the API.
public struct VivosunDevice: Identifiable, Codable, Sendable {
    public enum DeviceType: String, Codable, Sendable {
        case controller
        case sensor
        case unknown
    }

    public let id: String
    public let name: String
    public let deviceType: DeviceType
    public let location: String?
    public let isOnline: Bool

    public init(
        id: String,
        name: String,
        deviceType: DeviceType = .unknown,
        location: String? = nil,
        isOnline: Bool = true
    ) {
        self.id = id
        self.name = name
        self.deviceType = deviceType
        self.location = location
        self.isOnline = isOnline
    }
}

/// Environmental data payload from Vivosun sensors.
public struct VivosunSensorReading: Codable, Sendable {
    public let temperatureFahrenheit: Double?
    public let humidityPercent: Double?
    public let vpdKilopascal: Double?

    public init(
        temperatureFahrenheit: Double? = nil,
        humidityPercent: Double? = nil,
        vpdKilopascal: Double? = nil
    ) {
        self.temperatureFahrenheit = temperatureFahrenheit
        self.humidityPercent = humidityPercent
        self.vpdKilopascal = vpdKilopascal
    }
}
