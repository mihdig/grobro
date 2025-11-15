import SwiftUI
import GroBroDomain

// MARK: - Pro User View Modifier

/// View modifier that conditionally shows/hides content based on Pro status
@available(iOS 17.0, macOS 14.0, *)
struct ProUserModifier: ViewModifier {

    @Environment(ProEntitlementManager.self) private var proManager

    let showForProUsers: Bool

    func body(content: Content) -> some View {
        if showForProUsers {
            // Show only if user is Pro
            if proManager.isPro {
                content
            }
        } else {
            // Show only if user is NOT Pro (Free users)
            if !proManager.isPro {
                content
            }
        }
    }
}

// MARK: - View Extension

@available(iOS 17.0, macOS 14.0, *)
public extension View {

    /// Show this view only for Pro users
    /// - Returns: View that is visible only when user has Pro subscription
    func showForProUsers() -> some View {
        modifier(ProUserModifier(showForProUsers: true))
    }

    /// Show this view only for Free users
    /// - Returns: View that is visible only when user does NOT have Pro subscription
    func showForFreeUsers() -> some View {
        modifier(ProUserModifier(showForProUsers: false))
    }

    /// Hide Pro feature prompts and CTAs when user is Pro
    /// Convenience method equivalent to showForFreeUsers()
    /// - Returns: View that is hidden for Pro users
    func hideForProUsers() -> some View {
        modifier(ProUserModifier(showForProUsers: false))
    }
}

// MARK: - Feature Lock Overlay

/// Overlay that shows upgrade prompt when feature is locked for Free users
@available(iOS 18.0, macOS 15.0, *)
struct FeatureLockOverlay: ViewModifier {

    @Environment(ProEntitlementManager.self) private var proManager

    let feature: ProFeature
    let message: String
    let onUpgrade: () -> Void

    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: proManager.hasAccess(to: feature) ? 0 : 3)
                .disabled(!proManager.hasAccess(to: feature))

            if !proManager.hasAccess(to: feature) {
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.largeTitle)
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(feature.displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button {
                        onUpgrade()
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("Upgrade to Pro")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(radius: 20)
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
public extension View {

    /// Lock this feature for Free users with an upgrade prompt overlay
    /// - Parameters:
    ///   - feature: The Pro feature being locked
    ///   - message: Custom message explaining the feature benefit
    ///   - onUpgrade: Action to perform when user taps upgrade
    /// - Returns: View with feature lock overlay for Free users
    func lockForFreeUsers(
        feature: ProFeature,
        message: String,
        onUpgrade: @escaping () -> Void
    ) -> some View {
        modifier(FeatureLockOverlay(
            feature: feature,
            message: message,
            onUpgrade: onUpgrade
        ))
    }
}

// MARK: - Previews

#Preview("Pro User Content") {
    VStack(spacing: 20) {
        Text("This is visible to everyone")
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)

        Text("This is ONLY for Pro users")
            .padding()
            .background(Color.green.opacity(0.2))
            .cornerRadius(8)
            .showForProUsers()

        Text("This is ONLY for Free users")
            .padding()
            .background(Color.orange.opacity(0.2))
            .cornerRadius(8)
            .showForFreeUsers()

        Text("Upgrade CTA (hidden for Pro)")
            .padding()
            .background(Color.purple.opacity(0.2))
            .cornerRadius(8)
            .hideForProUsers()
    }
    .environment(ProEntitlementManager())
}

@available(iOS 18.0, macOS 15.0, *)
#Preview("Feature Lock") {
    VStack {
        Text("Advanced Analytics")
            .font(.largeTitle)
            .padding()

        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<5) { index in
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Chart \(index + 1)")
                        Spacer()
                        Text("42%")
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .lockForFreeUsers(
            feature: .advancedAnalytics,
            message: "Get detailed growth insights and optimization tips with Pro"
        ) {
            print("Show upgrade screen")
        }
    }
    .environment(ProEntitlementManager())
}
