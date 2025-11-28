import SwiftUI
import GroBroDomain

/// Tutorial overlay for first-time users of AR light distance measurement
@MainActor
public struct LightDistanceTutorial: View {
    @Binding var isPresented: Bool

    public init(isPresented: Binding<Bool>) {
        _isPresented = isPresented
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "ruler.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.electricGreen, .neonGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Measure Light Distance")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primaryText)

                    Text("Use AR to measure the distance from your light to plant canopy")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 60)

                // Steps
                VStack(spacing: 24) {
                    TutorialStep(
                        number: 1,
                        icon: "lightbulb.fill",
                        iconColor: .warningOrange,
                        title: "Tap Your Light",
                        description: "Point your camera at the light source and tap the screen to mark it"
                    )

                    TutorialStep(
                        number: 2,
                        icon: "leaf.fill",
                        iconColor: .successGreen,
                        title: "Tap Plant Canopy",
                        description: "Point at the top of your plant and tap to mark it"
                    )

                    TutorialStep(
                        number: 3,
                        icon: "checkmark.circle.fill",
                        iconColor: .electricGreen,
                        title: "Get Distance & Save",
                        description: "See the distance with real-time recommendations"
                    )
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: startTutorial) {
                        Text("Got It!")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.deepBackground)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.electricGreen, .neonGreen],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button(action: skipTutorial) {
                        Text("Skip Tutorial")
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryText)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    private func startTutorial() {
        UserDefaults.standard.set(true, forKey: "hasSeenLightARTutorial")
        isPresented = false
    }

    private func skipTutorial() {
        UserDefaults.standard.set(true, forKey: "hasSeenLightARTutorial")
        isPresented = false
    }
}

/// Individual tutorial step component
struct TutorialStep: View {
    let number: Int
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            // Step number badge
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Step \(number)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondaryText)
                        .textCase(.uppercase)

                    Spacer()
                }

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
