import SwiftUI
import GroBroDomain

/// Reusable contextual prompt component for Pro features
/// Non-modal, tasteful banner/card that respects dismissals
@available(iOS 18.0, macOS 15.0, *)
public struct ProFeaturePromptView: View {

    @Environment(ProEntitlementManager.self) private var proManager
    @Environment(PromptDismissalTracker.self) private var dismissalTracker
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let promptType: ProPromptType
    let onUpgrade: () -> Void

    @State private var isVisible = true
    @State private var isDismissed = false

    public init(
        promptType: ProPromptType,
        onUpgrade: @escaping () -> Void
    ) {
        self.promptType = promptType
        self.onUpgrade = onUpgrade
    }

    public var body: some View {
        Group {
            // Only show if:
            // 1. User is not Pro
            // 2. Not dismissed in this session
            // 3. Dismissal tracker allows showing
            if !proManager.isPro && isVisible && !isDismissed {
                promptContent
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        // Check dismissal tracker when view appears
                        if !dismissalTracker.shouldShowPrompt(for: promptType) {
                            isVisible = false
                        }
                    }
            }
        }
        .motionSensitiveAnimation(SmartGreenhouseAnimations.quickFade, value: isVisible)
    }

    // MARK: - Prompt Content

    private var promptContent: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Image(systemName: promptType.icon)
                    .font(.title2)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32)

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(promptType.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(promptType.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                // Dismiss button
                Button {
                    handleDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(Circle().fill(Color.gray.opacity(0.2)))
                }
                .buttonStyle(.plain)
            }
            .padding(12)

            // Upgrade button
            Button {
                onUpgrade()
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Pro")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }

    // MARK: - Actions

    private func handleDismiss() {
        // Record dismissal
        dismissalTracker.recordDismissal(for: promptType)

        // Hide with animation
        if reduceMotion {
            isDismissed = true
            isVisible = false
        } else {
            withAnimation(SmartGreenhouseAnimations.quickFade) {
                isDismissed = true
                isVisible = false
            }
        }
    }
}

// MARK: - Inline Variant

/// Inline variant that appears as a card within content flow
@available(iOS 18.0, macOS 15.0, *)
public struct ProFeatureInlinePrompt: View {

    @Environment(ProEntitlementManager.self) private var proManager
    @Environment(PromptDismissalTracker.self) private var dismissalTracker
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let promptType: ProPromptType
    let onUpgrade: () -> Void

    @State private var isVisible = true

    public init(
        promptType: ProPromptType,
        onUpgrade: @escaping () -> Void
    ) {
        self.promptType = promptType
        self.onUpgrade = onUpgrade
    }

    public var body: some View {
        Group {
            if !proManager.isPro && isVisible {
                VStack(spacing: 16) {
                    // Icon and title
                    VStack(spacing: 12) {
                        Image(systemName: promptType.icon)
                            .font(.largeTitle)
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(promptType.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        Text(promptType.message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Action buttons
                    HStack(spacing: 12) {
                        Button("Maybe Later") {
                            handleDismiss()
                        }
                        .buttonStyle(.bordered)

                        Button {
                            onUpgrade()
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                Text("Upgrade to Pro")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .motionSensitiveAnimation(SmartGreenhouseAnimations.quickFade, value: isVisible)
        .onAppear {
            if !dismissalTracker.shouldShowPrompt(for: promptType) {
                isVisible = false
            }
        }
    }

    private func handleDismiss() {
        dismissalTracker.recordDismissal(for: promptType)
        if reduceMotion {
            isVisible = false
        } else {
            withAnimation(SmartGreenhouseAnimations.quickFade) {
                isVisible = false
            }
        }
    }
}

// MARK: - Banner Variant

/// Floating banner that appears at top/bottom of screen
@available(iOS 18.0, macOS 15.0, *)
public struct ProFeatureBanner: View {

    @Environment(ProEntitlementManager.self) private var proManager
    @Environment(PromptDismissalTracker.self) private var dismissalTracker
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let promptType: ProPromptType
    let onUpgrade: () -> Void

    @State private var isVisible = true

    public init(
        promptType: ProPromptType,
        onUpgrade: @escaping () -> Void
    ) {
        self.promptType = promptType
        self.onUpgrade = onUpgrade
    }

    public var body: some View {
        Group {
            if !proManager.isPro && isVisible {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(promptType.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    Button("Upgrade") {
                        onUpgrade()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button {
                        handleDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .motionSensitiveAnimation(SmartGreenhouseAnimations.sheetSlide, value: isVisible)
        .onAppear {
            if !dismissalTracker.shouldShowPrompt(for: promptType) {
                isVisible = false
            }
        }
    }

    private func handleDismiss() {
        dismissalTracker.recordDismissal(for: promptType)
        if reduceMotion {
            isVisible = false
        } else {
            withAnimation(SmartGreenhouseAnimations.sheetSlide) {
                isVisible = false
            }
        }
    }
}

// MARK: - Previews

@available(iOS 18.0, macOS 15.0, *)
#Preview("Card Prompt") {
    VStack {
        ProFeaturePromptView(promptType: .gardenPlantLimit) {
            print("Upgrade tapped")
        }
        .padding()

        Spacer()
    }
    .environment(ProEntitlementManager())
    .environment(PromptDismissalTracker())
}

@available(iOS 18.0, macOS 15.0, *)
#Preview("Inline Prompt") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Some content above")
                .padding()

            ProFeatureInlinePrompt(promptType: .analytics) {
                print("Upgrade tapped")
            }
            .padding(.horizontal)

            Text("Some content below")
                .padding()
        }
    }
    .environment(ProEntitlementManager())
    .environment(PromptDismissalTracker())
}

@available(iOS 18.0, macOS 15.0, *)
#Preview("Banner") {
    VStack {
        ProFeatureBanner(promptType: .dataExport) {
            print("Upgrade tapped")
        }
        .padding()

        Spacer()

        Text("Main content here")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .environment(ProEntitlementManager())
    .environment(PromptDismissalTracker())
}
