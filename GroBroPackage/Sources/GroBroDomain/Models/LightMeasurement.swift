import Foundation

/// Represents a single light measurement snapshot for a plant.
public struct LightMeasurement: Sendable {
    public let ppfd: Double
    public let lux: Double
    public let dli: Double
    public let lightType: LightType
    public let photoperiodHours: Double

    public init(
        ppfd: Double,
        lux: Double,
        dli: Double,
        lightType: LightType,
        photoperiodHours: Double
    ) {
        self.ppfd = ppfd
        self.lux = lux
        self.dli = dli
        self.lightType = lightType
        self.photoperiodHours = photoperiodHours
    }
}

/// Zone classification for current PPFD relative to recommended range.
public enum LightIntensityZone: String, Sendable {
    case tooLow
    case optimal
    case tooHigh
}

