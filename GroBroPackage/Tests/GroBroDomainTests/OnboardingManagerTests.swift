import Testing
@testable import GroBroDomain

@MainActor
@Suite("OnboardingManager Tests")
struct OnboardingManagerTests {

    @Test("Reset clears all onboarding flags")
    func resetClearsFlags() {
        let manager = OnboardingManager()

        // Set all flags to true
        manager.completeWelcome()
        manager.completeFirstPlant()
        manager.acceptTerms()

        // Sanity check
        #expect(manager.hasCompletedWelcome == true)
        #expect(manager.hasCreatedFirstPlant == true)
        #expect(manager.hasAcceptedTerms == true)
        #expect(manager.isOnboardingComplete == true)

        // Reset and verify
        manager.resetOnboarding()

        #expect(manager.hasCompletedWelcome == false)
        #expect(manager.hasCreatedFirstPlant == false)
        #expect(manager.hasAcceptedTerms == false)
        #expect(manager.isOnboardingComplete == false)
        #expect(manager.completedStepCount == 0)
        #expect(manager.progress == 0)
    }

    @Test("Completing steps updates progress")
    func completingStepsUpdatesProgress() {
        let manager = OnboardingManager()
        manager.resetOnboarding()

        #expect(manager.completedStepCount == 0)
        #expect(manager.progress == 0)

        manager.completeWelcome()
        #expect(manager.completedStepCount == 1)
        #expect(manager.progress > 0 && manager.progress < 1)

        manager.completeFirstPlant()
        #expect(manager.completedStepCount == 2)
        #expect(manager.progress > 0 && manager.progress < 1)

        manager.acceptTerms()
        #expect(manager.completedStepCount == manager.totalStepCount)
        #expect(manager.isOnboardingComplete == true)
        #expect(manager.progress == 1)
    }

    @Test("Skip onboarding only marks welcome complete")
    func skipOnboardingMarksWelcomeOnly() {
        let manager = OnboardingManager()
        manager.resetOnboarding()

        manager.skipOnboarding()

        #expect(manager.hasCompletedWelcome == true)
        #expect(manager.hasCreatedFirstPlant == false)
        #expect(manager.hasAcceptedTerms == false)
        #expect(manager.isOnboardingComplete == false)
        #expect(manager.completedStepCount == 1)
    }
}

