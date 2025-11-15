import Foundation

/// Service responsible for managing watering states and computing schedules
@available(iOS 17.0, macOS 14.0, *)
@MainActor
public final class WateringService: ObservableObject {

    private let eventStore: EventStore
    private let notificationService: NotificationService?
    private var wateringStates: [UUID: WateringState] = [:]

    public init(
        eventStore: EventStore,
        notificationService: NotificationService? = nil
    ) {
        self.eventStore = eventStore
        self.notificationService = notificationService
    }

    /// Gets or computes the watering state for a plant
    /// - Parameter plant: The plant to get watering state for
    /// - Returns: WateringState with current schedule information
    public func getWateringState(for plant: Plant) throws -> WateringState {
        // Check if we have cached state
        if let cached = wateringStates[plant.id] {
            return cached
        }

        // Otherwise, compute from events
        let wateringEvents = try eventStore.fetchEvents(
            for: plant.id,
            types: [.watering]
        )

        let lastWatering = wateringEvents.first // Already sorted by timestamp descending
        let intervalDays = WateringScheduler.computeSuggestedInterval(for: plant)

        let nextWateringDate: Date? = if let lastDate = lastWatering?.timestamp {
            WateringScheduler.computeNextWateringDate(
                lastWateringDate: lastDate,
                intervalDays: intervalDays
            )
        } else {
            nil
        }

        let state = WateringState(
            plantId: plant.id,
            intervalDays: intervalDays,
            lastWateringDate: lastWatering?.timestamp,
            nextWateringDate: nextWateringDate
        )

        wateringStates[plant.id] = state
        return state
    }

    /// Updates watering state after a watering event is logged
    /// - Parameters:
    ///   - plant: The plant that was watered
    ///   - wateringDate: Date of the watering
    public func recordWatering(for plant: Plant, wateringDate: Date) {
        let intervalDays = wateringStates[plant.id]?.intervalDays
            ?? WateringScheduler.computeSuggestedInterval(for: plant)

        let nextDate = WateringScheduler.computeNextWateringDate(
            lastWateringDate: wateringDate,
            intervalDays: intervalDays
        )

        let state = WateringState(
            plantId: plant.id,
            intervalDays: intervalDays,
            lastWateringDate: wateringDate,
            nextWateringDate: nextDate
        )

        wateringStates[plant.id] = state

        // Schedule notification for next watering
        if let notification = notificationService {
            Task {
                await notification.scheduleWateringNotification(
                    for: plant,
                    wateringDate: nextDate
                )
            }
        }
    }

    /// Applies user feedback to adjust the watering interval
    /// - Parameters:
    ///   - plant: The plant to adjust
    ///   - feedback: User's feedback about timing
    public func applyFeedback(for plant: Plant, feedback: WateringFeedback) throws {
        var state = try getWateringState(for: plant)

        let newInterval = WateringScheduler.adjustInterval(
            currentIntervalDays: state.intervalDays,
            feedback: feedback,
            for: plant
        )

        state.intervalDays = newInterval

        // Recompute next watering date with new interval
        if let lastDate = state.lastWateringDate {
            state.nextWateringDate = WateringScheduler.computeNextWateringDate(
                lastWateringDate: lastDate,
                intervalDays: newInterval
            )

            // Reschedule notification with new date
            if let notification = notificationService, let nextDate = state.nextWateringDate {
                Task {
                    await notification.scheduleWateringNotification(
                        for: plant,
                        wateringDate: nextDate
                    )
                }
            }
        }

        wateringStates[plant.id] = state
    }

    /// Computes the current watering status for a plant
    /// - Parameter plant: The plant to check
    /// - Returns: WateringStatus with user-friendly information
    public func getWateringStatus(for plant: Plant) throws -> WateringStatus? {
        let state = try getWateringState(for: plant)

        guard let nextDate = state.nextWateringDate else {
            return nil
        }

        return WateringScheduler.computeWateringStatus(nextWateringDate: nextDate)
    }

    /// Clears cached state for a plant (useful after plant updates)
    /// - Parameter plantId: The plant ID to clear
    public func clearCachedState(for plantId: UUID) {
        wateringStates.removeValue(forKey: plantId)
    }

    /// Clears all cached states
    public func clearAllCachedStates() {
        wateringStates.removeAll()
    }
}
