import Foundation

/// Pure service responsible for converting camera exposure information into Lux/PPFD/DLI estimates
/// and classifying intensity relative to plant stage.
public struct LightMeterService {

    public init() {}

    /// Estimates Lux from camera exposure parameters and a calibration constant.
    /// The formula is approximate and intended for relative guidance.
    public func estimateLux(
        iso: Double,
        exposureDurationSeconds: Double,
        aperture: Double,
        lightType: LightType
    ) -> Double {
        guard iso > 0, exposureDurationSeconds > 0, aperture > 0 else {
            return 0
        }

        // Base exposure-derived value
        let base = (aperture * aperture) / (iso * exposureDurationSeconds)

        // Calibration factor keeps values in a reasonable range for indoor grow lights.
        let calibration: Double
        switch lightType {
        case .fullSpectrumLED:
            calibration = 12_000
        case .hps:
            calibration = 10_000
        case .sunlight:
            calibration = 20_000
        case .whiteLED:
            calibration = 11_000
        }

        return max(0, base * calibration)
    }

    /// Converts Lux to PPFD based on light type spectrum.
    public func luxToPPFD(lux: Double, lightType: LightType) -> Double {
        guard lux > 0 else { return 0 }
        return lux / lightType.luxToPPFDDivisor
    }

    /// Calculates Daily Light Integral (DLI) in mol/m²/day.
    public func dli(ppfd: Double, photoperiodHours: Double) -> Double {
        guard ppfd > 0, photoperiodHours > 0 else { return 0 }
        return (ppfd * photoperiodHours * 3600) / 1_000_000
    }

    /// Computes a full measurement bundle for UI display.
    public func makeMeasurement(
        iso: Double,
        exposureDurationSeconds: Double,
        aperture: Double,
        lightType: LightType,
        photoperiodHours: Double
    ) -> LightMeasurement {
        let lux = estimateLux(
            iso: iso,
            exposureDurationSeconds: exposureDurationSeconds,
            aperture: aperture,
            lightType: lightType
        )
        let ppfd = luxToPPFD(lux: lux, lightType: lightType)
        let dliValue = dli(ppfd: ppfd, photoperiodHours: photoperiodHours)

        return LightMeasurement(
            ppfd: ppfd,
            lux: lux,
            dli: dliValue,
            lightType: lightType,
            photoperiodHours: photoperiodHours
        )
    }

    /// Classifies PPFD relative to recommended ranges for the plant's stage.
    public func intensityZone(ppfd: Double, stage: PlantStage) -> LightIntensityZone {
        let range = recommendedRange(for: stage)

        if ppfd < range.lowerBound {
            return .tooLow
        } else if ppfd > range.upperBound {
            return .tooHigh
        } else {
            return .optimal
        }
    }

    /// Recommended PPFD range for a given stage (μmol/m²/s).
    public func recommendedRange(for stage: PlantStage) -> ClosedRange<Double> {
        switch stage {
        case .seedling:
            return 200...400
        case .vegetative:
            return 400...600
        case .flowering:
            return 600...1_000
        }
    }
}

