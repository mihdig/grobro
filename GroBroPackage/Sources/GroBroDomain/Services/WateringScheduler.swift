import Foundation

/// Feedback from the user about the timing of a watering event
public enum WateringFeedback: String, Sendable, CaseIterable {
    case tooEarly
    case justRight
    case tooLate
}

/// Represents the watering status for a plant
public struct WateringStatus: Sendable {
    public let nextWateringDate: Date
    public let daysUntilWatering: Int
    public let isOverdue: Bool

    public init(nextWateringDate: Date, daysUntilWatering: Int, isOverdue: Bool) {
        self.nextWateringDate = nextWateringDate
        self.daysUntilWatering = daysUntilWatering
        self.isOverdue = isOverdue
    }

    /// User-friendly status message
    public var statusMessage: String {
        if isOverdue {
            let days = abs(daysUntilWatering)
            return days == 1 ? "Water overdue by 1 day" : "Water overdue by \(days) days"
        } else {
            return daysUntilWatering == 0 ? "Water today" :
                   daysUntilWatering == 1 ? "Water in 1 day" :
                   "Water in \(daysUntilWatering) days"
        }
    }
}

/// Service responsible for computing watering schedules and adapting them based on user feedback
@MainActor
public final class WateringScheduler: Sendable {

    // MARK: - Default Interval Ranges

    /// Default watering intervals (in days) based on stage and substrate
    /// These are starting points that adapt over time with user feedback
    private static let defaultIntervals: [PlantStage: [SubstrateType: (min: Int, default: Int, max: Int)]] = [
        .seedling: [
            .soil: (min: 1, default: 2, max: 4),
            .coco: (min: 1, default: 1, max: 3),
            .hydro: (min: 0, default: 0, max: 1), // Daily checks for hydro
            .soilless: (min: 1, default: 2, max: 4),
            .other: (min: 1, default: 2, max: 4)
        ],
        .vegetative: [
            .soil: (min: 2, default: 3, max: 7),
            .coco: (min: 1, default: 2, max: 4),
            .hydro: (min: 0, default: 0, max: 1),
            .soilless: (min: 2, default: 3, max: 6),
            .other: (min: 2, default: 3, max: 6)
        ],
        .flowering: [
            .soil: (min: 2, default: 3, max: 6),
            .coco: (min: 1, default: 2, max: 4),
            .hydro: (min: 0, default: 0, max: 1),
            .soilless: (min: 2, default: 3, max: 5),
            .other: (min: 2, default: 3, max: 5)
        ]
    ]

    /// Adjustment factor for pot size
    /// Larger pots retain moisture longer, smaller pots dry out faster
    private static func potSizeAdjustmentDays(potSizeLiters: Double?) -> Double {
        guard let size = potSizeLiters else { return 0.0 }

        switch size {
        case 0..<5: return -1.0  // Very small pots dry faster
        case 5..<10: return -0.5 // Small pots
        case 10..<20: return 0.0 // Medium pots (baseline)
        case 20..<40: return 0.5 // Large pots
        default: return 1.0      // Very large pots retain more moisture
        }
    }

    // MARK: - Interval Calculation

    /// Computes the suggested watering interval for a plant based on its current characteristics
    /// - Parameters:
    ///   - plant: The plant to compute the interval for
    ///   - currentIntervalDays: Optional current interval from previous calculations
    /// - Returns: Suggested watering interval in days
    public static func computeSuggestedInterval(
        for plant: Plant,
        currentIntervalDays: Int? = nil
    ) -> Int {
        // If we have a current interval, use it as the baseline
        if let current = currentIntervalDays {
            // Validate it's within safe bounds for the plant's stage/substrate
            let bounds = getBounds(for: plant)
            return max(bounds.min, min(bounds.max, current))
        }

        // Otherwise, compute from defaults
        let bounds = getBounds(for: plant)
        var interval = Double(bounds.default)

        // Adjust for pot size
        interval += potSizeAdjustmentDays(potSizeLiters: plant.potSizeLiters)

        // Keep within safe bounds
        return max(bounds.min, min(bounds.max, Int(interval.rounded())))
    }

    /// Adjusts the watering interval based on user feedback
    /// - Parameters:
    ///   - currentIntervalDays: The current interval
    ///   - feedback: User feedback about the last watering timing
    ///   - plant: The plant being adjusted
    /// - Returns: New adjusted interval in days
    public static func adjustInterval(
        currentIntervalDays: Int,
        feedback: WateringFeedback,
        for plant: Plant
    ) -> Int {
        let bounds = getBounds(for: plant)
        var newInterval = currentIntervalDays

        switch feedback {
        case .tooEarly:
            // User watered too soon, increase interval by 1 day
            newInterval += 1
        case .justRight:
            // Perfect timing, no change
            break
        case .tooLate:
            // User waited too long, decrease interval by 1 day
            newInterval -= 1
        }

        // Enforce bounds
        return max(bounds.min, min(bounds.max, newInterval))
    }

    /// Computes the next watering date based on the last watering event
    /// - Parameters:
    ///   - lastWateringDate: Date of the last watering
    ///   - intervalDays: Watering interval in days
    /// - Returns: Date when the next watering is due
    public static func computeNextWateringDate(
        lastWateringDate: Date,
        intervalDays: Int
    ) -> Date {
        Calendar.current.date(byAdding: .day, value: intervalDays, to: lastWateringDate) ?? lastWateringDate
    }

    /// Computes the watering status for a plant
    /// - Parameters:
    ///   - nextWateringDate: The computed next watering date
    ///   - now: Current date (defaults to now, injectable for testing)
    /// - Returns: WateringStatus with user-friendly information
    public static func computeWateringStatus(
        nextWateringDate: Date,
        now: Date = Date()
    ) -> WateringStatus {
        let daysUntil = Calendar.current.dateComponents([.day], from: now, to: nextWateringDate).day ?? 0
        let isOverdue = daysUntil < 0

        return WateringStatus(
            nextWateringDate: nextWateringDate,
            daysUntilWatering: daysUntil,
            isOverdue: isOverdue
        )
    }

    // MARK: - Private Helpers

    private static func getBounds(for plant: Plant) -> (min: Int, default: Int, max: Int) {
        let substrate = plant.substrateType ?? .other
        return defaultIntervals[plant.stage]?[substrate] ?? (min: 2, default: 3, max: 7)
    }
}
