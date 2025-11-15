import Foundation

/// Tracks user dismissals of Pro feature prompts to prevent spam
@MainActor
@Observable
public final class PromptDismissalTracker {

    // MARK: - Constants

    /// Maximum dismissals before hiding prompt for cooldown period
    private static let maxDismissals = 3

    /// Cooldown period in seconds (30 days)
    private static let cooldownPeriod: TimeInterval = 30 * 24 * 60 * 60

    // MARK: - Dependencies

    private let userDefaults: UserDefaults

    // MARK: - Initialization

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Public API

    /// Check if a prompt should be shown
    /// - Parameter type: The prompt type to check
    /// - Returns: True if prompt should be shown, false if suppressed
    public func shouldShowPrompt(for type: ProPromptType) -> Bool {
        let dismissalCount = getDismissalCount(for: type)
        let lastDismissalDate = getLastDismissalDate(for: type)

        // If under max dismissals, always show
        guard dismissalCount >= Self.maxDismissals else {
            return true
        }

        // If we have a last dismissal date, check cooldown
        if let lastDate = lastDismissalDate {
            let timeSinceDismissal = Date().timeIntervalSince(lastDate)
            if timeSinceDismissal < Self.cooldownPeriod {
                // Still in cooldown period
                return false
            } else {
                // Cooldown expired, reset counter
                resetDismissals(for: type)
                return true
            }
        }

        // Reached max dismissals but no date recorded (shouldn't happen)
        return false
    }

    /// Record a dismissal for a prompt type
    /// - Parameter type: The prompt type that was dismissed
    public func recordDismissal(for type: ProPromptType) {
        let currentCount = getDismissalCount(for: type)
        let newCount = currentCount + 1

        userDefaults.set(newCount, forKey: dismissalCountKey(for: type))
        userDefaults.set(Date(), forKey: lastDismissalDateKey(for: type))
    }

    /// Reset dismissal tracking for a specific prompt type
    /// - Parameter type: The prompt type to reset
    public func resetDismissals(for type: ProPromptType) {
        userDefaults.removeObject(forKey: dismissalCountKey(for: type))
        userDefaults.removeObject(forKey: lastDismissalDateKey(for: type))
    }

    /// Reset all dismissal tracking (useful for Pro users or debugging)
    public func resetAllDismissals() {
        for type in ProPromptType.allCases {
            resetDismissals(for: type)
        }
    }

    /// Get current dismissal count for debugging
    /// - Parameter type: The prompt type
    /// - Returns: Number of times prompt has been dismissed
    public func getDismissalCount(for type: ProPromptType) -> Int {
        return userDefaults.integer(forKey: dismissalCountKey(for: type))
    }

    // MARK: - Private Helpers

    private func getLastDismissalDate(for type: ProPromptType) -> Date? {
        return userDefaults.object(forKey: lastDismissalDateKey(for: type)) as? Date
    }

    private func dismissalCountKey(for type: ProPromptType) -> String {
        return "com.grobro.prompt.\(type.rawValue).dismissalCount"
    }

    private func lastDismissalDateKey(for type: ProPromptType) -> String {
        return "com.grobro.prompt.\(type.rawValue).lastDismissalDate"
    }
}

// MARK: - Prompt Types

public enum ProPromptType: String, CaseIterable {
    case gardenPlantLimit = "garden_plant_limit"
    case analytics = "analytics"
    case dataExport = "data_export"

    public var title: String {
        switch self {
        case .gardenPlantLimit:
            return "Upgrade for Unlimited Plants"
        case .analytics:
            return "Unlock Advanced Analytics"
        case .dataExport:
            return "Export Your Data with Pro"
        }
    }

    public var message: String {
        switch self {
        case .gardenPlantLimit:
            return "You've reached your 3-plant limit. Upgrade to Pro to track unlimited plants."
        case .analytics:
            return "Get detailed growth insights, trends, and optimization recommendations with Pro."
        case .dataExport:
            return "Export your complete plant history in CSV or JSON format with Pro."
        }
    }

    public var icon: String {
        switch self {
        case .gardenPlantLimit:
            return "leaf.circle.fill"
        case .analytics:
            return "chart.line.uptrend.xyaxis.circle.fill"
        case .dataExport:
            return "square.and.arrow.up.circle.fill"
        }
    }
}

// Note: Environment extensions are defined in GroBroFeature module
// to avoid SwiftUI dependency in Domain layer
