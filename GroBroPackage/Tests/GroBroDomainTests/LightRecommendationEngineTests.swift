import Foundation
import Testing
@testable import GroBroDomain

/// Tests for light recommendation engine
@Suite("Light Recommendation Engine Tests")
struct LightRecommendationEngineTests {

    let engine = LightRecommendationEngine()

    // MARK: - Seedling Stage Tests

    @Test("Seedling stage recommends 18/6 photoperiod")
    func seedlingPhotoperiod() {
        let recommendation = engine.recommendation(for: .seedling, lightType: .fullSpectrumLED)

        #expect(recommendation.hoursOn == 18)
        #expect(recommendation.hoursOff == 6)
        #expect(recommendation.photoperiodString == "18/6")
    }

    @Test("Seedling stage recommends 200-400 PPFD for LED")
    func seedlingPPFD() {
        let recommendation = engine.recommendation(for: .seedling, lightType: .fullSpectrumLED)

        #expect(recommendation.ppfdRange == 200...400)
    }

    @Test("Seedling stage recommends 15-25 DLI")
    func seedlingDLI() {
        let recommendation = engine.recommendation(for: .seedling, lightType: .fullSpectrumLED)

        #expect(recommendation.dliTarget == 15...25)
    }

    @Test("Seedling spectrum is balanced")
    func seedlingSpectrum() {
        let recommendation = engine.recommendation(for: .seedling, lightType: .fullSpectrumLED)

        guard let spectrum = recommendation.spectrum else {
            #expect(Bool(false), "Expected spectrum recommendation for seedling")
            return
        }

        #expect(spectrum.bluePercentage == 50)
        #expect(spectrum.redPercentage == 30)
        #expect(spectrum.kelvin == 4000...5000)
    }

    // MARK: - Vegetative Stage Tests

    @Test("Vegetative stage recommends 18/6 photoperiod")
    func vegetativePhotoperiod() {
        let recommendation = engine.recommendation(for: .vegetative, lightType: .fullSpectrumLED)

        #expect(recommendation.hoursOn == 18)
        #expect(recommendation.hoursOff == 6)
    }

    @Test("Vegetative stage recommends 400-600 PPFD for LED")
    func vegetativePPFD() {
        let recommendation = engine.recommendation(for: .vegetative, lightType: .fullSpectrumLED)

        #expect(recommendation.ppfdRange == 400...600)
    }

    @Test("Vegetative stage recommends 25-40 DLI")
    func vegetativeDLI() {
        let recommendation = engine.recommendation(for: .vegetative, lightType: .fullSpectrumLED)

        #expect(recommendation.dliTarget == 25...40)
    }

    @Test("Vegetative spectrum is blue-heavy")
    func vegetativeSpectrum() {
        let recommendation = engine.recommendation(for: .vegetative, lightType: .fullSpectrumLED)

        guard let spectrum = recommendation.spectrum else {
            #expect(Bool(false), "Expected spectrum recommendation for vegetative")
            return
        }

        #expect(spectrum.bluePercentage == 60)
        #expect(spectrum.redPercentage == 20)
        #expect(spectrum.kelvin == 5000...6500)
    }

    // MARK: - Flowering Stage Tests

    @Test("Flowering stage recommends 12/12 photoperiod")
    func floweringPhotoperiod() {
        let recommendation = engine.recommendation(for: .flowering, lightType: .fullSpectrumLED)

        #expect(recommendation.hoursOn == 12)
        #expect(recommendation.hoursOff == 12)
        #expect(recommendation.photoperiodString == "12/12")
    }

    @Test("Flowering stage recommends 600-1000 PPFD for LED")
    func floweringPPFD() {
        let recommendation = engine.recommendation(for: .flowering, lightType: .fullSpectrumLED)

        #expect(recommendation.ppfdRange == 600...1000)
    }

    @Test("Flowering stage recommends 35-50 DLI")
    func floweringDLI() {
        let recommendation = engine.recommendation(for: .flowering, lightType: .fullSpectrumLED)

        #expect(recommendation.dliTarget == 35...50)
    }

    @Test("Flowering spectrum is red-heavy")
    func floweringSpectrum() {
        let recommendation = engine.recommendation(for: .flowering, lightType: .fullSpectrumLED)

        guard let spectrum = recommendation.spectrum else {
            #expect(Bool(false), "Expected spectrum recommendation for flowering")
            return
        }

        #expect(spectrum.bluePercentage == 20)
        #expect(spectrum.redPercentage == 60)
        #expect(spectrum.kelvin == 2700...3000)
    }

    // MARK: - Light Type Adjustment Tests

    @Test("HPS/MH PPFD is adjusted down from LED baseline")
    func hpsPPFDAdjustment() {
        let ledRec = engine.recommendation(for: .vegetative, lightType: .fullSpectrumLED)
        let hpsRec = engine.recommendation(for: .vegetative, lightType: .hps)

        // HPS should be 80% of LED
        #expect(hpsRec.ppfdRange.lowerBound < ledRec.ppfdRange.lowerBound)
        #expect(hpsRec.ppfdRange.upperBound < ledRec.ppfdRange.upperBound)
    }

