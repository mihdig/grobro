import Foundation

/// Service for environmental data operations including grouping and correlation detection
@MainActor
public final class EnvironmentalDataService {
    private let eventStore: EventStore

    public init(eventStore: EventStore) {
        self.eventStore = eventStore
    }

    // MARK: - Time-Based Grouping

    /// Group environmental events by time period to reduce clutter
    /// Groups by hour if > 10 events/day, by day if > 100 events/week
    public func groupEnvironmentalEvents(_ events: [Event]) -> [EnvironmentalEventGroup] {
        let envEvents = events.filter { $0.type == .environment }

        guard !envEvents.isEmpty else { return [] }

        // Determine grouping interval based on event density
        let groupingInterval = determineGroupingInterval(for: envEvents)

        // Group events by time buckets
        let grouped = Dictionary(grouping: envEvents) { event in
            roundToInterval(event.timestamp, interval: groupingInterval)
        }

        // Create groups
        return grouped.map { timestamp, events in
            EnvironmentalEventGroup(
                timestamp: timestamp,
                events: events,
                groupingInterval: groupingInterval
            )
        }.sorted { $0.timestamp > $1.timestamp } // Most recent first
    }

    private func determineGroupingInterval(for events: [Event]) -> TimeInterval {
        guard let earliest = events.map(\.timestamp).min(),
              let latest = events.map(\.timestamp).max() else {
            return 3600 // Default to hourly
        }

        let duration = latest.timeIntervalSince(earliest)
        let daysSpan = duration / (24 * 3600)
        let eventsPerDay = Double(events.count) / max(daysSpan, 1)

        // Group by hour if > 10 events/day
        if eventsPerDay > 10 {
            return 3600 // 1 hour
        }

        // Group by day if > 100 events/week
        let eventsPerWeek = eventsPerDay * 7
        if eventsPerWeek > 100 {
            return 24 * 3600 // 1 day
        }

        // Otherwise, no grouping needed
        return 0
    }

    private func roundToInterval(_ date: Date, interval: TimeInterval) -> Date {
        guard interval > 0 else { return date }
        let seconds = date.timeIntervalSince1970
        let rounded = floor(seconds / interval) * interval
        return Date(timeIntervalSince1970: rounded)
    }

    // MARK: - Correlation Detection

    /// Detect correlations between environmental events and plant events
    public func detectCorrelations(
        environmentalEvents: [Event],
        plantEvents: [Event]
    ) -> [EventCorrelation] {
        var correlations: [EventCorrelation] = []

        for plantEvent in plantEvents {
            // Find env events within ±4 hours
            let nearbyEnvEvents = environmentalEvents.filter { envEvent in
                abs(envEvent.timestamp.timeIntervalSince(plantEvent.timestamp)) < 4 * 3600
            }

            for envEvent in nearbyEnvEvents {
                guard let envData = envEvent.environmentalData,
                      let temp = envData.temperatureFahrenheit,
                      let humidity = envData.humidityPercent,
                      let vpd = envData.vpdKilopascal else {
                    continue
                }

                // Check for anomalies correlated with stress events
                if plantEvent.type == .stress {
                    if temp > 85 {
                        correlations.append(EventCorrelation(
                            message: "During high temp period",
                            relatedEventId: plantEvent.id
                        ))
                    }
                    if humidity < 30 {
                        correlations.append(EventCorrelation(
                            message: "During low humidity",
                            relatedEventId: plantEvent.id
                        ))
                    }
                    if vpd > 1.8 {
                        correlations.append(EventCorrelation(
                            message: "High VPD stress",
                            relatedEventId: plantEvent.id
                        ))
                    }
                }
            }
        }

        return correlations
    }
}

// MARK: - Environmental Event Group

/// A group of environmental events aggregated by time period
public struct EnvironmentalEventGroup: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let events: [Event]
    public let groupingInterval: TimeInterval

    // Aggregate statistics
    public var avgTemperature: Double {
        let temps = events.compactMap { $0.environmentalData?.temperatureFahrenheit }
        guard !temps.isEmpty else { return 0 }
        return temps.reduce(0, +) / Double(temps.count)
    }

    public var avgHumidity: Double {
        let humidity = events.compactMap { $0.environmentalData?.humidityPercent }
        guard !humidity.isEmpty else { return 0 }
        return humidity.reduce(0, +) / Double(humidity.count)
    }

    public var avgVPD: Double {
        let vpds = events.compactMap { $0.environmentalData?.vpdKilopascal }
        guard !vpds.isEmpty else { return 0 }
        return vpds.reduce(0, +) / Double(vpds.count)
    }

    public var minTemperature: Double {
        events.compactMap { $0.environmentalData?.temperatureFahrenheit }.min() ?? 0
    }

    public var maxTemperature: Double {
        events.compactMap { $0.environmentalData?.temperatureFahrenheit }.max() ?? 0
    }

    public var minHumidity: Double {
        events.compactMap { $0.environmentalData?.humidityPercent }.min() ?? 0
    }

    public var maxHumidity: Double {
        events.compactMap { $0.environmentalData?.humidityPercent }.max() ?? 0
    }

    public init(timestamp: Date, events: [Event], groupingInterval: TimeInterval) {
        self.timestamp = timestamp
        self.events = events
        self.groupingInterval = groupingInterval
    }

    /// Human-readable summary
    public func summary(using userSettings: UserSettings = .shared) -> String {
        if groupingInterval == 3600 {
            return "Hourly: Temp: \(userSettings.formatTemperature(minTemperature))-\(userSettings.formatTemperature(maxTemperature)), RH: \(Int(minHumidity))-\(Int(maxHumidity))%, VPD: \(String(format: "%.1f", avgVPD)) kPa"
        } else if groupingInterval == 24 * 3600 {
            return "Daily: Temp: \(userSettings.formatTemperature(minTemperature))-\(userSettings.formatTemperature(maxTemperature)), RH: \(Int(minHumidity))-\(Int(maxHumidity))%, VPD: \(String(format: "%.1f", avgVPD)) kPa"
        } else {
            return ""
        }
    }
}
