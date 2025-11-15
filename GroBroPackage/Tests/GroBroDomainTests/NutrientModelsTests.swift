import Testing
import Foundation
@testable import GroBroDomain

@Suite("Nutrient Brand Tests")
struct NutrientBrandTests {

    @Test("Brand display names are correct")
    func testBrandDisplayNames() {
        #expect(NutrientBrand.generalHydroponics.displayName == "General Hydroponics")
        #expect(NutrientBrand.advancedNutrients.displayName == "Advanced Nutrients")
        #expect(NutrientBrand.foxFarm.displayName == "Fox Farm")
        #expect(NutrientBrand.canna.displayName == "Canna")
        #expect(NutrientBrand.biobizz.displayName == "BioBizz")
    }

    @Test("Pro brands are correctly identified")
    func testProBrands() {
        // Free brands
        #expect(NutrientBrand.generalHydroponics.requiresPro == false)
        #expect(NutrientBrand.advancedNutrients.requiresPro == false)

        // Pro brands
        #expect(NutrientBrand.foxFarm.requiresPro == true)
        #expect(NutrientBrand.canna.requiresPro == true)
        #expect(NutrientBrand.biobizz.requiresPro == true)
    }
}

@Suite("Nutrient Product Tests")
struct NutrientProductTests {

    @Test("Product creation with NPK ratio")
    func testProductCreationWithNPK() {
        let npk = NPKRatio(nitrogen: 5, phosphorus: 10, potassium: 5)
        let product = NutrientProduct(
            name: "FloraBloom",
            brand: .generalHydroponics,
            npkRatio: npk,
            category: .bloom
        )

        #expect(product.name == "FloraBloom")
        #expect(product.brand == .generalHydroponics)
        #expect(product.npkRatio?.nitrogen == 5)
        #expect(product.npkRatio?.phosphorus == 10)
        #expect(product.npkRatio?.potassium == 5)
        #expect(product.category == .bloom)
    }

    @Test("NPK ratio formatting")
    func testNPKFormatting() {
        let npk = NPKRatio(nitrogen: 5, phosphorus: 10, potassium: 5)
        #expect(npk.formatted == "5-10-5")
    }
}

@Suite("Nutrient Dosage Tests")
struct NutrientDosageTests {

    @Test("Dosage conversion to milliliters")
    func testDosageConversions() {
        let mlDosage = NutrientDosage(
            productId: UUID(),
            productName: "Test Product",
            amount: 10.0,
            unit: .milliliters
        )
        #expect(mlDosage.amountInMilliliters == 10.0)

        let tspDosage = NutrientDosage(
            productId: UUID(),
            productName: "Test Product",
            amount: 1.0,
            unit: .teaspoons
        )
        #expect(abs(tspDosage.amountInMilliliters - 4.92892) < 0.01)

        let tbspDosage = NutrientDosage(
            productId: UUID(),
            productName: "Test Product",
            amount: 1.0,
            unit: .tablespoons
        )
        #expect(abs(tbspDosage.amountInMilliliters - 14.7868) < 0.01)
    }

    @Test("Dosage formatted display")
    func testDosageFormatting() {
        let dosage = NutrientDosage(
            productId: UUID(),
            productName: "Test",
            amount: 5.5,
            unit: .milliliters
        )
        #expect(dosage.formattedAmount == "5.50 ml")
    }
}

@Suite("Reservoir Volume Tests")
struct ReservoirVolumeTests {

    @Test("Volume conversions")
    func testVolumeConversions() {
        let liters = ReservoirVolume(amount: 10.0, unit: .liters)
        #expect(liters.liters == 10.0)
        #expect(abs(liters.gallons - 2.64172) < 0.01)

        let gallons = ReservoirVolume(amount: 5.0, unit: .gallons)
        #expect(gallons.gallons == 5.0)
        #expect(abs(gallons.liters - 18.92705) < 0.01)
    }

    @Test("Volume formatting")
    func testVolumeFormatting() {
        let volume = ReservoirVolume(amount: 15.5, unit: .liters)
        #expect(volume.formatted == "15.5 L")
    }
}

@Suite("Nutrient Mix Tests")
struct NutrientMixTests {

    @Test("Mix creation with dosages")
    func testMixCreation() {
        let dosage1 = NutrientDosage(
            productId: UUID(),
            productName: "Product A",
            amount: 5.0,
            unit: .milliliters
        )
        let dosage2 = NutrientDosage(
            productId: UUID(),
            productName: "Product B",
            amount: 10.0,
            unit: .milliliters
        )

        let mix = NutrientMix(
            dosages: [dosage1, dosage2],
            brand: .generalHydroponics,
            productLine: "Flora Series",
            reservoirVolume: ReservoirVolume(amount: 5.0, unit: .gallons),
            plantStage: .flowering,
            estimatedPPM: 800.0
        )

        #expect(mix.productCount == 2)
        #expect(mix.brand == .generalHydroponics)
        #expect(mix.estimatedPPM == 800.0)
    }
}

@Suite("Nutrient Event Data Tests")
struct NutrientEventDataTests {

    @Test("Event data creation with full nutrient info")
    func testEventDataCreation() {
        let dosage = ProductDosage(
            productName: "FloraGro",
            amount: 5.0,
            unit: "ml"
        )

        let eventData = NutrientEventData(
            brand: "General Hydroponics",
            productLine: "Flora Series",
            dosages: [dosage],
            feedPPM: 800.0,
            feedEC: 1.6,
            runoffPPM: 850.0,
            feedPH: 5.8,
            runoffPH: 6.2,
            reservoirVolumeLiters: 18.9
        )

        #expect(eventData.brand == "General Hydroponics")
        #expect(eventData.feedPPM == 800.0)
        #expect(eventData.feedEC == 1.6)
        #expect(eventData.feedPH == 5.8)
        #expect(eventData.dosages?.count == 1)
    }

    @Test("Event data is Codable")
    func testEventDataCodable() throws {
        let eventData = NutrientEventData(
            brand: "Test Brand",
            feedPPM: 500.0,
            feedPH: 6.0
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(eventData)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(NutrientEventData.self, from: data)

        #expect(decoded.brand == "Test Brand")
        #expect(decoded.feedPPM == 500.0)
        #expect(decoded.feedPH == 6.0)
    }
}
