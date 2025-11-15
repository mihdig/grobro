import Foundation

/// Provides comprehensive light recommendations including photoperiod, PPFD, DLI, and spectrum
public final class LightRecommendationEngine: Sendable {

    public init() {}

    /// Get complete light recommendation for a given stage and light type
    /// - Parameters:
    ///   - stage: Current growth stage
    ///   - lightType: Type of light source
    /// - Returns: Complete light recommendation
    public func recommendation(
        for stage: PlantStage,
        lightType: LightType
    ) -> LightRecommendation {
        switch stage {
        case .seedling:
            return LightRecommendation(
                stage: .seedling,
                lightType: lightType,
                hoursOn: 18,
                hoursOff: 6,
                ppfdRange: adjustPPFDForLightType(200...400, lightType),
                dliTarget: 15...25,
                spectrum: SpectrumRecommendation(
                    kelvin: 4000...5000,
                    bluePercentage: 50,
                    redPercentage: 30,
                    description: "Balanced spectrum for early growth"
                )
            )

        case .vegetative:
            return LightRecommendation(
                stage: .vegetative,
                lightType: lightType,
                hoursOn: 18,
                hoursOff: 6,
                ppfdRange: adjustPPFDForLightType(400...600, lightType),
                dliTarget: 25...40,
                spectrum: SpectrumRecommendation(
                    kelvin: 5000...6500,
                    bluePercentage: 60,
                    redPercentage: 20,
                    description: "Higher blue for vegetative growth and tight node spacing"
                )
            )

        case .flowering:
            return LightRecommendation(
                stage: .flowering,
                lightType: lightType,
                hoursOn: 12,
                hoursOff: 12,
                ppfdRange: adjustPPFDForLightType(600...1000, lightType),
                dliTarget: 35...50,
                spectrum: SpectrumRecommendation(
                    kelvin: 2700...3000,
                    bluePercentage: 20,
                    redPercentage: 60,
                    description: "Higher red spectrum for flower development"
                )
            )

        case .drying, .curing:
            // No light needed for drying and curing
            return LightRecommendation(
                stage: stage,
                lightType: lightType,
                hoursOn: 0,
                hoursOff: 24,
                ppfdRange: 0...0,
                dliTarget: 0...0,
                spectrum: nil
            )
        }
    }

    /// Adjust PPFD range based on light type efficiency
    /// - Parameters:
    ///   - basePPFD: Base PPFD range (optimized for LED)
    ///   - lightType: Type of light source
    /// - Returns: Adjusted PPFD range
    private func adjustPPFDForLightType(
        _ basePPFD: ClosedRange<Double>,
        _ lightType: LightType
    ) -> ClosedRange<Double> {
        switch lightType {
        case .fullSpectrumLED, .whiteLED:
            // LED is baseline (most efficient)
            return basePPFD

        case .hps, .mh:
            // HPS/MH less efficient, plants can handle slightly lower PPFD
            return (basePPFD.lowerBound * 0.8)...(basePPFD.upperBound * 0.8)

        case .cfl:
            // CFL less penetrating, may need higher PPFD at canopy
            return (basePPFD.lowerBound * 1.2)...(basePPFD.upperBound * 1.2)

        case .cmh:
            // CMH good efficiency, slightly less than LED
            return (basePPFD.lowerBound * 0.9)...(basePPFD.upperBound * 0.9)

        case .sunlight:
            // Natural sunlight varies widely
            return basePPFD
        }
    }

    /// Validate a custom light schedule against best practices
    /// - Parameters:
    ///   - schedule: Custom schedule to validate
    ///   - stage: Current growth stage
    /// - Returns: Validation result with warnings if any
    public func validateSchedule(
        _ schedule: LightSchedule,
        for stage: PlantStage
    ) -> ScheduleValidation {
        let recommendation = self.recommendation(for: stage, lightType: .fullSpectrumLED)

        var warnings: [String] = []

        // Check if schedule is valid (24 hours total)
        guard schedule.isValid else {
            warnings.append("Invalid schedule: Total hours must equal 24")
            return ScheduleValidation(isValid: false, warnings: warnings)
        }

        // Check if photoperiod deviates significantly from recommendation
        let hoursDeviation = abs(schedule.hoursOn - recommendation.hoursOn)
        if hoursDeviation > 2 {
            if schedule.hoursOn < recommendation.hoursOn {
                warnings.append("Light period is \(hoursDeviation) hours shorter than recommended. This may slow growth.")
            } else {
                warnings.append("Light period is \(hoursDeviation) hours longer than recommended. Risk of stress.")
            }
        }

        // Check minimum light for vegetative growth
        if stage == .vegetative || stage == .seedling {
            if schedule.hoursOn < 12 {
                warnings.append("Vegetative plants need at least 12 hours of light to prevent flowering")
            }
        }

        // Check flowering photoperiod
        if stage == .flowering {
            if schedule.hoursOn > 13 {
                warnings.append("Flowering plants typically need 12/12 or less to continue flowering")
            }
        }

        return ScheduleValidation(
            isValid: warnings.isEmpty,
            warnings: warnings
        )
    }

    /// Schedule validation result
    public struct ScheduleValidation: Sendable {
        public let isValid: Bool
        public let warnings: [String]

        public init(isValid: Bool, warnings: [String]) {
            self.isValid = isValid
            self.warnings = warnings
        }
    }
}
