import Foundation

/// Service for analyzing environmental data and calculating health scores
@MainActor
public final class EnvironmentalAnalyzer {
    public init() {}

    /// Calculate environmental health score for given events and plant stage
    public func calculateHealthScore(
        events: [Event],
        stage: PlantStage,
        previousPeriodScore: Double? = nil
    ) -> EnvironmentalHealthScore {
        guard !events.isEmpty else {
            return EnvironmentalHealthScore(
                overall: 0,
                tempScore: 0,
                humidityScore: 0,
                vpdScore: 0,
                trend: .stable
            )
        }

        // Define optimal ranges for stage
        let optimalTemp = optimalTempRange(for: stage)
        let optimalHumidity = optimalHumidityRange(for: stage)
        let optimalVPD = optimalVPDRange(for: stage)

        // Extract environmental data points
        let envDataPoints = events.compactMap { $0.environmentalData }

        // Calculate % of time in optimal range for each metric
        let tempInRange = envDataPoints.filter { data in
            guard let temp = data.temperatureFahrenheit else { return false }
            return optimalTemp.contains(temp)
        }.count

        let humidityInRange = envDataPoints.filter { data in
            guard let humidity = data.humidityPercent else { return false }
            return optimalHumidity.contains(humidity)
        }.count

        let vpdInRange = envDataPoints.filter { data in
            guard let vpd = data.vpdKilopascal else { return false }
            return optimalVPD.contains(vpd)
        }.count

        let tempScore = Double(tempInRange) / Double(envDataPoints.count) * 100
        let humidityScore = Double(humidityInRange) / Double(envDataPoints.count) * 100
        let vpdScore = Double(vpdInRange) / Double(envDataPoints.count) * 100

        // Weighted overall score (VPD is most important for plant health)
        let overall = (vpdScore * 0.5) + (tempScore * 0.3) + (humidityScore * 0.2)

        // Calculate trend
        let trend: EnvironmentalHealthScore.Trend
        if let previousScore = previousPeriodScore {
            if overall > previousScore + 5 {
                trend = .improving
            } else if overall < previousScore - 5 {
                trend = .declining
            } else {
                trend = .stable
            }
        } else {
            trend = .stable
        }

        return EnvironmentalHealthScore(
            overall: overall,
            tempScore: tempScore,
            humidityScore: humidityScore,
            vpdScore: vpdScore,
            trend: trend
        )
    }

    // MARK: - Optimal Range Helpers

    private func optimalTempRange(for stage: PlantStage) -> ClosedRange<Double> {
        switch stage {
        case .seedling: return 70...80
        case .vegetative: return 70...85
        case .flowering: return 65...80
        }
    }

    private func optimalHumidityRange(for stage: PlantStage) -> ClosedRange<Double> {
        switch stage {
        case .seedling: return 65...75
        case .vegetative: return 50...70
        case .flowering: return 40...55
        }
    }

    private func optimalVPDRange(for stage: PlantStage) -> ClosedRange<Double> {
        switch stage {
        case .seedling: return 0.4...0.8
        case .vegetative: return 0.8...1.2
        case .flowering: return 1.0...1.5
        }
    }
}

/// Time range for analytics queries
public enum TimeRange: String, CaseIterable, Sendable {
    case day = "24h"
    case week = "7d"
    case month = "30d"
    case all = "All"

    public var displayName: String { rawValue }

    public var timeInterval: TimeInterval? {
        switch self {
        case .day: return 24 * 3600
        case .week: return 7 * 24 * 3600
        case .month: return 30 * 24 * 3600
        case .all: return nil // No limit
        }
    }

    public func startDate(from now: Date = Date()) -> Date? {
        guard let interval = timeInterval else { return nil }
        return now.addingTimeInterval(-interval)
    }
}
