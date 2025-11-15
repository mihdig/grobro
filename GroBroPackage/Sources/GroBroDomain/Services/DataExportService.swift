import Foundation

/// Service responsible for exporting plant and diary data to CSV or JSON files.
/// This service is UI-agnostic and can be used from SwiftUI views or view models.
@available(iOS 17.0, macOS 14.0, *)
public struct DataExportService: Sendable {

    // MARK: - Types

    public enum Format: String, Sendable, CaseIterable {
        case csv
        case json
    }

    /// Options controlling how an export is generated.
    public struct Options: Sendable {
        public let format: Format
        public let anonymizePlantNames: Bool
        /// Optional date range filter applied to events.
        public let dateRange: ClosedRange<Date>?
        /// App version recorded in export metadata.
        public let appVersion: String
        /// Time zone identifier recorded in export metadata.
        public let timeZone: TimeZone

        public init(
            format: Format,
            anonymizePlantNames: Bool,
            dateRange: ClosedRange<Date>? = nil,
            appVersion: String = "1.0.0",
            timeZone: TimeZone = .current
        ) {
            self.format = format
            self.anonymizePlantNames = anonymizePlantNames
            self.dateRange = dateRange
            self.appVersion = appVersion
            self.timeZone = timeZone
        }
    }

    private struct ExportSnapshot: Sendable {
        let plants: [Plant]
        let events: [Event]
        let options: Options
        let createdAt: Date
    }

    // MARK: - Public API

    public init() {}

    /// Exports the provided plants and events according to the given options.
    /// Heavy work is performed on a background task; callers should `await` this method.
    /// - Parameters:
    ///   - plants: Plants to include in the export.
    ///   - events: Events to include in the export.
    ///   - options: Export options (format, anonymization, date range).
    ///   - progressHandler: Optional callback with progress in 0...1.
    /// - Returns: URL to the generated export file (usually a `.zip` archive).
    public func export(
        plants: [Plant],
        events: [Event],
        options: Options,
        progressHandler: (@Sendable (Double) -> Void)? = nil
    ) async throws -> URL {
        let snapshot = ExportSnapshot(
            plants: plants,
            events: events,
            options: options,
            createdAt: Date()
        )

        return try await Task.detached(priority: .userInitiated) {
            try Self.performExport(
                snapshot: snapshot,
                progressHandler: progressHandler
            )
        }.value
    }

    // MARK: - Internal Export Implementation

