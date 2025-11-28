import AppIntents
import GroBroDomain

enum GardenWidgetStyle: String, AppEnum {
    case auto
    case single
    case grid

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Widget Style"
    }

    static var caseDisplayRepresentations: [GardenWidgetStyle: DisplayRepresentation] = [
        .auto: "Smart",
        .single: "Single Plant",
        .grid: "Garden Grid"
    ]
}

struct GardenWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Garden Status"
    static var description = IntentDescription("Monitor upcoming watering tasks, badges, and quick actions from your home screen.")

    @Parameter(title: "Display Style")
    var style: GardenWidgetStyle?

    @Parameter(title: "Plants", requestValueDialog: IntentDialog("Which plants should appear in this widget?"))
    var plants: [WidgetPlantEntity]?

    init() {
        self.style = .auto
        self.plants = []
    }

    var configurationIdentifier: String {
        let ids = plants?.map(\.id.uuidString).joined(separator: "-") ?? "all"
        let styleValue = style?.rawValue ?? "auto"
        return "\(ids)|\(styleValue)"
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$style) for \(\.$plants)")
    }
}

struct LockScreenWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Lock Screen Watering"
    static var description = IntentDescription("Pin a countdown for your next watering directly on the lock screen.")

    @Parameter(title: "Plant")
    var plant: WidgetPlantEntity?

    init() {
        plant = nil
    }

    var configurationIdentifier: String {
        plant?.id.uuidString ?? "next"
    }

    static var parameterSummary: some ParameterSummary {
        When(\.$plant, .hasAnyValue) {
            Summary("Countdown for \(\.$plant)")
        } otherwise: {
            Summary("Countdown for next plant")
        }
    }
}

struct WidgetPlantEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Plant"
    }

    static var defaultQuery = WidgetPlantEntityQuery()

    let id: UUID
    let name: String
    let stage: String
    let status: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(stage) • \(status)"
        )
    }
}

struct WidgetPlantEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [WidgetPlantEntity] {
        let available = Self.availableEntities()
        let dictionary = Dictionary(uniqueKeysWithValues: available.map { ($0.id, $0) })
        return identifiers.compactMap { dictionary[$0] }
    }

    func suggestedEntities() async throws -> [WidgetPlantEntity] {
        Self.availableEntities()
    }

    private static func availableEntities() -> [WidgetPlantEntity] {
        let snapshot = WidgetSnapshotStore.shared.latestSnapshot() ?? .placeholder
        if snapshot.plants.isEmpty {
            return [
                WidgetPlantEntity(
                    id: WidgetPlantSnapshot.placeholder.id,
                    name: WidgetPlantSnapshot.placeholder.name,
                    stage: WidgetPlantSnapshot.placeholder.stage.displayName,
                    status: WidgetPlantSnapshot.placeholder.statusMessage
                )
            ]
        }
        return snapshot.plants.map {
            WidgetPlantEntity(
                id: $0.id,
                name: $0.name,
                stage: $0.stage.displayName,
                status: $0.statusMessage
            )
        }
    }
}

struct OpenPlantDetailIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Plant Detail"
    static var description = IntentDescription("Jump to the selected plant inside GroBro.")

    @Parameter(title: "Plant")
    var plant: WidgetPlantEntity

    func perform() async throws -> some IntentResult & OpensIntent {
        let destination = DeepLinkDestination.plantDetail(id: plant.id, tab: .overview)
        return .result(value: destination.url)
    }
}

struct OpenWateringIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Watering"

    @Parameter(title: "Plant")
    var plant: WidgetPlantEntity?

    func perform() async throws -> some IntentResult & OpensIntent {
        let destination = DeepLinkDestination.watering(plantID: plant?.id)
        return .result(value: destination.url)
    }
}
