import Foundation

/// Aggregate environmental statistics for a time period
public struct EnvironmentalStats: Sendable {
    public let current: MetricValues?
    public let min: MetricValues
    public let max: MetricValues
    public let avg: MetricValues

    public struct MetricValues: Sendable {
        public let temperature: Double
        public let humidity: Double
        public let vpd: Double

        public init(temperature: Double, humidity: Double, vpd: Double) {
            self.temperature = temperature
            self.humidity = humidity
            self.vpd = vpd
        }
    }

    public init(events: [Event]) {
        let envData = events.compactMap { $0.environmentalData }

        let temps = envData.compactMap { $0.temperatureFahrenheit }
        let humidities = envData.compactMap { $0.humidityPercent }
        let vpds = envData.compactMap { $0.vpdKilopascal }

        self.current = events.last?.environmentalData.flatMap {
            guard let temp = $0.temperatureFahrenheit,
                  let humidity = $0.humidityPercent,
                  let vpd = $0.vpdKilopascal else {
                return nil
            }
            return MetricValues(temperature: temp, humidity: humidity, vpd: vpd)
        }

        self.min = MetricValues(
            temperature: temps.min() ?? 0,
            humidity: humidities.min() ?? 0,
            vpd: vpds.min() ?? 0
        )

        self.max = MetricValues(
            temperature: temps.max() ?? 0,
            humidity: humidities.max() ?? 0,
            vpd: vpds.max() ?? 0
        )

        self.avg = MetricValues(
            temperature: temps.isEmpty ? 0 : temps.reduce(0, +) / Double(temps.count),
            humidity: humidities.isEmpty ? 0 : humidities.reduce(0, +) / Double(humidities.count),
            vpd: vpds.isEmpty ? 0 : vpds.reduce(0, +) / Double(vpds.count)
        )
    }
}
