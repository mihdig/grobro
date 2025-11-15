import Foundation

/// Service for aggregating and preparing plant data for analytics visualizations
@MainActor
@Observable
public final class AnalyticsDataService {

    // MARK: - Dependencies

    private let plantStore: PlantStore
    private let eventStore: EventStore

    // MARK: - Cached Data

    private var cachedPlantId: UUID?
    private var cachedGrowthData: GrowthTimelineData?
    private var cachedWateringData: [WateringDataPoint]?
    private var cachedEventDistribution: [EventDistributionData]?
    private var cachedStageDuration: [StageDurationData]?

    // MARK: - Initialization

    public init(plantStore: PlantStore, eventStore: EventStore) {
        self.plantStore = plantStore
        self.eventStore = eventStore
    }

    // MARK: - Public API

    /// Get aggregated growth timeline data for a plant
    /// - Parameter plantId: The plant to analyze
    /// - Returns: Growth timeline data with stage transitions
    public func getGrowthTimelineData(for plantId: UUID) async throws -> GrowthTimelineData {
        // Check cache
        if cachedPlantId == plantId, let cached = cachedGrowthData {
            return cached
        }

        guard let plant = try await plantStore.fetchPlant(id: plantId) else {
            throw AnalyticsError.plantNotFound
        }

        let events = try await eventStore.fetchEvents(for: plantId)

        // Find stage transition events (we'll infer from notes or tracking changes)
        let stageTransitions = extractStageTransitions(from: events, plant: plant)

        let data = GrowthTimelineData(
            plantId: plantId,
            startDate: plant.startDate,
            currentAge: plant.ageInDays,
            currentStage: plant.stage,
            stageTransitions: stageTransitions
        )

        // Cache result
        cachedPlantId = plantId
        cachedGrowthData = data

        return data
    }

    /// Get watering frequency data points for charting
    /// - Parameters:
    ///   - plantId: The plant to analyze
    ///   - dateRange: Optional date range filter
    /// - Returns: Array of watering data points with timestamps and volumes
    public func getWateringFrequency(
        for plantId: UUID,
        dateRange: DateRange? = nil
    ) async throws -> [WateringDataPoint] {
        // Check cache
        if cachedPlantId == plantId,
           let cached = cachedWateringData,
           dateRange == nil {
            return cached
        }

        let events = try await eventStore.fetchEvents(for: plantId)
        let wateringEvents = events.filter { $0.type == .watering }

        // Filter by date range if provided
        let filteredEvents: [Event]
        if let range = dateRange {
            filteredEvents = wateringEvents.filter { event in
                event.timestamp >= range.start && event.timestamp <= range.end
            }
        } else {
            filteredEvents = wateringEvents
        }

        // Group by day and aggregate volume
        let dataPoints = Dictionary(grouping: filteredEvents) { event in
            Calendar.current.startOfDay(for: event.timestamp)
        }.map { date, dayEvents in
            WateringDataPoint(
                date: date,
                count: dayEvents.count,
                totalVolume: dayEvents.compactMap { $0.volumeLiters }.reduce(0, +)
            )
        }.sorted { $0.date < $1.date }

        // Cache if no date range filter
        if dateRange == nil {
            cachedWateringData = dataPoints
        }

        return dataPoints
    }

    /// Get event type distribution for pie chart
    /// - Parameter plantId: The plant to analyze
    /// - Returns: Distribution of event types with counts
    public func getEventDistribution(for plantId: UUID) async throws -> [EventDistributionData] {
        // Check cache
        if cachedPlantId == plantId, let cached = cachedEventDistribution {
            return cached
        }

        let events = try await eventStore.fetchEvents(for: plantId)

        let distribution = Dictionary(grouping: events, by: { $0.type })
            .map { type, typeEvents in
                EventDistributionData(
                    eventType: type,
                    count: typeEvents.count,
                    percentage: 0 // Will calculate after we have total
                )
            }

        let total = distribution.reduce(0) { $0 + $1.count }

        let dataWithPercentages = distribution.map { data in
            EventDistributionData(
                eventType: data.eventType,
                count: data.count,
                percentage: total > 0 ? Double(data.count) / Double(total) * 100 : 0
            )
        }.sorted { $0.count > $1.count }

        // Cache result
        cachedEventDistribution = dataWithPercentages

        return dataWithPercentages
    }

