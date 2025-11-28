import WidgetKit
import SwiftUI
import GroBroDomain

struct GardenWidgetTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GardenWidgetEntry {
        .placeholder
    }

    func snapshot(
        for configuration: GardenWidgetConfigurationIntent,
        in context: Context
    ) async -> GardenWidgetEntry {
        WidgetDataSource.makeEntry(for: configuration)
    }

    func timeline(
        for configuration: GardenWidgetConfigurationIntent,
        in context: Context
    ) async -> Timeline<GardenWidgetEntry> {
        let start = WidgetDataSource.makeEntry(for: configuration)
        let interval: TimeInterval = 15 * 60
        var entries: [GardenWidgetEntry] = [start]

        for step in 1...4 {
            let nextDate = start.date.addingTimeInterval(interval * Double(step))
            entries.append(WidgetDataSource.makeEntry(for: configuration, date: nextDate))
        }

        return Timeline(entries: entries, policy: .after(entries.last?.date ?? Date().addingTimeInterval(interval)))
    }
}

struct GardenStatusWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "com.grobro.widgets.garden", intent: GardenWidgetConfigurationIntent.self, provider: GardenWidgetTimelineProvider()) { entry in
            GardenWidgetView(entry: entry)
                .containerBackground(.thinMaterial, for: .widget)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Garden Status")
        .description("Keep an eye on watering schedules, badges, and Smart Greenhouse actions.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct GardenWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GardenWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            fallbackView
        }
    }

    private var smallView: some View {
        let plant = entry.selectedPlants.first ?? entry.snapshot.plants.first
        return Group {
            if let plant {
                PlantTileView(plant: plant, emphasizeCountdown: true)
                    .widgetURL(DeepLinkDestination.plantDetail(id: plant.id, tab: .overview).url)
            } else {
                fallbackView
            }
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HeaderView(title: "Next Waterings", lastUpdated: entry.snapshot.generatedAt)
            if entry.selectedPlants.isEmpty {
                EmptyWidgetStateView()
            } else {
                HStack(spacing: 8) {
                    ForEach(Array(entry.selectedPlants.prefix(3)), id: \.id) { plant in
                        PlantBadgeView(plant: plant)
                            .widgetURL(DeepLinkDestination.plantDetail(id: plant.id, tab: .overview).url)
                    }
                }
            }
        }
        .padding()
    }

    private var largeView: some View {
        VStack(spacing: 12) {
            HeaderView(title: "Smart Greenhouse", lastUpdated: entry.snapshot.generatedAt)

            if entry.selectedPlants.isEmpty {
                EmptyWidgetStateView()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    ForEach(Array(entry.selectedPlants.prefix(4)), id: \.id) { plant in
                        PlantTileView(plant: plant, emphasizeCountdown: false)
                            .widgetURL(DeepLinkDestination.plantDetail(id: plant.id, tab: .overview).url)
                    }
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.2))

            QuickActionsRow(primaryPlant: entry.selectedPlants.first)
        }
        .padding()
    }

    private var fallbackView: some View {
        EmptyWidgetStateView()
            .padding()
    }
}

private struct HeaderView: View {
    let title: String
    let lastUpdated: Date

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Text(lastUpdated, style: .time)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

private struct PlantTileView: View {
    let plant: WidgetPlantSnapshot
    var emphasizeCountdown: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(plant.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                BadgeStackView(badges: plant.badges)
            }

            Text(plant.stage.displayName)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text(plant.statusMessage)
                .font(emphasizeCountdown ? .title3 : .callout)
                .fontWeight(.semibold)
                .foregroundColor(plant.isOverdue ? .red : .greenhouseAccent)

            if let environment = plant.environment {
                EnvironmentSummaryView(summary: environment)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.35))
        )
    }
}

private struct PlantBadgeView: View {
    let plant: WidgetPlantSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(plant.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                BadgeStackView(badges: plant.badges)
            }
            Text(plant.countdownText)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            if let message = plant.environment?.statusTitle {
                Text(message)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            } else {
                Text(plant.statusMessage)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.35))
        )
    }
}

private struct BadgeStackView: View {
    let badges: [WidgetPlantSnapshot.StatusBadge]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(badges.prefix(2), id: \.self) { badge in
                Image(systemName: badge.systemImageName)
                    .font(.caption2)
                    .foregroundColor(color(for: badge))
            }
        }
    }

    private func color(for badge: WidgetPlantSnapshot.StatusBadge) -> Color {
        switch badge {
        case .overdue: return .red
        case .dueSoon: return .orange
        case .offline: return .yellow
        case .pro: return .purple
        case .empty: return .white.opacity(0.6)
        }
    }
}

private struct EnvironmentSummaryView: View {
    let summary: WidgetPlantSnapshot.EnvironmentalSummary

    var body: some View {
        HStack(spacing: 6) {
            Label {
                Text(summary.statusTitle)
                    .font(.caption2)
            } icon: {
                Image(systemName: "antenna.radiowaves.left.and.right")
            }
                .foregroundColor(summary.statusColor)

            Spacer()

            Text(String(format: "%.0f°", summary.temperature))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            Text(String(format: "%.0f%%", summary.humidity))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

private struct QuickActionsRow: View {
    let primaryPlant: WidgetPlantSnapshot?

    var body: some View {
        HStack(spacing: 12) {
            if let primaryPlant {
                let entity = WidgetPlantEntity(
                    id: primaryPlant.id,
                    name: primaryPlant.name,
                    stage: primaryPlant.stage.displayName,
                    status: primaryPlant.statusMessage
                )
                var intent = OpenPlantDetailIntent()
                let _ = intent.$plant.wrappedValue = entity

                Button(intent: intent) {
                    Label("Open Detail", systemImage: "leaf")
                }
                .buttonStyle(.borderedProminent)
                .tint(.greenhouseAccent)
            }

            let wateringIntent = {
                var intent = OpenWateringIntent()
                if let plant = primaryPlant {
                    let entity = WidgetPlantEntity(
                        id: plant.id,
                        name: plant.name,
                        stage: plant.stage.displayName,
                        status: plant.statusMessage
                    )
                    intent.$plant.wrappedValue = entity
                }
                return intent
            }()

            Button(intent: wateringIntent) {
                Label("Log Water", systemImage: "drop.fill")
            }
            .buttonStyle(.bordered)
            .tint(.white.opacity(0.5))
        }
        .labelStyle(.iconOnly)
    }
}

private struct EmptyWidgetStateView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No active plants")
                .font(.headline)
                .foregroundColor(.white)
            Text("Open GroBro to add your first plant and power Smart Greenhouse widgets.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

private extension WidgetPlantSnapshot.EnvironmentalSummary {
    var statusTitle: String {
        switch status {
        case .optimal: return "Optimal"
        case .caution: return "Caution"
        case .critical: return "Critical"
        case .offline: return "Offline"
        }
    }

    var statusColor: Color {
        switch status {
        case .optimal: return .greenhouseAccent
        case .caution: return .yellow
        case .critical: return .red
        case .offline: return .gray
        }
    }
}
