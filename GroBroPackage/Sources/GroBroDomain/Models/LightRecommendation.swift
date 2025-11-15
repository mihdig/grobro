import Foundation

/// Spectrum recommendation for a given growth stage
public struct SpectrumRecommendation: Sendable {
    public let kelvin: ClosedRange<Int>
    public let bluePercentage: Double
    public let redPercentage: Double
    public let description: String

    public init(
        kelvin: ClosedRange<Int>,
        bluePercentage: Double,
        redPercentage: Double,
        description: String
    ) {
        self.kelvin = kelvin
        self.bluePercentage = bluePercentage
        self.redPercentage = redPercentage
        self.description = description
    }
}

/// Complete light recommendation for a plant based on stage and light type
public struct LightRecommendation: Sendable {
    public let stage: PlantStage
    public let lightType: LightType
    public let hoursOn: Int
    public let hoursOff: Int
    public let ppfdRange: ClosedRange<Double>
    public let dliTarget: ClosedRange<Double>
    public let spectrum: SpectrumRecommendation?

    public init(
        stage: PlantStage,
        lightType: LightType,
        hoursOn: Int,
        hoursOff: Int,
        ppfdRange: ClosedRange<Double>,
        dliTarget: ClosedRange<Double>,
        spectrum: SpectrumRecommendation? = nil
    ) {
        self.stage = stage
        self.lightType = lightType
        self.hoursOn = hoursOn
        self.hoursOff = hoursOff
        self.ppfdRange = ppfdRange
        self.dliTarget = dliTarget
        self.spectrum = spectrum
    }

    /// Photoperiod as a string (e.g., "18/6", "12/12")
    public var photoperiodString: String {
        "\(hoursOn)/\(hoursOff)"
    }
}

/// Custom light schedule set by the user
public struct LightSchedule: Codable, Sendable {
    public let startTime: Date
    public let hoursOn: Int
    public let hoursOff: Int

    public init(startTime: Date, hoursOn: Int, hoursOff: Int) {
        self.startTime = startTime
        self.hoursOn = hoursOn
        self.hoursOff = hoursOff
    }

    /// Calculate the time when lights turn off
    public var offTime: Date {
        Calendar.current.date(byAdding: .hour, value: hoursOn, to: startTime) ?? startTime
    }

    /// Total hours (should always be 24)
    public var totalHours: Int {
        hoursOn + hoursOff
    }

    /// Validate schedule is within acceptable ranges
    public var isValid: Bool {
        totalHours == 24 && hoursOn >= 0 && hoursOff >= 0
    }
}
