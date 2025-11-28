#if canImport(ActivityKit) && os(iOS)
import ActivityKit
import Foundation

@available(iOS 17.0, *)
public struct WateringCountdownAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var plantID: UUID
        public var plantName: String
        public var nextWateringDate: Date

        public var countdownText: String {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute]
            formatter.unitsStyle = .abbreviated
            return formatter.string(from: Date(), to: nextWateringDate) ?? "Soon"
        }

        public var compactCountdown: String {
            let interval = nextWateringDate.timeIntervalSinceNow
            if interval <= 0 {
                return "Now"
            } else if interval < 3_600 {
                return "\(max(1, Int(interval / 60)))m"
            } else {
                return "\(Int(interval / 3_600))h"
            }
        }

        public init(plantID: UUID, plantName: String, nextWateringDate: Date) {
            self.plantID = plantID
            self.plantName = plantName
            self.nextWateringDate = nextWateringDate
        }
    }

    public let plantID: UUID
    public let plantName: String

    public init(plantID: UUID, plantName: String) {
        self.plantID = plantID
        self.plantName = plantName
    }
}
#endif
