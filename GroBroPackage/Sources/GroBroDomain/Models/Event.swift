import Foundation

/// Domain model representing an event in a plant's timeline/diary
public struct Event: Identifiable, Sendable {
    public let id: UUID
    public let plantId: UUID
    public var type: EventType
    public var timestamp: Date
    public var volumeLiters: Double?
    public var nutrientProfileId: UUID?
    public var noteText: String?
    public var photoAssetId: String?
    public var stressTags: [StressTag]

    // Optional structured metadata for advanced event types
    public var source: EventSource
    public var environmentalData: EnvironmentalData?
    public var lightMeasurement: LightMeasurementData?

    public init(
        id: UUID = UUID(),
        plantId: UUID,
        type: EventType,
        timestamp: Date = Date(),
        volumeLiters: Double? = nil,
        nutrientProfileId: UUID? = nil,
        noteText: String? = nil,
        photoAssetId: String? = nil,
        stressTags: [StressTag] = [],
        source: EventSource = .manual,
        environmentalData: EnvironmentalData? = nil,
        lightMeasurement: LightMeasurementData? = nil
    ) {
        self.id = id
        self.plantId = plantId
        self.type = type
        self.timestamp = timestamp
        self.volumeLiters = volumeLiters
        self.nutrientProfileId = nutrientProfileId
        self.noteText = noteText
        self.photoAssetId = photoAssetId
        self.stressTags = stressTags
        self.source = source
        self.environmentalData = environmentalData
        self.lightMeasurement = lightMeasurement
    }
}

/// Source of an event (manual entry vs external integration)
public enum EventSource: String, Codable, Sendable {
    case manual
    case acInfinity
    case lightMeter
    case other
}

/// Environmental data associated with an event (e.g., AC Infinity readings)
public struct EnvironmentalData: Codable, Sendable {
    public var temperatureFahrenheit: Double?
    public var humidityPercent: Double?
    public var vpdKilopascal: Double?

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

/// Light measurement data logged from the light meter
public struct LightMeasurementData: Codable, Sendable {
    public var ppfd: Double?
    public var lux: Double?
    public var dli: Double?
    public var lightTypeIdentifier: String?
    public var distanceMeters: Double?

    public init(
        ppfd: Double? = nil,
        lux: Double? = nil,
        dli: Double? = nil,
        lightTypeIdentifier: String? = nil,
        distanceMeters: Double? = nil
    ) {
        self.ppfd = ppfd
        self.lux = lux
        self.dli = dli
        self.lightTypeIdentifier = lightTypeIdentifier
        self.distanceMeters = distanceMeters
    }
}
