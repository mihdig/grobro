import Testing
import Foundation
@testable import GroBroDomain

@MainActor
@Suite("Prompt Dismissal Tracker Tests")
struct PromptDismissalTrackerTests {

    // MARK: - Test UserDefaults

    func makeTestTracker() -> PromptDismissalTracker {
        let testDefaults = UserDefaults(suiteName: "test.promptdismissal.\(UUID().uuidString)")!
        return PromptDismissalTracker(userDefaults: testDefaults)
    }

    // MARK: - Basic Functionality Tests

    @Test("Should show prompt initially")
    func shouldShowPromptInitially() async throws {
        let tracker = makeTestTracker()

        let shouldShow = tracker.shouldShowPrompt(for: .gardenPlantLimit)
        #expect(shouldShow == true)
    }

    @Test("Should record dismissal and increment count")
    func recordDismissal() async throws {
        let tracker = makeTestTracker()

        // Initial count should be 0
        #expect(tracker.getDismissalCount(for: .gardenPlantLimit) == 0)

        // Record first dismissal
        tracker.recordDismissal(for: .gardenPlantLimit)
        #expect(tracker.getDismissalCount(for: .gardenPlantLimit) == 1)

        // Record second dismissal
        tracker.recordDismissal(for: .gardenPlantLimit)
        #expect(tracker.getDismissalCount(for: .gardenPlantLimit) == 2)

        // Should still show prompt (under max)
        #expect(tracker.shouldShowPrompt(for: .gardenPlantLimit) == true)
    }

    @Test("Should suppress prompt after max dismissals")
    func suppressAfterMaxDismissals() async throws {
        let tracker = makeTestTracker()

        // Dismiss 3 times (max)
        for _ in 0..<3 {
            tracker.recordDismissal(for: .gardenPlantLimit)
        }

        #expect(tracker.getDismissalCount(for: .gardenPlantLimit) == 3)
        #expect(tracker.shouldShowPrompt(for: .gardenPlantLimit) == false)
    }

    @Test("Should track each prompt type separately")
    func separateTrackingPerPromptType() async throws {
        let tracker = makeTestTracker()

        // Dismiss garden prompt 3 times
        for _ in 0..<3 {
            tracker.recordDismissal(for: .gardenPlantLimit)
        }

        // Garden should be suppressed
        #expect(tracker.shouldShowPrompt(for: .gardenPlantLimit) == false)

        // Analytics should still show (independent tracking)
        #expect(tracker.shouldShowPrompt(for: .analytics) == true)
        #expect(tracker.getDismissalCount(for: .analytics) == 0)
    }

    @Test("Should reset dismissals for specific prompt")
    func resetDismissals() async throws {
        let tracker = makeTestTracker()

        // Dismiss 3 times
        for _ in 0..<3 {
            tracker.recordDismissal(for: .gardenPlantLimit)
        }

        #expect(tracker.shouldShowPrompt(for: .gardenPlantLimit) == false)

        // Reset dismissals
        tracker.resetDismissals(for: .gardenPlantLimit)

        // Should show again
        #expect(tracker.shouldShowPrompt(for: .gardenPlantLimit) == true)
        #expect(tracker.getDismissalCount(for: .gardenPlantLimit) == 0)
    }

    @Test("Should reset all dismissals")
    func resetAllDismissals() async throws {
        let tracker = makeTestTracker()

        // Dismiss all prompt types
        for promptType in ProPromptType.allCases {
            for _ in 0..<3 {
                tracker.recordDismissal(for: promptType)
            }
            #expect(tracker.shouldShowPrompt(for: promptType) == false)
        }

        // Reset all
        tracker.resetAllDismissals()

        // All should show again
        for promptType in ProPromptType.allCases {
            #expect(tracker.shouldShowPrompt(for: promptType) == true)
            #expect(tracker.getDismissalCount(for: promptType) == 0)
        }
    }

    // MARK: - Cooldown Period Tests

    @Test("Should respect cooldown period", .timeLimit(.minutes(1)))
    func cooldownPeriod() async throws {
        let testDefaults = UserDefaults(suiteName: "test.cooldown.\(UUID().uuidString)")!
        let tracker = PromptDismissalTracker(userDefaults: testDefaults)

        // Dismiss 3 times
        for _ in 0..<3 {
            tracker.recordDismissal(for: .gardenPlantLimit)
        }

        // Should be suppressed
        #expect(tracker.shouldShowPrompt(for: .gardenPlantLimit) == false)

        // Manually set last dismissal date to 31 days ago (past cooldown)
        let pastDate = Date().addingTimeInterval(-31 * 24 * 60 * 60)
        testDefaults.set(pastDate, forKey: "com.grobro.prompt.garden_plant_limit.lastDismissalDate")

        // Should show again after cooldown
        let shouldShowAfterCooldown = tracker.shouldShowPrompt(for: .gardenPlantLimit)
        #expect(shouldShowAfterCooldown == true)

        // Counter should be reset after cooldown check
        #expect(tracker.getDismissalCount(for: .gardenPlantLimit) == 0)
    }

    @Test("Should not show during cooldown period")
    func duringCooldown() async throws {
        let tracker = makeTestTracker()

        // Dismiss 3 times
        for _ in 0..<3 {
            tracker.recordDismissal(for: .gardenPlantLimit)
        }

        // Should still be suppressed (within 30 days)
        #expect(tracker.shouldShowPrompt(for: .gardenPlantLimit) == false)
    }
}

// MARK: - Prompt Type Tests

@Suite("Prompt Type Tests")
struct ProPromptTypeTests {

    @Test("All prompt types have unique IDs")
    func uniqueRawValues() {
        let rawValues = ProPromptType.allCases.map { $0.rawValue }
        let uniqueValues = Set(rawValues)
        #expect(rawValues.count == uniqueValues.count)
    }

    @Test("All prompt types have display properties")
    func displayProperties() {
        for promptType in ProPromptType.allCases {
            #expect(!promptType.title.isEmpty)
            #expect(!promptType.message.isEmpty)
            #expect(!promptType.icon.isEmpty)
        }
    }

    @Test("Prompt type titles are descriptive")
    func descriptiveTitles() {
        #expect(ProPromptType.gardenPlantLimit.title.contains("Unlimited"))
        #expect(ProPromptType.analytics.title.contains("Analytics"))
        #expect(ProPromptType.dataExport.title.contains("Export"))
    }
}
