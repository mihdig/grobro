import Foundation
import UserNotifications

/// Service responsible for managing local notifications for watering reminders
@available(iOS 17.0, macOS 14.0, *)
@MainActor
public final class NotificationService: ObservableObject {

    @Published public var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let notificationCenter: UNUserNotificationCenter

    public init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter

        Task {
            await checkAuthorizationStatus()
        }
    }

    /// Requests notification authorization from the user
    /// - Returns: true if authorized, false otherwise
    @discardableResult
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }

    /// Checks the current notification authorization status
    public func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Schedules a watering notification for a plant
    /// - Parameters:
    ///   - plant: The plant to schedule notification for
    ///   - wateringDate: The date when watering is due
    public func scheduleWateringNotification(
        for plant: Plant,
        wateringDate: Date
    ) async {
        // Check authorization first
        guard authorizationStatus == .authorized else {
            print("Notifications not authorized")
            return
        }

        // Remove any existing notification for this plant
        await cancelWateringNotification(for: plant.id)

        // Don't schedule if the date is in the past
        guard wateringDate > Date() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Time to Water"
        content.body = "\(plant.name) needs watering today"
        content.sound = .default
        content.categoryIdentifier = "WATERING_REMINDER"
        content.userInfo = ["plantId": plant.id.uuidString]

        // Schedule for the specific date at 9 AM
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: wateringDate
        )
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: plant.id),
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("Scheduled watering notification for \(plant.name) on \(wateringDate)")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    /// Cancels a watering notification for a plant
    /// - Parameter plantId: The plant ID
    public func cancelWateringNotification(for plantId: UUID) async {
        let identifier = notificationIdentifier(for: plantId)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancels all watering notifications
    public func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Gets all pending notification requests
    /// - Returns: Array of pending notification requests
    public func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    // MARK: - Private Helpers

    private func notificationIdentifier(for plantId: UUID) -> String {
        "watering-\(plantId.uuidString)"
    }
}
