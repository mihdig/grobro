import Foundation

/// Persists the latest garden snapshot and per-widget configuration in the shared app group.
public final class WidgetSnapshotStore: @unchecked Sendable {
    public static let shared = WidgetSnapshotStore()

    private let snapshotKey = "com.grobro.widgets.gardenSnapshot"
    private let configurationKey = "com.grobro.widgets.configuration"
    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let queue = DispatchQueue(label: "com.grobro.widgets.snapshot", qos: .userInitiated)

    public init(
        userDefaults: UserDefaults = AppGroup.userDefaults,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.defaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder

        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Snapshots

    public func save(snapshot: WidgetGardenSnapshot) {
        queue.async {
            guard let data = try? self.encoder.encode(snapshot) else {
                return
            }
            self.defaults.set(data, forKey: self.snapshotKey)
        }
    }

    public func latestSnapshot() -> WidgetGardenSnapshot? {
        var data: Data?
        queue.sync {
            data = defaults.data(forKey: snapshotKey)
        }
        guard let data else { return nil }
        return try? decoder.decode(WidgetGardenSnapshot.self, from: data)
    }

    public func availablePlants() -> [WidgetPlantSnapshot] {
        latestSnapshot()?.plants ?? []
    }

    // MARK: - Configuration

    public func save(configuration: WidgetConfigurationRecord) {
        queue.async {
            var dictionary = self.loadConfigurationDictionary()
            dictionary[configuration.widgetID] = configuration
            self.persistConfigurationDictionary(dictionary)
        }
    }

    public func configuration(for widgetID: String) -> WidgetConfigurationRecord? {
        var configuration: WidgetConfigurationRecord?
        queue.sync {
            configuration = self.loadConfigurationDictionary()[widgetID]
        }
        return configuration
    }

    public func deleteConfiguration(for widgetID: String) {
        queue.async {
            var dictionary = self.loadConfigurationDictionary()
            dictionary.removeValue(forKey: widgetID)
            self.persistConfigurationDictionary(dictionary)
        }
    }

    public func allConfigurations() -> [WidgetConfigurationRecord] {
        var values: [WidgetConfigurationRecord] = []
        queue.sync {
            values = Array(self.loadConfigurationDictionary().values)
        }
        return values
    }

    // MARK: - Helpers

    private func loadConfigurationDictionary() -> [String: WidgetConfigurationRecord] {
        guard let data = defaults.data(forKey: configurationKey),
              let dictionary = try? decoder.decode([String: WidgetConfigurationRecord].self, from: data) else {
            return [:]
        }
        return dictionary
    }

    private func persistConfigurationDictionary(_ dictionary: [String: WidgetConfigurationRecord]) {
        guard let data = try? encoder.encode(dictionary) else {
            return
        }
        defaults.set(data, forKey: configurationKey)
    }
}
