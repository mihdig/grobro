import Foundation

/// Supported light types for camera-based light metering
public enum LightType: String, CaseIterable, Codable, Sendable, Identifiable {
    case fullSpectrumLED
    case hps
    case sunlight
    case whiteLED

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .fullSpectrumLED:
            return "Full Spectrum LED"
        case .hps:
            return "HPS / MH"
        case .sunlight:
            return "Sunlight"
        case .whiteLED:
            return "Cool/Warm White LED"
        }
    }

    /// Lux → PPFD divisor based on spectrum (approximate)
    public var luxToPPFDDivisor: Double {
        switch self {
        case .fullSpectrumLED:
            return 70
        case .hps:
            return 80
        case .sunlight:
            return 54
        case .whiteLED:
            return 75
        }
    }
}

