import SwiftUI

/// Glassmorphic card component for Smart Greenhouse design system
/// Provides a translucent card with blur effect, gradient borders, and neon glow
///
/// Usage:
/// ```swift
/// GlassCard(isHighlighted: true) {
///     VStack {
///         Text("Card Content")
///     }
/// }
/// ```
public struct GlassCard<Content: View>: View {
    let content: Content
    var isHighlighted: Bool = false
    var elevation: Elevation = .standard
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16

    public enum Elevation {
        case subtle
        case standard
        case elevated

        var shadowRadius: CGFloat {
            switch self {
            case .subtle: return 8
            case .standard: return 20
            case .elevated: return 24
            }
        }

        var shadowY: CGFloat {
            switch self {
            case .subtle: return 4
            case .standard: return 10
            case .elevated: return 12
            }
        }

        var shadowOpacity: Double {
            switch self {
            case .subtle: return 0.2
            case .standard: return 0.3
            case .elevated: return 0.4
            }
        }
    }

    public init(
        isHighlighted: Bool = false,
        elevation: Elevation = .standard,
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.isHighlighted = isHighlighted
        self.elevation = elevation
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    public var body: some View {
        content
            .padding(padding)
            .background(glassBackground)
            .background(.ultraThinMaterial)
            .shadow(
                color: isHighlighted ? Color.electricGreen.opacity(0.4) : Color.black.opacity(elevation.shadowOpacity),
                radius: elevation.shadowRadius,
                x: 0,
                y: elevation.shadowY
            )
            .scaleEffect(isHighlighted ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
    }

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.surfaceDark.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        Color.glassBorderGradient(highlighted: isHighlighted),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Compact Variant
// Note: Compact variant removed due to generic parameter shadowing
// Use GlassCard(elevation: .subtle, cornerRadius: 12, padding: 12) instead

// MARK: - Preview

#Preview("GlassCard Variants") {
    ZStack {
        Color.deepBackground
            .ignoresSafeArea()

        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Standard Card")
                        .font(.headline)
                        .foregroundColor(.primaryText)

                    Text("This is a standard glassmorphic card with default settings.")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
            }

            GlassCard(isHighlighted: true) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Highlighted Card")
                        .font(.headline)
                        .foregroundColor(.primaryText)

                    Text("This card has the green glow highlighting effect.")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
            }

            // Compact variant - commenting out due to type inference issue
            // GlassCard.compact {
            //     HStack {
            //         Image(systemName: "leaf.fill")
            //             .foregroundColor(.electricGreen)
            //         Text("Compact Card")
            //             .foregroundColor(.primaryText)
            //     }
            // }

            GlassCard(elevation: .elevated) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Elevated Card")
                        .font(.headline)
                        .foregroundColor(.primaryText)

                    Text("This card has increased elevation with larger shadow.")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding()
    }
}
