import SwiftUI

/// Glassmorphic loading indicator used for async operations throughout the app.
public struct GlassLoadingIndicator: View {
    public enum Style {
        case inline
        case fullWidth
    }

    private let title: String?
    private let subtitle: String?
    private let style: Style

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    public init(
        title: String? = nil,
        subtitle: String? = nil,
        style: Style = .inline
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.surfaceDark.opacity(0.9))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.glassBorderGradient(highlighted: true), lineWidth: 1)
                    )
                    .shadow(color: Color.electricGreen.opacity(0.4), radius: 8)

                ProgressView()
                    .tint(.electricGreen)
            }
            .scaleEffect(isPulsing ? 1.05 : 0.95)
            .motionSensitiveAnimation(SmartGreenhouseAnimations.pulse, value: isPulsing)

            VStack(alignment: .leading, spacing: 4) {
                if let title {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primaryText)
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .frame(maxWidth: style == .fullWidth ? .infinity : nil)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceDark.opacity(0.9))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.glassBorderGradient(highlighted: true), lineWidth: 1)
                )
        )
        .onAppear {
            guard !reduceMotion else { return }
            isPulsing = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title ?? "Loading")
        .accessibilityValue(subtitle ?? "Please wait")
    }
}

// MARK: - Skeleton Card & Shimmer

/// Generic glassmorphic skeleton card used to represent loading content.
public struct GlassSkeletonCard: View {
    private let lineCount: Int
    private let showsIcon: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(lineCount: Int = 3, showsIcon: Bool = false) {
        self.lineCount = lineCount
        self.showsIcon = showsIcon
    }

    public var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                if showsIcon {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.surfaceLight.opacity(0.6))
                        .frame(width: 32, height: 32)
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(0..<lineCount, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.surfaceLight.opacity(index == 0 ? 0.9 : 0.6))
                            .frame(height: 12)
                    }
                }
            }
            .redacted(reason: .placeholder)
        }
        .modifier(ShimmerModifier(isActive: !reduceMotion))
        .accessibilityHidden(true)
    }
}

/// Simple shimmer effect used for skeleton placeholders.
struct ShimmerModifier: ViewModifier {
    let isActive: Bool

    @State private var phase: CGFloat = -1.0

    func body(content: Content) -> some View {
        Group {
            if isActive {
                content
                    .overlay(shimmer.mask(content))
                    .onAppear {
                        phase = 1.5
                    }
            } else {
                content
            }
        }
    }

    private var shimmer: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            LinearGradient(
                colors: [
                    .white.opacity(0.0),
                    .white.opacity(0.5),
                    .white.opacity(0.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * 1.5, height: proxy.size.height)
            .rotationEffect(.degrees(20))
            .offset(x: width * phase)
            .animation(
                SmartGreenhouseAnimations.glow,
                value: phase
            )
        }
    }
}

public extension View {
    /// Applies a glassmorphic skeleton placeholder with shimmer when active.
    func glassSkeleton(isActive: Bool) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}

// MARK: - Preview

#Preview("Glass Loading States") {
    ZStack {
        Color.deepBackground
            .ignoresSafeArea()

        VStack(spacing: 24) {
            GlassLoadingIndicator(
                title: "Loading data...",
                subtitle: "This may take a moment",
                style: .fullWidth
            )

            GlassSkeletonCard(lineCount: 3, showsIcon: true)
        }
        .padding()
    }
}