    private static func performExport(
        snapshot: ExportSnapshot,
        progressHandler: (@Sendable (Double) -> Void)?
    ) throws -> URL {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory
        let exportId = UUID().uuidString

        let workingDirectory = tempRoot.appendingPathComponent("GroBroExport-\(exportId)", isDirectory: true)
        try fileManager.createDirectory(at: workingDirectory, withIntermediateDirectories: true)

        let filteredEvents = applyDateFilter(
            events: snapshot.events,
            range: snapshot.options.dateRange
        )

        let (plantsForExport, eventsForExport, nameMap) = prepareAnonymizedData(
            plants: snapshot.plants,
            events: filteredEvents,
            anonymize: snapshot.options.anonymizePlantNames
        )

        let metadata = ExportMetadata(
            exportDate: snapshot.createdAt,
            appVersion: snapshot.options.appVersion,
            timeZoneIdentifier: snapshot.options.timeZone.identifier
        )

        let totalUnits = max(plantsForExport.count + eventsForExport.count, 1)
        var processedUnits = 0

        func reportProgress() {
            let progress = Double(processedUnits) / Double(totalUnits)
            progressHandler?(min(max(progress, 0), 1))
        }

        // Write files based on format
        switch snapshot.options.format {
        case .csv:
            let plantsURL = workingDirectory.appendingPathComponent("plants.csv")
            let eventsURL = workingDirectory.appendingPathComponent("events.csv")
            try writePlantsCSV(
                plants: plantsForExport,
                nameMap: nameMap,
                metadata: metadata,
                to: plantsURL,
                processedUnits: &processedUnits,
                totalUnits: totalUnits,
                progressHandler: progressHandler
            )
            try writeEventsCSV(
                events: eventsForExport,
                plants: plantsForExport,
                nameMap: nameMap,
                metadata: metadata,
                to: eventsURL,
                processedUnits: &processedUnits,
                totalUnits: totalUnits,
                progressHandler: progressHandler
            )
        case .json:
            let jsonURL = workingDirectory.appendingPathComponent("data.json")
            try writeJSONExport(
                plants: plantsForExport,
                events: eventsForExport,
                nameMap: nameMap,
                metadata: metadata,
                to: jsonURL
            )
            // Consider all work done for JSON after writing file
            processedUnits = totalUnits
            reportProgress()
        }

        // README is shared between formats
        let readmeURL = workingDirectory.appendingPathComponent("README.txt")
        try writeReadme(to: readmeURL)

        // Package into a ZIP archive if supported; otherwise return directory URL.
        let zipURL = tempRoot.appendingPathComponent("GroBroExport-\(exportId).zip")
        if fileManager.fileExists(atPath: zipURL.path) {
            try fileManager.removeItem(at: zipURL)
        }

        // Create ZIP archive using system zip command (macOS only)
        #if os(macOS)
        do {
            try Self.createZipArchive(from: workingDirectory, to: zipURL)
            progressHandler?(1.0)
            return zipURL
        } catch {
            // If zipping fails, return the directory
            progressHandler?(1.0)
            return workingDirectory
        }
        #else
        // On iOS, Process is not available - return directory instead
        progressHandler?(1.0)
        return workingDirectory
        #endif
    }

    // MARK: - Filtering & Anonymization

    private static func applyDateFilter(
        events: [Event],
        range: ClosedRange<Date>?
    ) -> [Event] {
        guard let range else { return events }
        return events.filter { range.contains($0.timestamp) }
    }

    /// Returns anonymized plants/events if requested, along with a mapping of original IDs to names.
    private static func prepareAnonymizedData(
        plants: [Plant],
        events: [Event],
        anonymize: Bool
    ) -> ([Plant], [Event], [UUID: String]) {
        guard anonymize else {
            // Map of real names for convenience when building events.csv
            let nameMap = Dictionary(uniqueKeysWithValues: plants.map { ($0.id, $0.name) })
            return (plants, events, nameMap)
        }

        // Build deterministic ordering so anonymized names are stable
        let sortedPlants = plants.sorted { $0.createdAt < $1.createdAt }

        var anonymizedPlants: [Plant] = []
        var nameMap: [UUID: String] = [:]

        for (index, plant) in sortedPlants.enumerated() {
            let anonymizedName = "Plant \(index + 1)"
            var copy = plant
            copy.name = anonymizedName
            anonymizedPlants.append(copy)
            nameMap[plant.id] = anonymizedName
        }

        return (anonymizedPlants, events, nameMap)
    }

    // MARK: - CSV Generation

