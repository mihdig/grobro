import WidgetKit
import SwiftUI

@main
struct GroBroWidgetsBundle: WidgetBundle {
    var body: some Widget {
        GardenStatusWidget()
        LockScreenStatusWidget()
#if canImport(ActivityKit)
        WateringCountdownLiveActivityWidget()
#endif
    }
}