    /// Get duration spent in each growth stage
    /// - Parameter plantId: The plant to analyze
    /// - Returns: Array of stage durations in days
    public func getStageDuration(for plantId: UUID) async throws -> [StageDurationData] {
        // Check cache
        if cachedPlantId == plantId, let cached = cachedStageDuration {
            return cached
        }

        guard let plant = try await plantStore.fetchPlant(id: plantId) else {
            throw AnalyticsError.plantNotFound
        }

        let events = try await eventStore.fetchEvents(for: plantId)
        let stageTransitions = extractStageTransitions(from: events, plant: plant)

        var durations: [StageDurationData] = []

        // Calculate duration for each stage
        for (index, transition) in stageTransitions.enumerated() {
            let endDate: Date
            if index < stageTransitions.count - 1 {
                endDate = stageTransitions[index + 1].date
            } else {
                endDate = Date() // Current stage, use today
            }

            let days = Calendar.current.dateComponents([.day], from: transition.date, to: endDate).day ?? 0

            durations.append(StageDurationData(
                stage: transition.stage,
                durationDays: days,
                startDate: transition.date,
                endDate: endDate
            ))
        }

        // Cache result
        cachedStageDuration = durations

        return durations
    }

    /// Get photos with their timestamps for timeline gallery
    /// - Parameter plantId: The plant to analyze
    /// - Returns: Array of photo metadata sorted by date
    public func getPhotoTimeline(for plantId: UUID) async throws -> [PhotoTimelineItem] {
        let events = try await eventStore.fetchEvents(for: plantId)

        let photoEvents = events
            .filter { $0.photoAssetId != nil }
            .sorted { $0.timestamp < $1.timestamp }

        return photoEvents.map { event in
            PhotoTimelineItem(
                id: event.id,
                photoAssetId: event.photoAssetId!,
                timestamp: event.timestamp,
                ageInDays: calculateAgeInDays(from: event.timestamp, plantId: plantId)
            )
        }
    }

    /// Check if plant has enough data for analytics
    /// - Parameter plantId: The plant to check
    /// - Returns: True if plant is old enough and has events
    public func hasAnalyticsData(for plantId: UUID) async throws -> Bool {
        guard let plant = try await plantStore.fetchPlant(id: plantId) else {
            return false
        }

        // Plant must be at least 7 days old
        guard plant.ageInDays >= 7 else {
            return false
        }

        // Must have at least one event
        let events = try await eventStore.fetchEvents(for: plantId)
        return !events.isEmpty
    }

    /// Invalidate cache when plant data changes
    public func invalidateCache(for plantId: UUID) {
        if cachedPlantId == plantId {
            cachedPlantId = nil
            cachedGrowthData = nil
            cachedWateringData = nil
            cachedEventDistribution = nil
            cachedStageDuration = nil
        }
    }

    // MARK: - Private Helpers

    private func extractStageTransitions(from events: [Event], plant: Plant) -> [StageTransition] {
        var transitions: [StageTransition] = []

        // Add initial stage at start date
        transitions.append(StageTransition(
            stage: .seedling,
            date: plant.startDate
        ))

        // Look for stage transition indicators in notes
        // In a real app, you'd have explicit stage change events
        // For now, we'll infer based on plant's current stage and age

        if plant.stage == .vegetative || plant.stage == .flowering {
            // Estimate seedling lasted about 2 weeks
            let vegStart = Calendar.current.date(
                byAdding: .day,
                value: 14,
                to: plant.startDate
            ) ?? plant.startDate

            transitions.append(StageTransition(
                stage: .vegetative,
                date: vegStart
            ))
        }

        if plant.stage == .flowering {
            // Estimate veg lasted until 2/3 of current age
            let flowerStart = Calendar.current.date(
                byAdding: .day,
                value: Int(Double(plant.ageInDays) * 0.66),
                to: plant.startDate
            ) ?? Date()

            transitions.append(StageTransition(
                stage: .flowering,
                date: flowerStart
            ))
        }

        return transitions
    }

