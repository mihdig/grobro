import SwiftUI

/// Neon-styled button component for Smart Greenhouse design system
/// Provides primary, secondary, tertiary, and destructive button variants
///
/// Usage:
/// ```swift
/// NeonButton("Save Changes", style: .primary) {
///     // Action
/// }
/// ```
public struct NeonButton: View {
    let title: String
    let action: () -> Void
    var style: ButtonStyle = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var fullWidth: Bool = true

    public enum ButtonStyle {
        case primary
        case secondary
        case tertiary
        case destructive
    }

    public init(
        _ title: String,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.fullWidth = fullWidth
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                }

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(foregroundColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, fullWidth ? 0 : 24)
            .background(backgroundView)
            .cornerRadius(12)
            .shadow(
                color: shadowColor,
                radius: 16,
                x: 0,
                y: 4
            )
            .opacity(isDisabled || isLoading ? 0.5 : 1.0)
        }
        .disabled(isLoading || isDisabled)
        .accessibilityLabel(Text(title))
        .accessibilityValue(
            isLoading
                ? Text("Loading")
                : (isDisabled ? Text("Disabled") : Text(""))
        )
        .accessibilityHint(
            isLoading
                ? Text("Please wait for the action to finish")
                : Text("Double tap to activate")
        )
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [Color.electricGreen, Color.neonGreen],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .secondary:
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.electricGreen, lineWidth: 2)

        case .tertiary:
            Color.clear

        case .destructive:
            Color.criticalRed
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return Color.deepBackground
        case .secondary, .tertiary:
            return Color.electricGreen
        case .destructive:
            return .white
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary:
            return Color.electricGreen.opacity(0.4)
        case .destructive:
            return Color.criticalRed.opacity(0.4)
        default:
            return .clear
        }
    }
}

// MARK: - Icon Button Variant

extension NeonButton {
    /// Creates a button with an icon
    static func withIcon(
        _ title: String,
        systemImage: String,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .medium))
                }

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(style == .primary || style == .destructive ? Color.deepBackground : Color.electricGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundForStyle(style))
            .cornerRadius(12)
            .shadow(
                color: style == .primary ? Color.electricGreen.opacity(0.4) :
                       style == .destructive ? Color.criticalRed.opacity(0.4) : .clear,
                radius: 16,
                y: 4
            )
        }
        .disabled(isLoading)
        .accessibilityLabel(Text(title))
        .accessibilityValue(isLoading ? Text("Loading") : Text(""))
        .accessibilityHint(
            isLoading
                ? Text("Please wait for the action to finish")
                : Text("Double tap to activate")
        )
    }

    private static func backgroundForStyle(_ style: ButtonStyle) -> some View {
        Group {
            switch style {
            case .primary:
                LinearGradient(
                    colors: [Color.electricGreen, Color.neonGreen],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .secondary:
                Color.clear
            case .tertiary:
                Color.clear
            case .destructive:
                Color.criticalRed
            }
        }
    }
}

// MARK: - Preview

#Preview("NeonButton Variants") {
    ZStack {
        Color.deepBackground
            .ignoresSafeArea()

        VStack(spacing: 20) {
            NeonButton("Primary Button", style: .primary) {
                print("Primary tapped")
            }

            NeonButton("Secondary Button", style: .secondary) {
                print("Secondary tapped")
            }

            NeonButton("Tertiary Button", style: .tertiary) {
                print("Tertiary tapped")
            }

            NeonButton("Destructive Button", style: .destructive) {
                print("Destructive tapped")
            }

            NeonButton("Loading Button", style: .primary, isLoading: true) {
                print("Loading tapped")
            }

            NeonButton("Disabled Button", style: .primary, isDisabled: true) {
                print("Disabled tapped")
            }

            NeonButton.withIcon("With Icon", systemImage: "leaf.fill", style: .primary) {
                print("Icon button tapped")
            }
        }
        .padding()
    }
}