    @Test("CFL PPFD is adjusted up from LED baseline")
    func cflPPFDAdjustment() {
        let ledRec = engine.recommendation(for: .vegetative, lightType: .fullSpectrumLED)
        let cflRec = engine.recommendation(for: .vegetative, lightType: .cfl)

        // CFL should be 120% of LED
        #expect(cflRec.ppfdRange.lowerBound > ledRec.ppfdRange.lowerBound)
        #expect(cflRec.ppfdRange.upperBound > ledRec.ppfdRange.upperBound)
    }

    @Test("CMH PPFD is slightly adjusted down from LED baseline")
    func cmhPPFDAdjustment() {
        let ledRec = engine.recommendation(for: .vegetative, lightType: .fullSpectrumLED)
        let cmhRec = engine.recommendation(for: .vegetative, lightType: .cmh)

        // CMH should be 90% of LED
        #expect(cmhRec.ppfdRange.lowerBound < ledRec.ppfdRange.lowerBound)
        #expect(cmhRec.ppfdRange.upperBound < ledRec.ppfdRange.upperBound)
    }

    // MARK: - Drying and Curing Tests

    @Test("Drying stage has no light requirement")
    func dryingStage() {
        let recommendation = engine.recommendation(for: .drying, lightType: .fullSpectrumLED)

        #expect(recommendation.hoursOn == 0)
        #expect(recommendation.hoursOff == 24)
        #expect(recommendation.ppfdRange == 0...0)
        #expect(recommendation.dliTarget == 0...0)
        #expect(recommendation.spectrum == nil)
    }

    @Test("Curing stage has no light requirement")
    func curingStage() {
        let recommendation = engine.recommendation(for: .curing, lightType: .fullSpectrumLED)

        #expect(recommendation.hoursOn == 0)
        #expect(recommendation.hoursOff == 24)
        #expect(recommendation.ppfdRange == 0...0)
        #expect(recommendation.dliTarget == 0...0)
        #expect(recommendation.spectrum == nil)
    }

    // MARK: - Schedule Validation Tests

    @Test("Valid 18/6 schedule passes validation for vegetative")
    func validVegetativeSchedule() {
        let schedule = LightSchedule(
            startTime: Date(),
            hoursOn: 18,
            hoursOff: 6
        )

        let validation = engine.validateSchedule(schedule, for: .vegetative)
        #expect(validation.isValid)
        #expect(validation.warnings.isEmpty)
    }

    @Test("Valid 12/12 schedule passes validation for flowering")
    func validFloweringSchedule() {
        let schedule = LightSchedule(
            startTime: Date(),
            hoursOn: 12,
            hoursOff: 12
        )

        let validation = engine.validateSchedule(schedule, for: .flowering)
        #expect(validation.isValid)
        #expect(validation.warnings.isEmpty)
    }

    @Test("Schedule with total hours != 24 is invalid")
    func invalidTotalHours() {
        let schedule = LightSchedule(
            startTime: Date(),
            hoursOn: 18,
            hoursOff: 8 // Total = 26, invalid
        )

        let validation = engine.validateSchedule(schedule, for: .vegetative)
        #expect(!validation.isValid)
        #expect(validation.warnings.count > 0)
    }

    @Test("Less than 12 hours light in vegetative shows warning")
    func shortVegetativePhotoperiod() {
        let schedule = LightSchedule(
            startTime: Date(),
            hoursOn: 10,
            hoursOff: 14
        )

        let validation = engine.validateSchedule(schedule, for: .vegetative)
        #expect(!validation.isValid)
        #expect(validation.warnings.contains { $0.contains("12 hours") })
    }

    @Test("More than 13 hours light in flowering shows warning")
    func longFloweringPhotoperiod() {
        let schedule = LightSchedule(
            startTime: Date(),
            hoursOn: 16,
            hoursOff: 8
        )

        let validation = engine.validateSchedule(schedule, for: .flowering)
        #expect(!validation.isValid)
        #expect(validation.warnings.contains { $0.contains("12/12") })
    }

    @Test("Schedule deviation of 2+ hours shows warning")
    func scheduleDeviation() {
        // Recommended is 18/6, trying 14/10 (4 hours deviation)
        let schedule = LightSchedule(
            startTime: Date(),
            hoursOn: 14,
            hoursOff: 10
        )

        let validation = engine.validateSchedule(schedule, for: .vegetative)
        #expect(!validation.isValid)
        #expect(validation.warnings.count > 0)
    }

    // MARK: - Integration Tests

    @Test("All stages return valid recommendations")
    func allStagesValid() {
        let stages: [PlantStage] = [.seedling, .vegetative, .flowering, .drying, .curing]

        for stage in stages {
            let recommendation = engine.recommendation(for: stage, lightType: .fullSpectrumLED)

            // All should have valid total hours
            #expect(recommendation.hoursOn + recommendation.hoursOff == 24)

            // DLI target lower bound should be <= upper bound
            #expect(recommendation.dliTarget.lowerBound <= recommendation.dliTarget.upperBound)

            // PPFD range lower bound should be <= upper bound
            #expect(recommendation.ppfdRange.lowerBound <= recommendation.ppfdRange.upperBound)
        }
    }
}
