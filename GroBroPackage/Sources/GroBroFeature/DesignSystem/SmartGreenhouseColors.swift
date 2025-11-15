import SwiftUI

/// Smart Greenhouse Design System - Color Palette
/// Version: 1.0
/// Spec: docs/smart-greenhouse-design-spec.md

public extension Color {
    // MARK: - Primary Palette

    /// Deep background color for main app background
    /// Hex: #0D0F12
    static let deepBackground = Color(hex: "0D0F12")

    /// Surface dark color for elevated cards and modals
    /// Hex: #1A1D23
    static let surfaceDark = Color(hex: "1A1D23")

    /// Surface light color for input fields and tertiary surfaces
    /// Hex: #252930
    static let surfaceLight = Color(hex: "252930")

    /// Electric green for primary actions and plant health
    /// Hex: #00FF7F
    static let electricGreen = Color(hex: "00FF7F")

    /// Neon green for active states and highlights
    /// Hex: #39FF14
    static let neonGreen = Color(hex: "39FF14")

    /// Sage green for muted text and icons
    /// Hex: #52B788
    static let sageGreen = Color(hex: "52B788")

    // MARK: - Accent Colors

    /// Cyan bright for water/humidity indicators
    /// Hex: #00F5FF
    static let cyanBright = Color(hex: "00F5FF")

    /// Purple neon for AI/diagnostics features
    /// Hex: #9D4EDD
    static let purpleNeon = Color(hex: "9D4EDD")

    /// Gold electric for Pro features and premium indicators
    /// Hex: #FFD700
    static let goldElectric = Color(hex: "FFD700")

    // MARK: - Semantic Colors

    /// Success green for optimal conditions
    /// Hex: #00FF7F (same as electricGreen)
    static let successGreen = Color(hex: "00FF7F")

    /// Warning orange for caution zones
    /// Hex: #FF9500
    static let warningOrange = Color(hex: "FF9500")

    /// Critical red for alerts and dangerous conditions
    /// Hex: #FF3B30
    static let criticalRed = Color(hex: "FF3B30")

    /// Info cyan for informational messages
    /// Hex: #00F5FF (same as cyanBright)
    static let infoCyan = Color(hex: "00F5FF")

    // MARK: - Text Colors

    /// Primary text color (white)
    static let primaryText = Color.white

    /// Secondary text color for body text
    /// Hex: #A8B2C1
    static let secondaryText = Color(hex: "A8B2C1")

    /// Tertiary text color for captions and metadata
    /// Hex: #6B7280
    static let tertiaryText = Color(hex: "6B7280")

    /// Disabled text color
    /// Hex: #4B5563
    static let disabledText = Color(hex: "4B5563")

    // MARK: - Environmental Zone Colors

    /// Optimal zone background (20% opacity)
    static let optimalZone = Color(hex: "00FF7F").opacity(0.2)

    /// Caution zone background (20% opacity)
    static let cautionZone = Color(hex: "FF9500").opacity(0.2)

    /// Critical zone background (20% opacity)
    static let criticalZone = Color(hex: "FF3B30").opacity(0.2)

    // MARK: - Gradients

    /// Deep space background gradient
    static let deepSpaceGradient = LinearGradient(
        colors: [Color.deepBackground, Color.surfaceDark],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Green accent gradient
    static let greenAccentGradient = LinearGradient(
        colors: [Color.electricGreen, Color.neonGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Cyan-purple data gradient
    static let dataGradient = LinearGradient(
        colors: [Color.cyanBright, Color.purpleNeon],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Glass border gradient for glassmorphic cards
    static func glassBorderGradient(highlighted: Bool = false) -> LinearGradient {
        LinearGradient(
            colors: highlighted ?
                [Color.electricGreen.opacity(0.6), Color.cyanBright.opacity(0.3)] :
                [Color.electricGreen.opacity(0.3), Color.cyanBright.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Hex Color Initializer

public extension Color {
    /// Initialize Color from hex string
    /// Supports 3, 6, and 8 character hex strings (RGB and ARGB)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Environmental Status Colors

public extension Color {
    /// Returns color for temperature value
    /// - Parameter temp: Temperature in Fahrenheit
    /// - Returns: Color representing temperature zone
    static func temperatureColor(for temp: Double) -> Color {
        switch temp {
        case ..<70: return .cyanBright
        case 70..<80: return .electricGreen
        case 80..<85: return .warningOrange
        default: return .criticalRed
        }
    }

    /// Returns color for VPD value
    /// - Parameter vpd: Vapor Pressure Deficit in kPa
    /// - Returns: Color representing VPD zone
    static func vpdColor(for vpd: Double) -> Color {
        if vpd >= 0.8 && vpd <= 1.2 {
            return .electricGreen
        }
        return .warningOrange
    }

    /// Returns color for humidity value
    /// - Parameter humidity: Relative humidity percentage
    /// - Returns: Color representing humidity zone
    static func humidityColor(for humidity: Double) -> Color {
        switch humidity {
        case 50..<70: return .electricGreen
        case 40..<50, 70..<80: return .warningOrange
        default: return .criticalRed
        }
    }
}
