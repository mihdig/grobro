import Testing
import Foundation
@testable import GroBroFeature
@testable import GroBroDomain

/// Tests for FeedingScheduleService
@Suite("FeedingScheduleService Tests")
@MainActor
struct FeedingScheduleServiceTests {

    @Test("Service initializes with empty schedules")
    func serviceInitialization() {
        let service = FeedingScheduleService()

        #expect(service.schedules.isEmpty)
        #expect(!service.isLoading)
        #expect(service.error == nil)
    }

    @Test("Service can find schedule by product line")
    func findScheduleByProductLine() async {
        let service = FeedingScheduleService()

        // Create test schedule
        let schedule = FeedingSchedule(
            brand: .generalHydroponics,
            productLine: .floraSeries,
            name: "Flora Test",
            description: "Test",
            weeks: [],
            products: [],
            safetyNotes: []
        )

        // Manually add for testing
        service.setSchedulesForTesting([schedule])

        let found = service.schedule(for: .floraSeries)
        #expect(found != nil)
        #expect(found?.productLine == .floraSeries)
    }

    @Test("Service filters schedules by brand")
    func filterSchedulesByBrand() {
        let service = FeedingScheduleService()

        let gheSchedule = FeedingSchedule(
            brand: .generalHydroponics,
            productLine: .floraSeries,
            name: "GHE",
            description: "Test",
            weeks: [],
            products: [],
            safetyNotes: []
        )

        let anSchedule = FeedingSchedule(
            brand: .advancedNutrients,
            productLine: .phPerfectGMB,
            name: "AN",
            description: "Test",
            weeks: [],
            products: [],
            safetyNotes: []
        )

        service.setSchedulesForTesting([gheSchedule, anSchedule])

        let gheSchedules = service.schedules(for: .generalHydroponics)
        #expect(gheSchedules.count == 1)
        #expect(gheSchedules.first?.brand == .generalHydroponics)

        let anSchedules = service.schedules(for: .advancedNutrients)
        #expect(anSchedules.count == 1)
        #expect(anSchedules.first?.brand == .advancedNutrients)
    }

    @Test("Service finds weekly dosage by week number")
    func findWeeklyDosage() {
        let service = FeedingScheduleService()

        let week1 = WeeklyDosage(
            weekNumber: 1,
            stage: .seedling,
            stageName: "Week 1",
            productDosages: []
        )

        let week2 = WeeklyDosage(
            weekNumber: 2,
            stage: .earlyVegetative,
            stageName: "Week 2",
            productDosages: []
        )

        let schedule = FeedingSchedule(
            brand: .generalHydroponics,
            productLine: .floraSeries,
            name: "Test",
            description: "Test",
            weeks: [week1, week2],
            products: [],
            safetyNotes: []
        )

        service.setSchedulesForTesting([schedule])

        let foundWeek = service.weeklyDosage(for: .floraSeries, week: 2)
        #expect(foundWeek != nil)
        #expect(foundWeek?.weekNumber == 2)
        #expect(foundWeek?.stage == .earlyVegetative)
    }

    @Test("Service returns nil for nonexistent week")
    func nonexistentWeek() {
        let service = FeedingScheduleService()

        let schedule = FeedingSchedule(
            brand: .generalHydroponics,
            productLine: .floraSeries,
            name: "Test",
            description: "Test",
            weeks: [],
            products: [],
            safetyNotes: []
        )

        service.setSchedulesForTesting([schedule])

        let foundWeek = service.weeklyDosage(for: .floraSeries, week: 99)
        #expect(foundWeek == nil)
    }

    @Test("Service returns nil for nonexistent product line")
    func nonexistentProductLine() {
        let service = FeedingScheduleService()

        let found = service.schedule(for: .floraSeries)
        #expect(found == nil)
    }
}
