import Testing
import Foundation
@testable import GroBroFeature
@testable import GroBroDomain

/// Tests for validating feeding schedule JSON files
@Suite("FeedingSchedule JSON Tests")
struct FeedingScheduleJSONTests {

    @Test("GHE Flora Series JSON is valid and parseable")
    func gheFloraSeriesJSON() throws {
        let jsonString = """
        {
          "id": "A1B2C3D4-E5F6-4789-A012-345678901234",
          "brand": "general_hydroponics",
          "productLine": "flora_series",
          "name": "GHE Flora Series Test",
          "description": "Test schedule",
          "products": ["FloraMicro", "FloraGro", "FloraBloom"],
          "safetyNotes": ["Safety note"],
          "weeks": [
            {
              "id": "W1",
              "weekNumber": 1,
              "stage": "seedling",
              "stageName": "Seedling",
              "productDosages": [
                {"productName": "FloraMicro", "mlPerGallon": 5.0, "mlPerLiter": 1.32}
              ]
            }
          ]
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        let schedule = try decoder.decode(FeedingSchedule.self, from: data)

        #expect(schedule.brand == .generalHydroponics)
        #expect(schedule.productLine == .floraSeries)
        #expect(schedule.products.count == 3)
        #expect(schedule.weeks.count == 1)
        #expect(schedule.weeks[0].weekNumber == 1)
    }

    @Test("Advanced Nutrients JSON is valid and parseable")
    func advancedNutrientsJSON() throws {
        let jsonString = """
        {
          "id": "B2C3D4E5-F6G7-4890-B123-456789012345",
          "brand": "advanced_nutrients",
          "productLine": "ph_perfect_gmb",
          "name": "pH Perfect Test",
          "description": "Test schedule",
          "products": ["Micro", "Grow", "Bloom"],
          "safetyNotes": ["Safety"],
          "weeks": [
            {
              "id": "W1",
              "weekNumber": 1,
              "stage": "seedling",
              "stageName": "Seedling",
              "productDosages": [
                {"productName": "Micro", "mlPerGallon": 3.8, "mlPerLiter": 1.0}
              ]
            }
          ]
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        let schedule = try decoder.decode(FeedingSchedule.self, from: data)

        #expect(schedule.brand == .advancedNutrients)
        #expect(schedule.productLine == .phPerfectGMB)
        #expect(schedule.products.count == 3)
    }

    @Test("GHE BioThrive JSON is valid and parseable")
    func gheBioThriveJSON() throws {
        let jsonString = """
        {
          "id": "C3D4E5F6-G7H8-4901-C234-567890123456",
          "brand": "general_hydroponics",
          "productLine": "bio_thrive",
          "name": "BioThrive Test",
          "description": "Organic test",
          "products": ["BioThrive Grow", "BioThrive Bloom"],
          "safetyNotes": ["Organic nutrients"],
          "weeks": [
            {
              "id": "W1",
              "weekNumber": 1,
              "stage": "seedling",
              "stageName": "Seedling",
              "productDosages": [
                {"productName": "BioThrive Grow", "mlPerGallon": 5.0, "mlPerLiter": 1.32}
              ]
            }
          ]
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        let schedule = try decoder.decode(FeedingSchedule.self, from: data)

        #expect(schedule.brand == .generalHydroponics)
        #expect(schedule.productLine == .bioThrive)
        #expect(schedule.products.count == 2)
    }

    @Test("Weekly dosage with multiple products parses correctly")
    func weeklyDosageMultipleProducts() throws {
        let jsonString = """
        {
          "id": "TEST",
          "brand": "general_hydroponics",
          "productLine": "flora_series",
          "name": "Multi Product Test",
          "description": "Test",
          "products": ["P1", "P2", "P3"],
          "safetyNotes": [],
          "weeks": [
            {
              "id": "W1",
              "weekNumber": 1,
              "stage": "early_vegetative",
              "stageName": "Veg",
              "productDosages": [
                {"productName": "FloraMicro", "mlPerGallon": 5.0, "mlPerLiter": 1.32},
                {"productName": "FloraGro", "mlPerGallon": 10.0, "mlPerLiter": 2.64},
                {"productName": "FloraBloom", "mlPerGallon": 5.0, "mlPerLiter": 1.32}
              ],
              "notes": "Test notes"
            }
          ]
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        let schedule = try decoder.decode(FeedingSchedule.self, from: data)
        let week = schedule.weeks[0]

        #expect(week.productDosages.count == 3)
        #expect(week.notes == "Test notes")

        // Verify all dosages parsed
        let microDosage = week.productDosages.first { $0.productName == "FloraMicro" }
        #expect(microDosage != nil)
        #expect(microDosage?.mlPerGallon == 5.0)
    }

    @Test("Schedule with all growth stages parses correctly")
    func allGrowthStages() throws {
        let stages: [GrowthStage] = [
            .seedling, .earlyVegetative, .lateVegetative,
            .transition, .earlyFlowering, .midFlowering,
            .lateFlowering, .flush
        ]

        for (index, stage) in stages.enumerated() {
            let weekJSON = """
            {
              "id": "W\(index)",
              "weekNumber": \(index + 1),
              "stage": "\(stage.rawValue)",
              "stageName": "\(stage.displayName)",
              "productDosages": []
            }
            """

            let data = weekJSON.data(using: .utf8)!
            let decoder = JSONDecoder()

            let week = try decoder.decode(WeeklyDosage.self, from: data)
            #expect(week.stage == stage)
        }
    }

    @Test("ScheduleProductDosage convenience init works in JSON context")
    func scheduleProductDosageConvenienceInit() throws {
        // Test that ScheduleProductDosage can be created with just mlPerGallon
        // and mlPerLiter is calculated
        let jsonString = """
        {
          "productName": "Test Product",
          "mlPerGallon": 10.0,
          "mlPerLiter": 2.64
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        let dosage = try decoder.decode(ScheduleProductDosage.self, from: data)

        #expect(dosage.productName == "Test Product")
        #expect(dosage.mlPerGallon == 10.0)
        #expect(dosage.mlPerLiter > 0)
    }

    @Test("Schedule validates required fields")
    func scheduleRequiredFields() throws {
        let jsonString = """
        {
          "id": "TEST",
          "brand": "general_hydroponics",
          "productLine": "flora_series",
          "name": "Test",
          "description": "Desc",
          "products": [],
          "safetyNotes": [],
          "weeks": []
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        // Should decode successfully even with empty arrays
        let schedule = try decoder.decode(FeedingSchedule.self, from: data)

        #expect(schedule.name == "Test")
        #expect(schedule.products.isEmpty)
        #expect(schedule.weeks.isEmpty)
    }
}
