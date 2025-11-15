import Foundation
import SwiftUI

/// Manages onboarding state and progress tracking
@Observable
@MainActor
public final class OnboardingManager: Sendable {
    // MARK: - Onboarding State

    /// Whether the user has completed the welcome flow
    public var hasCompletedWelcome: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedWelcome, forKey: "hasCompletedWelcome")
        }
    }

    /// Whether the user has created their first plant
    public var hasCreatedFirstPlant: Bool {
        didSet {
            UserDefaults.standard.set(hasCreatedFirstPlant, forKey: "hasCreatedFirstPlant")
        }
    }

    /// Whether the user has accepted legal terms
    public var hasAcceptedTerms: Bool {
        didSet {
            UserDefaults.standard.set(hasAcceptedTerms, forKey: "hasAcceptedTerms")
        }
    }

    /// Whether onboarding is complete
    public var isOnboardingComplete: Bool {
        hasCompletedWelcome && hasCreatedFirstPlant && hasAcceptedTerms
    }

    /// Whether to show onboarding
    public var shouldShowOnboarding: Bool {
        !hasCompletedWelcome
    }

    // MARK: - Initialization

    public init() {
        self.hasCompletedWelcome = UserDefaults.standard.bool(forKey: "hasCompletedWelcome")
        self.hasCreatedFirstPlant = UserDefaults.standard.bool(forKey: "hasCreatedFirstPlant")
        self.hasAcceptedTerms = UserDefaults.standard.bool(forKey: "hasAcceptedTerms")
    }

    // MARK: - Public Methods

    /// Mark welcome flow as complete
    public func completeWelcome() {
        hasCompletedWelcome = true
    }

    /// Mark first plant creation as complete
    public func completeFirstPlant() {
        hasCreatedFirstPlant = true
    }

    /// Mark terms acceptance as complete
    public func acceptTerms() {
        hasAcceptedTerms = true
    }

    /// Reset onboarding (for testing or Settings > Restart Onboarding)
    public func resetOnboarding() {
        hasCompletedWelcome = false
        hasCreatedFirstPlant = false
        hasAcceptedTerms = false
    }

    /// Skip onboarding entirely (sets all flags to complete)
    public func skipOnboarding() {
        hasCompletedWelcome = true
        hasCreatedFirstPlant = true
        hasAcceptedTerms = true
    }
}
