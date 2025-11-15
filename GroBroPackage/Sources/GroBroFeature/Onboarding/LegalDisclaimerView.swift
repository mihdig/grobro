import SwiftUI
import GroBroDomain

/// Legal disclaimer and terms acceptance screen shown before first plant creation.
@available(iOS 17.0, *)
public struct LegalDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(OnboardingManager.self) private var onboardingManager

    /// Optional callback invoked after the user accepts the terms.
    private let onAccepted: (() -> Void)?

    public init(onAccepted: (() -> Void)? = nil) {
        self.onAccepted = onAccepted
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.deepBackground
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    ScrollView {
                        GlassCard(elevation: .standard) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Before You Start")
                                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primaryText)

                                Text("GroBro is an educational tool designed to help you track and optimize your grow. It does not replace local laws, regulations, or professional advice.")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondaryText)

                                VStack(alignment: .leading, spacing: 8) {
                                    bullet("You are responsible for complying with all local laws and regulations related to cultivation.")
                                    bullet("Analytics, diagnostics, and recommendations are informational only and may not reflect real-world results.")
                                    bullet("Environmental and nutrient guidance is based on best‑effort models and may not be suitable for every setup.")
                                    bullet("GroBro does not provide medical, legal, or financial advice.")
                                }

                                Text("By continuing, you confirm that you understand these limitations and accept full responsibility for how you use the app.")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primaryText)
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }

                    VStack(spacing: 12) {
                        NeonButton("I Understand and Agree", style: .primary) {
                            onboardingManager.acceptTerms()
                            dismiss()
                            onAccepted?()
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.tertiaryText)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Legal & Terms")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.criticalRed)
                .font(.system(size: 14))
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
        }
    }
}

#Preview {
    LegalDisclaimerView()
        .environment(OnboardingManager())
}

