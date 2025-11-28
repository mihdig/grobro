import SwiftUI
import GroBroDomain

/// Welcome screen with feature highlights for first-time users
@MainActor
public struct WelcomeView: View {
    @Environment(OnboardingManager.self) private var onboardingManager
    @State private var currentPage: Int = 0

    private let features: [FeatureHighlight] = [
        FeatureHighlight(
            icon: "leaf.fill",
            title: "Smart Plant Diary",
            description: "Track growth, watering, and health with AI-powered diagnostics"
        ),
        FeatureHighlight(
            icon: "chart.line.uptrend.xyaxis",
            title: "Environmental Control",
            description: "Connect AC Infinity & Vivosun controllers for automated monitoring"
        ),
        FeatureHighlight(
            icon: "flask.fill",
            title: "Nutrient Management",
            description: "Pre-built feeding schedules from GHE, Advanced Nutrients, Fox Farm & more"
        ),
        FeatureHighlight(
            icon: "icloud.fill",
            title: "Pro Features",
            description: "Advanced analytics, iCloud sync, data export & more with Pro"
        )
    ]

    public init() {}

    public var body: some View {
        ZStack {
            // Smart Greenhouse dark background
            Color.deepBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.electricGreen, .neonGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .electricGreen.opacity(0.6), radius: 20)

                    Text("Welcome to GroBro")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primaryText)

                    Text("Your AI-powered cultivation assistant")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.secondaryText)
                }
                .padding(.bottom, 40)

                // Feature cards with paging
                TabView(selection: $currentPage) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        FeatureHighlightCard(feature: feature)
                            .tag(index)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 320)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                #else
                .frame(height: 320)
                #endif

                // Onboarding progress
                VStack(spacing: 4) {
                    ProgressView(value: onboardingManager.progress)
                        .progressViewStyle(.linear)
                        .tint(.electricGreen)

                    Text(progressLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.secondaryText)
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)

                Spacer()

                // Buttons
                VStack(spacing: 16) {
                    NeonButton(
                        "Get Started",
                        style: .primary
                    ) {
                        onboardingManager.completeWelcome()
                    }

                    Button {
                        onboardingManager.skipOnboarding()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.tertiaryText)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }

    private var progressLabel: String {
        let completed = onboardingManager.completedStepCount
        let total = onboardingManager.totalStepCount

        if onboardingManager.isOnboardingComplete {
            return "Onboarding complete – you're ready to grow."
        } else {
            return "Onboarding progress: \(completed) of \(total) steps"
        }
    }
}

// MARK: - Feature Highlight Model

struct FeatureHighlight {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Feature Highlight Card

@MainActor
struct FeatureHighlightCard: View {
    let feature: FeatureHighlight

    var body: some View {
        GlassCard(elevation: .standard) {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: feature.icon)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.electricGreen, .cyanBright],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .electricGreen.opacity(0.4), radius: 12)

                VStack(spacing: 12) {
                    // Title
                    Text(feature.title)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primaryText)
                        .multilineTextAlignment(.center)

                    // Description
                    Text(feature.description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .padding(32)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Previews

#Preview("Welcome View") {
    WelcomeView()
        .environment(OnboardingManager())
}

#Preview("Feature Card") {
    FeatureHighlightCard(
        feature: FeatureHighlight(
            icon: "leaf.fill",
            title: "Smart Plant Diary",
            description: "Track growth, watering, and health with AI-powered diagnostics"
        )
    )
    .background(Color.deepBackground)
}
