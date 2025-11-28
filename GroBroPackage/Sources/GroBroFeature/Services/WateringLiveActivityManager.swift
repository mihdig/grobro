#if canImport(ActivityKit) && os(iOS)
import ActivityKit
import Foundation
import GroBroDomain

@available(iOS 17.0, *)
@MainActor
public final class WateringLiveActivityManager {
    public init() {}

    public func synchronize(with plants: [WidgetPlantSnapshot]) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard let candidate = plants
            .compactMap({ snapshot -> (WidgetPlantSnapshot, Date)? in
                guard let date = snapshot.nextWateringDate else { return nil }
                return (snapshot, date)
            })
            .sorted(by: { $0.1 < $1.1 })
            .first else {
            Task { await endAllActivities() }
            return
        }

        let snapshot = candidate.0
        let nextDate = candidate.1

        if let existing = Activity<WateringCountdownAttributes>.activities.first(where: { $0.attributes.plantID == snapshot.id }) {
            Task {
                let content = ActivityContent(
                    state: WateringCountdownAttributes.ContentState(plantID: snapshot.id, plantName: snapshot.name, nextWateringDate: nextDate),
                    staleDate: nextDate
                )
                await existing.update(content)
            }
        } else {
            Task {
                await endAllActivities()
                let attributes = WateringCountdownAttributes(plantID: snapshot.id, plantName: snapshot.name)
                let content = ActivityContent(
                    state: WateringCountdownAttributes.ContentState(plantID: snapshot.id, plantName: snapshot.name, nextWateringDate: nextDate),
                    staleDate: nextDate
                )
                try? Activity.request(attributes: attributes, content: content)
            }
        }
    }

    public func endAllActivities() async {
        for activity in Activity<WateringCountdownAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
#endif
