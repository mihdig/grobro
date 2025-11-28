import Testing
import Foundation
@testable import GroBroDomain

@Suite("Nutrient Calculator Tests")
@MainActor
struct NutrientCalculatorTests {

    let calculator = NutrientCalculator()

    @Suite("PPM/EC/TDS Conversion Tests")
    @MainActor
    struct ConversionTests {

        let calculator = NutrientCalculator()

        @Test("EC to PPM 500 scale conversion")
        func testECToPPM500() {
            #expect(calculator.ecToPPM500(1.0) == 500.0)
            #expect(calculator.ecToPPM500(2.0) == 1000.0)
            #expect(calculator.ecToPPM500(1.6) == 800.0)
        }

        @Test("EC to PPM 700 scale conversion")
        func testECToPPM700() {
            #expect(calculator.ecToPPM700(1.0) == 700.0)
            #expect(calculator.ecToPPM700(2.0) == 1400.0)
            #expect(calculator.ecToPPM700(1.6) == 1120.0)
        }

        @Test("PPM to EC conversion with 500 scale")
        func testPPMToEC500() {
            #expect(calculator.ppmToEC(500.0, scale: .scale500) == 1.0)
            #expect(calculator.ppmToEC(1000.0, scale: .scale500) == 2.0)
            #expect(calculator.ppmToEC(800.0, scale: .scale500) == 1.6)
        }

        @Test("PPM to EC conversion with 700 scale")
        func testPPMToEC700() {
            #expect(calculator.ppmToEC(700.0, scale: .scale700) == 1.0)
            #expect(calculator.ppmToEC(1400.0, scale: .scale700) == 2.0)
            #expect(calculator.ppmToEC(1120.0, scale: .scale700) == 1.6)
        }
    }

    @Suite("Dosage Scaling Tests")
    @MainActor
    struct DosageScalingTests {

        let calculator = NutrientCalculator()

        @Test("Scale dosage from per-gallon to reservoir volume")
        func testDosageScaling() {
            let reservoir5Gal = ReservoirVolume(amount: 5.0, unit: .gallons)
            let scaled = calculator.scaleDosage(
                dosagePerGallon: 10.0,
                for: reservoir5Gal
            )
            #expect(scaled == 50.0)
        }

        @Test("Scale dosage with liter reservoir")
        func testDosageScalingLiters() {
            let reservoir20L = ReservoirVolume(amount: 20.0, unit: .liters)
            let scaled = calculator.scaleDosage(
                dosagePerGallon: 10.0,
                for: reservoir20L
            )
            // 20L ≈ 5.28 gallons, so 10 ml/gal * 5.28 ≈ 52.8 ml
            #expect(abs(scaled - 52.8) < 1.0)
        }

        @Test("Calculate multiple product dosages")
        func testCalculateDosages() {
            let product1 = NutrientProduct(
                name: "Product A",
                brand: .generalHydroponics,
                category: .grow
            )
            let product2 = NutrientProduct(
                name: "Product B",
                brand: .generalHydroponics,
                category: .bloom
            )

            let products: [(NutrientProduct, Double)] = [
                (product1, 5.0),  // 5 ml/gal
                (product2, 10.0)  // 10 ml/gal
            ]

            let reservoir = ReservoirVolume(amount: 5.0, unit: .gallons)
            let dosages = calculator.calculateDosages(
                for: products,
                reservoirVolume: reservoir
            )

            #expect(dosages.count == 2)
            #expect(dosages[0].amount == 25.0)  // 5 ml/gal * 5 gal
            #expect(dosages[1].amount == 50.0)  // 10 ml/gal * 5 gal
        }
    }

    @Suite("PPM Recommendation Tests")
    @MainActor
    struct RecommendationTests {

        let calculator = NutrientCalculator()

        @Test("Recommended PPM ranges by stage")
        func testRecommendedRanges() {
            #expect(calculator.recommendedPPMRange(for: .seedling) == 100...250)
            #expect(calculator.recommendedPPMRange(for: .vegetative) == 400...800)
            #expect(calculator.recommendedPPMRange(for: .flowering) == 800...1400)
        }

        @Test("PPM status check - optimal")
        func testPPMStatusOptimal() {
            let status = calculator.checkPPMStatus(600.0, for: .vegetative)
            #expect(status == .optimal)
            #expect(status.warningMessage == nil)
        }

        @Test("PPM status check - low")
        func testPPMStatusLow() {
            let status = calculator.checkPPMStatus(300.0, for: .vegetative)
            #expect(status == .low)
            #expect(status.warningMessage != nil)
        }

        @Test("PPM status check - high")
        func testPPMStatusHigh() {
            let status = calculator.checkPPMStatus(1000.0, for: .vegetative)
            #expect(status == .high)
            #expect(status.warningMessage != nil)
        }
    }

    @Suite("PPM Estimation Tests")
    @MainActor
    struct EstimationTests {

        let calculator = NutrientCalculator()

        @Test("Estimate PPM from dosages")
        func testPPMEstimation() {
            let dosages = [
                NutrientDosage(
                    productId: UUID(),
                    productName: "Product A",
                    amount: 25.0,
                    unit: .milliliters
                ),
                NutrientDosage(
                    productId: UUID(),
                    productName: "Product B",
                    amount: 25.0,
                    unit: .milliliters
                )
            ]

            let reservoir = ReservoirVolume(amount: 5.0, unit: .gallons)
            let estimatedPPM = calculator.estimatePPM(
                from: dosages,
                reservoirVolume: reservoir
            )

            // Total 50ml / 5 gallons = 10 ml/gal * 50 PPM/ml = 500 PPM
            #expect(estimatedPPM == 500.0)
        }

        @Test("Estimate PPM with zero dosages")
        func testPPMEstimationZero() {
            let dosages: [NutrientDosage] = []
            let reservoir = ReservoirVolume(amount: 5.0, unit: .gallons)
            let estimatedPPM = calculator.estimatePPM(
                from: dosages,
                reservoirVolume: reservoir
            )

            #expect(estimatedPPM == 0.0)
        }
    }
}
