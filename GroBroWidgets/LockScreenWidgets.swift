import WidgetKit
import SwiftUI
import GroBroDomain
#if canImport(ActivityKit)
import ActivityKit
#endif

struct LockScreenEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetGardenSnapshot
    let plant: WidgetPlantSnapshot?
    let configuration: LockScreenWidgetConfigurationIntent
}

struct LockScreenTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LockScreenEntry {
        LockScreenEntry(
            date: Date(),
            snapshot: .placeholder,
            plant: .placeholder,
            configuration: LockScreenWidgetConfigurationIntent()
        )
    }

    func snapshot(for configuration: LockScreenWidgetConfigurationIntent, in context: Context) async -> LockScreenEntry {
        makeEntry(configuration: configuration, date: Date())
    }

    func timeline(for configuration: LockScreenWidgetConfigurationIntent, in context: Context) async -> Timeline<LockScreenEntry> {
        let start = makeEntry(configuration: configuration, date: Date())
        let next = start.date.addingTimeInterval(15 * 60)
        return Timeline(entries: [start], policy: .after(next))
    }

    private func makeEntry(configuration: LockScreenWidgetConfigurationIntent, date: Date) -> LockScreenEntry {
        let snapshot = WidgetSnapshotStore.shared.latestSnapshot() ?? .placeholder
        let plant = selectPlant(configuration: configuration, snapshot: snapshot)
        let record = WidgetConfigurationRecord(
            widgetID: configuration.configurationIdentifier,
            family: .lockScreen,
            plantIDs: plant.map { [$0.id] } ?? [],
            preferredPlantCount: plant == nil ? 0 : 1
        )
        WidgetSnapshotStore.shared.save(configuration: record)
        return LockScreenEntry(date: date, snapshot: snapshot, plant: plant, configuration: configuration)
    }

    private func selectPlant(configuration: LockScreenWidgetConfigurationIntent, snapshot: WidgetGardenSnapshot) -> WidgetPlantSnapshot? {
        if let selectedID = configuration.plant?.id {
            return snapshot.plants.first(where: { $0.id == selectedID }) ?? snapshot.plants.first
        }
        return snapshot.plants.sorted(by: { ($0.nextWateringDate ?? .distantFuture) < ($1.nextWateringDate ?? .distantFuture) }).first
    }
}

struct LockScreenStatusWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "com.grobro.widgets.lockScreen", intent: LockScreenWidgetConfigurationIntent.self, provider: LockScreenTimelineProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Lock Screen Countdown")
        .description("See the next watering countdown directly on your lock screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

private struct LockScreenWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LockScreenEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            EmptyView()
        }
    }

    private var circularView: some View {
        ZStack {
            if let plant = entry.plant, let next = plant.nextWateringDate {
                ProgressView(timerInterval: Date()...next, countsDown: true)
                    .tint(plant.isOverdue ? .red : .greenhouseAccent)
                Text(shortCountdown(for: next))
                    .font(.caption2)
            } else {
                Image(systemName: "leaf")
                    .foregroundColor(.greenhouseAccent)
            }
        }
        .widgetURL(destination(for: entry.plant))
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let plant = entry.plant {
                Text(plant.name)
                    .font(.headline)
                Text(plant.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("No plants")
                    .font(.headline)
                Text("Add a plant in GroBro")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .widgetURL(destination(for: entry.plant))
    }

    private var inlineView: some View {
        HStack {
            if let plant = entry.plant {
                Text("🌱 \(plant.name.prefix(4))")
                Text(plant.countdownText)
            } else {
                Text("🌱 Add plant")
            }
        }
        .widgetURL(destination(for: entry.plant))
    }

    private func shortCountdown(for date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval <= 0 {
            return "Now"
        } else if interval < 3_600 {
            return "\(max(1, Int(interval / 60)))m"
        } else if interval < 86_400 {
            return "\(Int(interval / 3_600))h"
        } else {
            return "\(Int(interval / 86_400))d"
        }
    }

    private func destination(for plant: WidgetPlantSnapshot?) -> URL? {
        if let plant {
            return DeepLinkDestination.watering(plantID: plant.id).url
        } else {
            return DeepLinkDestination.createPlant.url
        }
    }
}

#if canImport(ActivityKit)
struct WateringCountdownLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WateringCountdownAttributes.self) { context in
            LiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.plantName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.countdownText)
                        .font(.title2)
                        .bold()
                }
            } compactLeading: {
                Text("💧")
            } compactTrailing: {
                Text(context.state.compactCountdown)
            } minimal: {
                Text(context.state.compactCountdown)
            }
        }
    }
}

private struct LiveActivityView: View {
    let context: ActivityViewContext<WateringCountdownAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(context.attributes.plantName)
                    .font(.headline)
                Text("Water in \(context.state.countdownText)")
                    .font(.subheadline)
            }
            Spacer()
            Text(context.state.compactCountdown)
                .font(.title2)
                .bold()
        }
        .padding()
    }
}
#endif
