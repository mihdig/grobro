import Foundation

/// Supported light types for camera-based light metering
public enum LightType: String, CaseIterable, Codable, Sendable, Identifiable {
    case fullSpectrumLED
    case hps
    case mh
    case cfl
    case cmh
    case sunlight
    case whiteLED

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .fullSpectrumLED:
            return "Full Spectrum LED"
        case .hps:
            return "HPS"
        case .mh:
            return "MH (Metal Halide)"
        case .cfl:
            return "CFL"
        case .cmh:
            return "CMH (Ceramic Metal Halide)"
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
        case .mh:
            return 75
        case .cfl:
            return 85
        case .cmh:
            return 72
        case .sunlight:
            return 54
        case .whiteLED:
            return 75
        }
    }
}

