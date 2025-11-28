import SwiftUI

/// Central animation tokens for the Smart Greenhouse design system.
/// Keeps motion consistent across the app and makes it easy to
/// respect accessibility settings like Reduce Motion.
public enum SmartGreenhouseAnimations {
    /// Default spring used for card elevation / pop effects.
    public static let cardPop = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Spring used for sheet / wizard step transitions.
    public static let sheetSlide = Animation.spring(response: 0.35, dampingFraction: 0.8)

    /// Fast fade used for small state changes.
    public static let quickFade = Animation.easeInOut(duration: 0.2)

    /// Repeating pulse effect for status indicators.
    public static let pulse = Animation.easeInOut(duration: 1.6).repeatForever(autoreverses: true)

    /// Subtle glow/breathing effect for highlighted elements.
    public static let glow = Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)
}

// MARK: - Motion-Aware Animations

/// View modifier that disables animations when Reduce Motion is enabled.
public struct MotionSensitiveAnimationModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let animation: Animation
    let value: Value

    public func body(content: Content) -> some View {
        if reduceMotion {
            content.animation(nil, value: value)
        } else {
            content.animation(animation, value: value)
        }
    }
}

public extension View {
    /// Applies an animation that automatically respects the user's
    /// Reduce Motion accessibility setting.
    func motionSensitiveAnimation<Value: Equatable>(
        _ animation: Animation,
        value: Value
    ) -> some View {
        modifier(MotionSensitiveAnimationModifier(animation: animation, value: value))
    }
}

// MARK: - Motion-Aware Symbol Effects

/// Modifier that conditionally applies SF Symbol effects based on Reduce Motion.
public struct MotionSensitiveSymbolEffect<T: SymbolEffect & IndefiniteSymbolEffect>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let effect: T
    let isActive: Bool

    public func body(content: Content) -> some View {
        if reduceMotion || !isActive {
            content
        } else {
            content.symbolEffect(effect, isActive: isActive)
        }
    }
}

public extension View {
    /// Applies an SF Symbol effect only when motion is allowed.
    func motionSensitiveSymbolEffect<T: SymbolEffect & IndefiniteSymbolEffect>(
        _ effect: T,
        isActive: Bool = true
    ) -> some View {
        modifier(MotionSensitiveSymbolEffect(effect: effect, isActive: isActive))
    }
}

