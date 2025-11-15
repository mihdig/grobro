import Testing
import Foundation
@testable import GroBroDomain

/// Tests for FeedingSchedule domain models
@Suite("FeedingSchedule Model Tests")
struct FeedingScheduleTests {

    @Test("FeedingSchedule initializes correctly")
    func feedingScheduleInitialization() {
        let schedule = FeedingSchedule(
            brand: .generalHydroponics,
            productLine: .floraSeries,
            name: "Test Schedule",
            description: "Test Description",
            weeks: [],
            products: ["Product1", "Product2"],
            safetyNotes: ["Safety note 1"]
        )

        #expect(schedule.brand == .generalHydroponics)
        #expect(schedule.productLine == .floraSeries)
        #expect(schedule.name == "Test Schedule")
        #expect(schedule.products.count == 2)
        #expect(schedule.safetyNotes.count == 1)
    }

    @Test("WeeklyDosage initializes correctly")
    func weeklyDosageInitialization() {
        let dosages = [
            ScheduleProductDosage(productName: "FloraMicro", mlPerGallon: 5.0),
            ScheduleProductDosage(productName: "FloraGro", mlPerGallon: 10.0)
        ]

        let week = WeeklyDosage(
            weekNumber: 3,
            stage: .earlyVegetative,
            stageName: "Early Veg",
            productDosages: dosages,
            notes: "Test notes"
        )

        #expect(week.weekNumber == 3)
        #expect(week.stage == .earlyVegetative)
        #expect(week.productDosages.count == 2)
        #expect(week.notes == "Test notes")
    }

    @Test("ScheduleProductDosage calculates ml/L correctly")
    func scheduleProductDosageConversion() {
        let dosage = ScheduleProductDosage(productName: "Test", mlPerGallon: 3.78541)

        // Should convert gallons to liters (1 gallon = 3.78541 liters)
        let mlPerLiter = dosage.mlPerLiter
        #expect(abs(mlPerLiter - 1.0) < 0.01)  // Should be ~1.0 ml/L
    }

    @Test("ProductLine returns correct brand")
    func productLineBrand() {
        #expect(ProductLine.floraSeries.brand == .generalHydroponics)
        #expect(ProductLine.bioThrive.brand == .generalHydroponics)
        #expect(ProductLine.phPerfectGMB.brand == .advancedNutrients)
        #expect(ProductLine.foxFarmTrio.brand == .foxFarm)
    }

    @Test("ProductLine Pro status matches brand")
    func productLineProStatus() {
        // Free tier
        #expect(!ProductLine.floraSeries.requiresPro)
        #expect(!ProductLine.phPerfectGMB.requiresPro)

        // Pro tier
        #expect(ProductLine.foxFarmTrio.requiresPro)
        #expect(ProductLine.cannaTerra.requiresPro)
        #expect(ProductLine.biobizzOrganic.requiresPro)
    }

    @Test("GrowthStage has correct display names")
    func growthStageDisplayNames() {
        #expect(GrowthStage.seedling.displayName == "Seedling/Clone")
        #expect(GrowthStage.earlyVegetative.displayName == "Early Vegetative")
        #expect(GrowthStage.flush.displayName == "Flush")
    }

    @Test("GrowthStage has icons")
    func growthStageIcons() {
        #expect(!GrowthStage.seedling.icon.isEmpty)
        #expect(!GrowthStage.earlyFlowering.icon.isEmpty)
        #expect(GrowthStage.flush.icon == "drop.fill")
    }

    @Test("FeedingSchedule is Codable")
    func feedingScheduleCodable() throws {
        let dosages = [
            ScheduleProductDosage(productName: "FloraMicro", mlPerGallon: 5.0)
        ]

        let week = WeeklyDosage(
            weekNumber: 1,
            stage: .seedling,
            stageName: "Seedling",
            productDosages: dosages
        )

        let schedule = FeedingSchedule(
            brand: .generalHydroponics,
            productLine: .floraSeries,
            name: "Test",
            description: "Test Desc",
            weeks: [week],
            products: ["FloraMicro"],
            safetyNotes: []
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(schedule)
        let decoded = try decoder.decode(FeedingSchedule.self, from: data)

        #expect(decoded.name == schedule.name)
        #expect(decoded.brand == schedule.brand)
        #expect(decoded.weeks.count == 1)
    }

    @Test("ScheduleProductDosage convenience init calculates mlPerLiter")
    func scheduleProductDosageConvenienceInit() {
        let dosage = ScheduleProductDosage(productName: "Test", mlPerGallon: 10.0)

        #expect(dosage.mlPerGallon == 10.0)
        #expect(dosage.mlPerLiter > 0)
        #expect(dosage.mlPerLiter < dosage.mlPerGallon)  // Liters are larger than gallons
    }
}
