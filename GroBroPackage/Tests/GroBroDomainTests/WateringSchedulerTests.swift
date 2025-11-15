import Testing
import Foundation
@testable import GroBroDomain

@Suite("WateringScheduler Tests")
struct WateringSchedulerTests {

    // MARK: - Interval Calculation Tests

    @Test("Computes reasonable intervals for different stages and substrates")
    func testComputeSuggestedInterval() {
        // Seedling in soil
        let seedlingSoil = Plant(
            name: "Test Seedling",
            stage: .seedling,
            potSizeLiters: 10,
            substrateType: .soil
        )
        let seedlingInterval = WateringScheduler.computeSuggestedInterval(for: seedlingSoil)
        #expect(seedlingInterval >= 1 && seedlingInterval <= 4)

        // Vegetative in coco
        let vegCoco = Plant(
            name: "Test Veg",
            stage: .vegetative,
            potSizeLiters: 15,
            substrateType: .coco
        )
        let vegInterval = WateringScheduler.computeSuggestedInterval(for: vegCoco)
        #expect(vegInterval >= 1 && vegInterval <= 4)

        // Flowering in hydro
        let flowerHydro = Plant(
            name: "Test Flower",
            stage: .flowering,
            potSizeLiters: 20,
            substrateType: .hydro
        )
        let flowerInterval = WateringScheduler.computeSuggestedInterval(for: flowerHydro)
        #expect(flowerInterval >= 0 && flowerInterval <= 1)
    }

    @Test("Adjusts interval for pot size")
    func testPotSizeAdjustment() {
        // Small pot should water more frequently
        let smallPot = Plant(
            name: "Small",
            stage: .vegetative,
            potSizeLiters: 3,
            substrateType: .soil
        )

        // Large pot should water less frequently
        let largePot = Plant(
            name: "Large",
            stage: .vegetative,
            potSizeLiters: 30,
            substrateType: .soil
        )

        let smallInterval = WateringScheduler.computeSuggestedInterval(for: smallPot)
        let largeInterval = WateringScheduler.computeSuggestedInterval(for: largePot)

        // Large pot should have longer interval
        #expect(largeInterval > smallInterval)
    }

    // MARK: - Feedback Adjustment Tests

    @Test("Increases interval when feedback is 'too early'")
    func testTooEarlyFeedback() {
        let plant = Plant(
            name: "Test",
            stage: .vegetative,
            potSizeLiters: 10,
            substrateType: .soil
        )

        let originalInterval = 3
        let newInterval = WateringScheduler.adjustInterval(
            currentIntervalDays: originalInterval,
            feedback: .tooEarly,
            for: plant
        )

        #expect(newInterval > originalInterval)
    }

    @Test("Decreases interval when feedback is 'too late'")
    func testTooLateFeedback() {
        let plant = Plant(
            name: "Test",
            stage: .vegetative,
            potSizeLiters: 10,
            substrateType: .soil
        )

        let originalInterval = 3
        let newInterval = WateringScheduler.adjustInterval(
            currentIntervalDays: originalInterval,
            feedback: .tooLate,
            for: plant
        )

        #expect(newInterval < originalInterval)
    }

    @Test("Keeps interval same when feedback is 'just right'")
    func testJustRightFeedback() {
        let plant = Plant(
            name: "Test",
            stage: .vegetative,
            potSizeLiters: 10,
            substrateType: .soil
        )

        let originalInterval = 3
        let newInterval = WateringScheduler.adjustInterval(
            currentIntervalDays: originalInterval,
            feedback: .justRight,
            for: plant
        )

        #expect(newInterval == originalInterval)
    }

    @Test("Respects minimum and maximum bounds")
    func testBoundsEnforcement() {
        let plant = Plant(
            name: "Test",
            stage: .seedling,
            potSizeLiters: 10,
            substrateType: .soil
        )

        // Try to go below minimum
        let atMin = 1
        let belowMin = WateringScheduler.adjustInterval(
            currentIntervalDays: atMin,
            feedback: .tooLate,
            for: plant
        )
        #expect(belowMin >= 1) // Should not go below min

        // Try to go above maximum
        let atMax = 4
        let aboveMax = WateringScheduler.adjustInterval(
            currentIntervalDays: atMax,
            feedback: .tooEarly,
            for: plant
        )
        #expect(aboveMax <= 4) // Should not go above max
    }

    // MARK: - Next Watering Date Tests

    @Test("Computes next watering date correctly")
    func testComputeNextWateringDate() {
        let lastWatering = Date()
        let intervalDays = 3

        let nextDate = WateringScheduler.computeNextWateringDate(
            lastWateringDate: lastWatering,
            intervalDays: intervalDays
        )

        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: lastWatering, to: nextDate).day

        #expect(daysDifference == intervalDays)
    }

    // MARK: - Watering Status Tests

    @Test("Computes watering status correctly for upcoming watering")
    func testWateringStatusUpcoming() {
        let now = Date()
        let nextWatering = Calendar.current.date(byAdding: .day, value: 2, to: now)!

        let status = WateringScheduler.computeWateringStatus(
            nextWateringDate: nextWatering,
            now: now
        )

        #expect(status.daysUntilWatering == 2)
        #expect(status.isOverdue == false)
        #expect(status.statusMessage.contains("2 days"))
    }

    @Test("Computes watering status correctly for overdue watering")
    func testWateringStatusOverdue() {
        let now = Date()
        let nextWatering = Calendar.current.date(byAdding: .day, value: -3, to: now)!

        let status = WateringScheduler.computeWateringStatus(
            nextWateringDate: nextWatering,
            now: now
        )

        #expect(status.daysUntilWatering < 0)
        #expect(status.isOverdue == true)
        #expect(status.statusMessage.contains("overdue"))
    }

    @Test("Handles today's watering correctly")
    func testWateringStatusToday() {
        let now = Date()

        let status = WateringScheduler.computeWateringStatus(
            nextWateringDate: now,
            now: now
        )

        #expect(status.daysUntilWatering == 0)
        #expect(status.isOverdue == false)
        #expect(status.statusMessage.contains("today"))
    }
}
