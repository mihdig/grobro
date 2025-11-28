import Foundation
import WidgetKit
import GroBroDomain

struct GardenWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetGardenSnapshot
    let configuration: GardenWidgetConfigurationIntent
    let selectedPlants: [WidgetPlantSnapshot]

    static var placeholder: GardenWidgetEntry {
        GardenWidgetEntry(
            date: Date(),
            snapshot: .placeholder,
            configuration: GardenWidgetConfigurationIntent(),
            selectedPlants: [.placeholder]
        )
    }
}

struct WidgetDataSource {
    private static let snapshotStore = WidgetSnapshotStore.shared

    static func makeEntry(
        for configuration: GardenWidgetConfigurationIntent,
        date: Date = Date()
    ) -> GardenWidgetEntry {
        let snapshot = snapshotStore.latestSnapshot() ?? .placeholder
        let selected = resolvePlants(configuration: configuration, snapshot: snapshot)
        persistConfiguration(configuration, snapshot: snapshot, selected: selected)
        return GardenWidgetEntry(
            date: date,
            snapshot: snapshot,
            configuration: configuration,
            selectedPlants: selected
        )
    }

    static func resolvePlants(
        configuration: GardenWidgetConfigurationIntent,
        snapshot: WidgetGardenSnapshot
    ) -> [WidgetPlantSnapshot] {
        let plantIDs = configuration.plants?.map(\.id) ?? []
        var resolved: [WidgetPlantSnapshot]
        if plantIDs.isEmpty {
            resolved = snapshot.plants
        } else {
            let available = Dictionary(uniqueKeysWithValues: snapshot.plants.map { ($0.id, $0) })
            resolved = plantIDs.compactMap { available[$0] }
            if resolved.isEmpty {
                resolved = snapshot.plants
            }
        }

        switch configuration.style ?? .auto {
        case .single:
            return Array(resolved.prefix(1))
        case .grid:
            return Array(resolved.prefix(4))
        case .auto:
            return resolved
        }
    }

    private static func persistConfiguration(
        _ configuration: GardenWidgetConfigurationIntent,
        snapshot: WidgetGardenSnapshot,
        selected: [WidgetPlantSnapshot]
    ) {
        let record = WidgetConfigurationRecord(
            widgetID: configuration.configurationIdentifier,
            family: .home,
            plantIDs: selected.map(\.id),
            preferredPlantCount: selected.count
        )
        snapshotStore.save(configuration: record)
    }
}
