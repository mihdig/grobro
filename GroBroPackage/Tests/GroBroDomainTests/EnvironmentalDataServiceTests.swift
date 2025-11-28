import Testing
import Foundation
@testable import GroBroDomain

@Suite("Environmental Data Service Tests")
@MainActor
struct EnvironmentalDataServiceTests {
    let plantStore: PlantStore
    let eventStore: EventStore
    let service: EnvironmentalDataService

    init() {
        // Use preview/in-memory stores for testing
        self.plantStore = PlantStore()
        self.eventStore = EventStore()
        self.service = EnvironmentalDataService(eventStore: eventStore)
    }

    @Test("Group events by hour when density is high")
    func testHourlyGrouping() async throws {
        let plantId = UUID()
        var events: [Event] = []

        // Create 15 events in a day (> 10/day threshold)
        for i in 0..<15 {
            let timestamp = Date().addingTimeInterval(Double(i) * 3600) // Every hour
            events.append(Event(
                plantId: plantId,
                type: .environment,
                timestamp: timestamp,
                environmentalData: EnvironmentalData(
                    temperatureFahrenheit: 75,
                    humidityPercent: 60,
                    vpdKilopascal: 1.0
                )
            ))
        }

        let groups = service.groupEnvironmentalEvents(events)

        // Should group by hour
        #expect(groups.count > 0)
        #expect(groups.count < events.count) // Should be grouped
    }

    @Test("No grouping for sparse events")
    func testNoGroupingForSparseEvents() async throws {
        let plantId = UUID()
        var events: [Event] = []

        // Create 5 events over a week
        for i in 0..<5 {
            let timestamp = Date().addingTimeInterval(Double(i) * 24 * 3600)
            events.append(Event(
                plantId: plantId,
                type: .environment,
                timestamp: timestamp,
                environmentalData: EnvironmentalData(
                    temperatureFahrenheit: 75,
                    humidityPercent: 60,
                    vpdKilopascal: 1.0
                )
            ))
        }

        let groups = service.groupEnvironmentalEvents(events)

        // Should not group (each event is its own group)
        #expect(groups.count == events.count)
    }

    @Test("Correlation detection - high temp with stress")
    func testCorrelationHighTemp() async throws {
        let plantId = UUID()

        // Environmental event with high temp
        let envEvent = Event(
            plantId: plantId,
            type: .environment,
            timestamp: Date(),
            environmentalData: EnvironmentalData(
                temperatureFahrenheit: 90,
                humidityPercent: 60,
                vpdKilopascal: 1.5
            )
        )

        // Stress event at same time
        let stressEvent = Event(
            plantId: plantId,
            type: .stress,
            timestamp: Date(),
            stressTags: [.heatStress]
        )

        let correlations = service.detectCorrelations(
            environmentalEvents: [envEvent],
            plantEvents: [stressEvent]
        )

        #expect(!correlations.isEmpty)
        #expect(correlations[0].message.contains("high temp"))
    }

    @Test("Correlation detection - low humidity with stress")
    func testCorrelationLowHumidity() async throws {
        let plantId = UUID()

        let envEvent = Event(
            plantId: plantId,
            type: .environment,
            timestamp: Date(),
            environmentalData: EnvironmentalData(
                temperatureFahrenheit: 75,
                humidityPercent: 25,
                vpdKilopascal: 2.0
            )
        )

        let stressEvent = Event(
            plantId: plantId,
            type: .stress,
            timestamp: Date(),
            stressTags: [.underwatering]
        )

        let correlations = service.detectCorrelations(
            environmentalEvents: [envEvent],
            plantEvents: [stressEvent]
        )

        #expect(!correlations.isEmpty)
        #expect(correlations[0].message.contains("low humidity"))
    }

    @Test("No correlation for distant events")
    func testNoCorrelationForDistantEvents() async throws {
        let plantId = UUID()

        let envEvent = Event(
            plantId: plantId,
            type: .environment,
            timestamp: Date(),
            environmentalData: EnvironmentalData(
                temperatureFahrenheit: 90,
                humidityPercent: 60,
                vpdKilopascal: 1.5
            )
        )

        // Stress event 10 hours later (outside 4-hour window)
        let stressEvent = Event(
            plantId: plantId,
            type: .stress,
            timestamp: Date().addingTimeInterval(10 * 3600),
            stressTags: [.heatStress]
        )

        let correlations = service.detectCorrelations(
            environmentalEvents: [envEvent],
            plantEvents: [stressEvent]
        )

        #expect(correlations.isEmpty)
    }

    @Test("Group aggregate statistics")
    func testGroupAggregateStatistics() async throws {
        let plantId = UUID()
        var events: [Event] = []

        // Create events with varying temperatures
        events.append(Event(
            plantId: plantId,
            type: .environment,
            timestamp: Date(),
            environmentalData: EnvironmentalData(
                temperatureFahrenheit: 70,
                humidityPercent: 55,
                vpdKilopascal: 1.0
            )
        ))

        events.append(Event(
            plantId: plantId,
            type: .environment,
            timestamp: Date().addingTimeInterval(600),
            environmentalData: EnvironmentalData(
                temperatureFahrenheit: 80,
                humidityPercent: 65,
                vpdKilopascal: 1.2
            )
        ))

        let group = EnvironmentalEventGroup(
            timestamp: Date(),
            events: events,
            groupingInterval: 3600
        )

        #expect(group.avgTemperature == 75)
        #expect(group.minTemperature == 70)
        #expect(group.maxTemperature == 80)
        #expect(group.avgHumidity == 60)
    }
}