    private static func writePlantsCSV(
        plants: [Plant],
        nameMap: [UUID: String],
        metadata: ExportMetadata,
        to url: URL,
        processedUnits: inout Int,
        totalUnits: Int,
        progressHandler: (@Sendable (Double) -> Void)?
    ) throws {
        var lines: [String] = []
        lines.append("plant_id,name,strain,created_date,stage,substrate_type,pot_size_liters,status")

        let dateFormatter = iso8601Formatter(timeZone: metadata.timeZoneIdentifier)

        for plant in plants {
            processedUnits += 1
            if totalUnits > 0 {
                let progress = Double(processedUnits) / Double(totalUnits)
                progressHandler?(min(max(progress, 0), 1))
            }

            let id = plant.id.uuidString
            let name = nameMap[plant.id] ?? plant.name
            let strain = plant.strainName ?? ""
            let createdDate = dateFormatter.string(from: plant.createdAt)
            let stage = plant.stage.rawValue
            let substrate = plant.substrateType?.rawValue ?? ""
            let potSize = plant.potSizeLiters.map { String($0) } ?? ""
            let status = plant.isArchived ? "archived" : "active"

            let row = [
                id,
                name,
                strain,
                createdDate,
                stage,
                substrate,
                potSize,
                status
            ]
            .map(csvEscaped)
            .joined(separator: ",")

            lines.append(row)
        }

        let contents = lines.joined(separator: "\n")
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func writeEventsCSV(
        events: [Event],
        plants: [Plant],
        nameMap: [UUID: String],
        metadata: ExportMetadata,
        to url: URL,
        processedUnits: inout Int,
        totalUnits: Int,
        progressHandler: (@Sendable (Double) -> Void)?
    ) throws {
        var lines: [String] = []
        lines.append("event_id,plant_name,event_type,source,timestamp,notes,water_volume_ml,stress_tags,photo_filename,temperature_f,humidity_percent,vpd_kpa,ppfd,lux,dli,light_type,distance_meters")

        let dateFormatter = iso8601Formatter(timeZone: metadata.timeZoneIdentifier)
        let plantLookup = Dictionary(uniqueKeysWithValues: plants.map { ($0.id, $0) })

        for event in events {
            processedUnits += 1
            if totalUnits > 0 {
                let progress = Double(processedUnits) / Double(totalUnits)
                progressHandler?(min(max(progress, 0), 1))
            }

            let plantName = nameMap[event.plantId]
                ?? plantLookup[event.plantId]?.name
                ?? "Unknown Plant"

            let id = event.id.uuidString
            let type = event.type.rawValue
            let source = event.source.rawValue
            let timestamp = dateFormatter.string(from: event.timestamp)
            let notes = event.noteText ?? ""

            // Convert liters to milliliters for export
            let volumeML: String = if let liters = event.volumeLiters {
                String(Int(liters * 1000))
            } else {
                ""
            }

            let stressTags = event.stressTags.map { $0.rawValue }.joined(separator: ";")
            let photoFilename = event.photoAssetId ?? ""

            let temperatureF: String = {
                if let env = event.environmentalData,
                   let temp = env.temperatureFahrenheit {
                    return String(format: "%.1f", temp)
                }
                return ""
            }()

            let humidityPercent: String = {
                if let env = event.environmentalData,
                   let humidity = env.humidityPercent {
                    return String(format: "%.1f", humidity)
                }
                return ""
            }()

            let vpdKPa: String = {
                if let env = event.environmentalData,
                   let vpd = env.vpdKilopascal {
                    return String(format: "%.2f", vpd)
                }
                return ""
            }()

            let ppfd: String = {
                if let light = event.lightMeasurement,
                   let value = light.ppfd {
                    return String(format: "%.0f", value)
                }
                return ""
            }()

            let lux: String = {
                if let light = event.lightMeasurement,
                   let value = light.lux {
                    return String(format: "%.0f", value)
                }
                return ""
            }()

            let dli: String = {
                if let light = event.lightMeasurement,
                   let value = light.dli {
                    return String(format: "%.2f", value)
                }
                return ""
            }()

            let lightType = event.lightMeasurement?.lightTypeIdentifier ?? ""

            let distanceMeters: String = {
                if let light = event.lightMeasurement,
                   let value = light.distanceMeters {
                    return String(format: "%.2f", value)
                }
                return ""
            }()

            let row = [
                id,
                plantName,
                type,
                source,
                timestamp,
                notes,
                volumeML,
                stressTags,
                photoFilename,
                temperatureF,
                humidityPercent,
                vpdKPa,
                ppfd,
                lux,
                dli,
                lightType,
                distanceMeters
            ]
            .map(csvEscaped)
            .joined(separator: ",")

            lines.append(row)
        }

        let contents = lines.joined(separator: "\n")
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.isEmpty {
            return ""
        }

        var needsQuotes = false
        var escaped = ""
        for character in value {
            if character == "\"" {
                escaped.append("\"\"")
                needsQuotes = true
            } else {
                if character == "," || character == "\n" || character == "\r" {
                    needsQuotes = true
                }
                escaped.append(character)
            }
        }

        if needsQuotes {
            return "\"\(escaped)\""
        } else {
            return escaped
        }
    }

    private static func iso8601Formatter(timeZone: String) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: timeZone) ?? .current
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        return formatter
    }

    // MARK: - JSON Generation

    private struct ExportMetadata: Sendable {
        let exportDate: Date
        let appVersion: String
        let timeZoneIdentifier: String
    }

    private struct JSONExportMetadata: Codable {
        let exportDate: String
        let appVersion: String
        let timezone: String

        enum CodingKeys: String, CodingKey {
            case exportDate = "export_date"
            case appVersion = "app_version"
            case timezone
        }
    }

    private struct JSONExportEvent: Codable {
        let id: UUID
        let plantId: UUID
        let type: String
        let timestamp: Date
        let note: String?
        let volumeLiters: Double?
        let stressTags: [String]
        let photoAssetId: String?
        let source: String
        let temperatureFahrenheit: Double?
        let humidityPercent: Double?
        let vpdKilopascal: Double?
        let ppfd: Double?
        let lux: Double?
        let dli: Double?
        let lightTypeIdentifier: String?
        let distanceMeters: Double?

        enum CodingKeys: String, CodingKey {
            case id
            case plantId = "plant_id"
            case type
            case timestamp
            case note
            case volumeLiters = "volume_liters"
            case stressTags = "stress_tags"
            case photoAssetId = "photo_asset_id"
            case source
            case temperatureFahrenheit = "temperature_fahrenheit"
            case humidityPercent = "humidity_percent"
            case vpdKilopascal = "vpd_kpa"
            case ppfd
            case lux
            case dli
            case lightTypeIdentifier = "light_type"
            case distanceMeters = "distance_meters"
        }
    }

    private struct JSONExportPlant: Codable {
        let id: UUID
        let name: String
        let strainName: String?
        let createdDate: Date
        let stage: String
        let substrateType: String?
        let potSizeLiters: Double?
        let status: String
        let events: [JSONExportEvent]

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case strainName = "strain"
            case createdDate = "created_date"
            case stage
            case substrateType = "substrate_type"
            case potSizeLiters = "pot_size_liters"
            case status
            case events
        }
    }

    private struct JSONExportPayload: Codable {
        let metadata: JSONExportMetadata
        let plants: [JSONExportPlant]

        enum CodingKeys: String, CodingKey {
            case metadata = "export_metadata"
            case plants
        }
    }

    private static func writeJSONExport(
        plants: [Plant],
        events: [Event],
        nameMap: [UUID: String],
        metadata: ExportMetadata,
        to url: URL
    ) throws {
        // Group events by plant
        let eventsByPlantId = Dictionary(grouping: events) { $0.plantId }

        let jsonPlants: [JSONExportPlant] = plants.map { plant in
            let plantEvents = eventsByPlantId[plant.id] ?? []

            let jsonEvents: [JSONExportEvent] = plantEvents.map { event in
                JSONExportEvent(
                    id: event.id,
                    plantId: event.plantId,
                    type: event.type.rawValue,
                    timestamp: event.timestamp,
                    note: event.noteText,
                    volumeLiters: event.volumeLiters,
                    stressTags: event.stressTags.map { $0.rawValue },
                    photoAssetId: event.photoAssetId,
                    source: event.source.rawValue,
                    temperatureFahrenheit: event.environmentalData?.temperatureFahrenheit,
                    humidityPercent: event.environmentalData?.humidityPercent,
                    vpdKilopascal: event.environmentalData?.vpdKilopascal,
                    ppfd: event.lightMeasurement?.ppfd,
                    lux: event.lightMeasurement?.lux,
                    dli: event.lightMeasurement?.dli,
                    lightTypeIdentifier: event.lightMeasurement?.lightTypeIdentifier,
                    distanceMeters: event.lightMeasurement?.distanceMeters
                )
            }

            return JSONExportPlant(
                id: plant.id,
                name: nameMap[plant.id] ?? plant.name,
                strainName: plant.strainName,
                createdDate: plant.createdAt,
                stage: plant.stage.rawValue,
                substrateType: plant.substrateType?.rawValue,
                potSizeLiters: plant.potSizeLiters,
                status: plant.isArchived ? "archived" : "active",
                events: jsonEvents
            )
        }

        let dateFormatter = iso8601Formatter(timeZone: metadata.timeZoneIdentifier)

        let jsonMetadata = JSONExportMetadata(
            exportDate: dateFormatter.string(from: metadata.exportDate),
            appVersion: metadata.appVersion,
            timezone: metadata.timeZoneIdentifier
        )

        let payload = JSONExportPayload(
            metadata: jsonMetadata,
            plants: jsonPlants
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(payload)
        try data.write(to: url)
    }

    // MARK: - README

    private static func writeReadme(to url: URL) throws {
        let contents = """
        GroBro Data Export
        ==================

        This export contains your GroBro plant and diary data.

        Files:
        - plants.csv: Basic information for each plant
        - events.csv: Diary events linked to plants
        - data.json: Combined JSON export (when JSON format is selected)

        plants.csv columns:
        - plant_id
        - name
        - strain
        - created_date (ISO 8601)
        - stage
        - substrate_type
        - pot_size_liters
        - status (active/archived)

        events.csv columns:
        - event_id
        - plant_name
        - event_type
        - source
        - timestamp (ISO 8601)
        - notes
        - water_volume_ml
        - stress_tags (semicolon-separated)
        - photo_filename
        - temperature_f
        - humidity_percent
        - vpd_kpa
        - ppfd
        - lux
        - dli
        - light_type
        - distance_meters

        JSON structure (data.json):
        {
          "export_metadata": {
            "export_date": "<ISO 8601 timestamp>",
            "app_version": "<app version>",
            "timezone": "<system timezone identifier>"
          },
          "plants": [
            {
              "id": "<UUID>",
              "name": "<plant name>",
              "strain": "<optional strain>",
              "created_date": "<ISO 8601 date>",
              "stage": "<stage>",
              "substrate_type": "<substrate>",
              "pot_size_liters": <number>,
              "status": "active|archived",
                  "events": [
                {
                  "id": "<UUID>",
                  "plant_id": "<UUID>",
                  "type": "<event type>",
                  "timestamp": "<ISO 8601 timestamp>",
                  "note": "<optional note>",
                  "volume_liters": <number|null>,
                  "stress_tags": ["tag1", "tag2"],
                  "photo_asset_id": "<optional asset id>",
                  "source": "<manual|acinfinity|lightMeter|other>",
                  "temperature_fahrenheit": <number|null>,
                  "humidity_percent": <number|null>,
                  "vpd_kpa": <number|null>,
                  "ppfd": <number|null>,
                  "lux": <number|null>,
                  "dli": <number|null>,
                  "light_type": "<light type identifier>",
                  "distance_meters": <number|null>
                }
              ]
            }
          ]
        }

        Privacy:
        - No GPS coordinates, device IDs, or account identifiers are included.
        - Plant names and notes are user-provided content.
        - If you enable anonymization, plant names are replaced with "Plant 1", "Plant 2", etc.
        """

        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    #if os(macOS)
    /// Creates a ZIP archive from a directory using the system zip command.
    /// Note: Only available on macOS - Process is not available on iOS.
    private static func createZipArchive(from sourceURL: URL, to destinationURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = [
            "-r",  // recursive
            "-q",  // quiet mode
            destinationURL.path,
            "."
        ]
        process.currentDirectoryURL = sourceURL

        let pipe = Pipe()
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "DataExportService",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Failed to create ZIP archive: \(errorMessage)"]
            )
        }
    }
    #endif
}
