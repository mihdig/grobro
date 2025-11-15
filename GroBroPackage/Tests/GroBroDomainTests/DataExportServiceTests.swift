import Testing
import Foundation
@testable import GroBroDomain

@Suite("DataExportService Tests")
struct DataExportServiceTests {

    @Test("Exports JSON with expected structure")
    func testJSONExportStructure() async throws {
        let plantId = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let plant = Plant(
            id: plantId,
            name: "Example Plant",
            strainName: "Test Strain",
            createdAt: now,
            startDate: now,
            stage: .vegetative,
            potSizeLiters: 10,
            substrateType: .soil,
            notes: "Sample notes"
        )

        let event = Event(
            id: UUID(),
            plantId: plantId,
            type: .watering,
            timestamp: now,
            volumeLiters: 1.5,
            noteText: "First watering",
            stressTags: [.heatStress]
        )

        let service = DataExportService()
        let options = DataExportService.Options(
            format: .json,
            anonymizePlantNames: false
        )

        let exportURL = try await service.export(
            plants: [plant],
            events: [event],
            options: options
        )

        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: exportURL.path))

        #if os(macOS)
        if #available(macOS 13.0, *) {
            let unpackDir = fileManager.temporaryDirectory.appendingPathComponent("GroBroJSONTest-\(UUID().uuidString)", isDirectory: true)
            try fileManager.createDirectory(at: unpackDir, withIntermediateDirectories: true)

            try fileManager.unzipItem(at: exportURL, to: unpackDir)

            let jsonURL = unpackDir.appendingPathComponent("data.json")
            #expect(fileManager.fileExists(atPath: jsonURL.path))

            let data = try Data(contentsOf: jsonURL)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            #expect(jsonObject != nil)

            let metadata = jsonObject?["export_metadata"] as? [String: Any]
            #expect(metadata?["app_version"] as? String == "1.0.0")

            let plantsArray = jsonObject?["plants"] as? [[String: Any]]
            #expect(plantsArray?.count == 1)

            if let firstPlant = plantsArray?.first {
                #expect(firstPlant["name"] as? String == "Example Plant")
                let eventsArray = firstPlant["events"] as? [[String: Any]]
                #expect(eventsArray?.count == 1)
            }
        }
        #endif
    }

    @Test("Exports CSV files for plants and events")
    func testCSVExportFiles() async throws {
        let plantId = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let plant = Plant(
            id: plantId,
            name: "CSV Plant",
            strainName: nil,
            createdAt: now,
            startDate: now,
            stage: .seedling,
            potSizeLiters: 5,
            substrateType: .soil
        )

        let event = Event(
            id: UUID(),
            plantId: plantId,
            type: .watering,
            timestamp: now,
            volumeLiters: 1.0,
            noteText: "CSV watering"
        )

        let service = DataExportService()
        let options = DataExportService.Options(
            format: .csv,
            anonymizePlantNames: true
        )

        let exportURL = try await service.export(
            plants: [plant],
            events: [event],
            options: options
        )

        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: exportURL.path))

        #if os(macOS)
        if #available(macOS 13.0, *) {
            let unpackDir = fileManager.temporaryDirectory.appendingPathComponent("GroBroCSVTest-\(UUID().uuidString)", isDirectory: true)
            try fileManager.createDirectory(at: unpackDir, withIntermediateDirectories: true)

            try fileManager.unzipItem(at: exportURL, to: unpackDir)

            let plantsCSVURL = unpackDir.appendingPathComponent("plants.csv")
            let eventsCSVURL = unpackDir.appendingPathComponent("events.csv")

            #expect(fileManager.fileExists(atPath: plantsCSVURL.path))
            #expect(fileManager.fileExists(atPath: eventsCSVURL.path))

            let plantsCSV = try String(contentsOf: plantsCSVURL, encoding: .utf8)
            let eventsCSV = try String(contentsOf: eventsCSVURL, encoding: .utf8)

            #expect(plantsCSV.contains("plant_id,name,strain,created_date,stage,substrate_type,pot_size_liters,status"))
            #expect(eventsCSV.contains("event_id,plant_name,event_type,source,timestamp,notes,water_volume_ml,stress_tags,photo_filename"))

            // Anonymization should replace the plant name in CSV
            #expect(plantsCSV.contains("Plant 1"))
            #expect(!plantsCSV.contains("CSV Plant"))
        }
        #endif
    }
}