    private func calculateAgeInDays(from timestamp: Date, plantId: UUID) -> Int {
        // This would fetch plant start date, simplified for now
        let daysSince = Calendar.current.dateComponents([.day], from: timestamp, to: Date()).day ?? 0
        return max(0, daysSince)
    }
}

// MARK: - Data Models

/// Growth timeline data with stage transitions
public struct GrowthTimelineData: Sendable {
    public let plantId: UUID
    public let startDate: Date
    public let currentAge: Int
    public let currentStage: PlantStage
    public let stageTransitions: [StageTransition]

    public init(plantId: UUID, startDate: Date, currentAge: Int, currentStage: PlantStage, stageTransitions: [StageTransition]) {
        self.plantId = plantId
        self.startDate = startDate
        self.currentAge = currentAge
        self.currentStage = currentStage
        self.stageTransitions = stageTransitions
    }
}

/// Represents a transition between growth stages
public struct StageTransition: Sendable, Identifiable {
    public let id = UUID()
    public let stage: PlantStage
    public let date: Date

    public init(stage: PlantStage, date: Date) {
        self.stage = stage
        self.date = date
    }
}

/// Watering data point for frequency charts
public struct WateringDataPoint: Sendable, Identifiable {
    public let id = UUID()
    public let date: Date
    public let count: Int
    public let totalVolume: Double

    public init(date: Date, count: Int, totalVolume: Double) {
        self.date = date
        self.count = count
        self.totalVolume = totalVolume
    }
}

/// Event type distribution data
public struct EventDistributionData: Sendable, Identifiable {
    public let id = UUID()
    public let eventType: EventType
    public let count: Int
    public let percentage: Double

    public init(eventType: EventType, count: Int, percentage: Double) {
        self.eventType = eventType
        self.count = count
        self.percentage = percentage
    }
}

/// Stage duration data for bar charts
public struct StageDurationData: Sendable, Identifiable {
    public let id = UUID()
    public let stage: PlantStage
    public let durationDays: Int
    public let startDate: Date
    public let endDate: Date

    public init(stage: PlantStage, durationDays: Int, startDate: Date, endDate: Date) {
        self.stage = stage
        self.durationDays = durationDays
        self.startDate = startDate
        self.endDate = endDate
    }
}

/// Photo timeline item
public struct PhotoTimelineItem: Sendable, Identifiable {
    public let id: UUID
    public let photoAssetId: String
    public let timestamp: Date
    public let ageInDays: Int

    public init(id: UUID, photoAssetId: String, timestamp: Date, ageInDays: Int) {
        self.id = id
        self.photoAssetId = photoAssetId
        self.timestamp = timestamp
        self.ageInDays = ageInDays
    }
}

/// Date range filter for analytics
public struct DateRange: Sendable, Equatable {
    public let start: Date
    public let end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    public static var last30Days: DateRange {
        DateRange(
            start: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            end: Date()
        )
    }

    public static var last90Days: DateRange {
        DateRange(
            start: Calendar.current.date(byAdding: .day, value: -90, to: Date())!,
            end: Date()
        )
    }

    public static func allTime(since startDate: Date) -> DateRange {
        DateRange(start: startDate, end: Date())
    }
}

// MARK: - Errors

public enum AnalyticsError: Error, LocalizedError {
    case plantNotFound
    case insufficientData

    public var errorDescription: String? {
        switch self {
        case .plantNotFound:
            return "Plant not found"
        case .insufficientData:
            return "Not enough data to generate analytics"
        }
    }
}
