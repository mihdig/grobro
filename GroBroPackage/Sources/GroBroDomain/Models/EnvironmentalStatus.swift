import Foundation

/// Environmental status indicating whether conditions are optimal, concerning, or critical
public struct EnvironmentalStatus: Sendable {
    public enum Status: String, Codable, Sendable {
        case optimal
        case caution
        case critical
    }

    public let status: Status
    public let temp: Double
    public let humidity: Double
    public let vpd: Double
    public let stage: PlantStage

    public init(temp: Double, humidity: Double, vpd: Double, stage: PlantStage) {
        self.temp = temp
        self.humidity = humidity
        self.vpd = vpd
        self.stage = stage
        self.status = Self.calculate(temp: temp, humidity: humidity, vpd: vpd, stage: stage)
    }

    /// Calculate environmental status based on temp, humidity, VPD, and growth stage
    public static func calculate(
        temp: Double,
        humidity: Double,
        vpd: Double,
        stage: PlantStage
    ) -> Status {
        // Define optimal ranges per stage
        let optimalTempRange: ClosedRange<Double>
        let optimalHumidityRange: ClosedRange<Double>
        let optimalVPDRange: ClosedRange<Double>

        switch stage {
        case .seedling:
            optimalTempRange = 70...80
            optimalHumidityRange = 65...75
            optimalVPDRange = 0.4...0.8
        case .vegetative:
            optimalTempRange = 70...85
            optimalHumidityRange = 50...70
            optimalVPDRange = 0.8...1.2
        case .flowering:
            optimalTempRange = 65...80
            optimalHumidityRange = 40...55
            optimalVPDRange = 1.0...1.5
        }

        // Check if all metrics in optimal range
        if optimalTempRange.contains(temp) &&
           optimalHumidityRange.contains(humidity) &&
           optimalVPDRange.contains(vpd) {
            return .optimal
        }

        // Check for critical conditions
        if temp < 60 || temp > 95 ||
           humidity < 20 || humidity > 85 ||
           vpd < 0.2 || vpd > 2.5 {
            return .critical
        }

        return .caution
    }
}
