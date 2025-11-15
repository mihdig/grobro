import Foundation

/// Provides optimal light distance recommendations based on light type and plant stage
public final class LightDistanceRecommendationEngine: Sendable {

    public init() {}

    /// Status of the current light distance relative to optimal range
    public enum DistanceStatus: Sendable {
        case tooClose
        case optimal
        case tooFar
    }

    /// Recommendation result with status and actionable message
    public struct DistanceRecommendation: Sendable {
        public let status: DistanceStatus
        public let message: String
        public let optimalRange: ClosedRange<Double>

        public init(status: DistanceStatus, message: String, optimalRange: ClosedRange<Double>) {
            self.status = status
            self.message = message
            self.optimalRange = optimalRange
        }
    }

    /// Evaluate current light distance and provide recommendation
    /// - Parameters:
    ///   - distance: Current distance in inches
    ///   - lightType: Type of light source
    ///   - stage: Current growth stage
    /// - Returns: Recommendation with status and message
    public func evaluate(
        distance: Double,
        lightType: LightType,
        stage: PlantStage
    ) -> DistanceRecommendation {
        let optimal = optimalRange(for: lightType, stage: stage)

        if distance < optimal.lowerBound {
            let diff = optimal.lowerBound - distance
            return DistanceRecommendation(
                status: .tooClose,
                message: "Move light up \(Int(diff.rounded()))\" to avoid light burn",
                optimalRange: optimal
            )
        } else if distance > optimal.upperBound {
            let diff = distance - optimal.upperBound
            return DistanceRecommendation(
                status: .tooFar,
                message: "Move light down \(Int(diff.rounded()))\" for better growth",
                optimalRange: optimal
            )
        } else {
            return DistanceRecommendation(
                status: .optimal,
                message: "Perfect distance! 🎯",
                optimalRange: optimal
            )
        }
    }

    /// Get optimal distance range for given light type and stage
    /// - Parameters:
    ///   - lightType: Type of light source
    ///   - stage: Current growth stage
    /// - Returns: Optimal distance range in inches
    public func optimalRange(
        for lightType: LightType,
        stage: PlantStage
    ) -> ClosedRange<Double> {
        switch (lightType, stage) {
        // LED distances
        case (.fullSpectrumLED, .seedling), (.whiteLED, .seedling):
            return 24...30
        case (.fullSpectrumLED, .vegetative), (.whiteLED, .vegetative):
            return 18...24
        case (.fullSpectrumLED, .flowering), (.whiteLED, .flowering):
            return 12...18

        // HPS distances
        case (.hps, .seedling):
            return 30...36
        case (.hps, .vegetative):
            return 24...30
        case (.hps, .flowering):
            return 18...24

        // MH distances (similar to HPS)
        case (.mh, .seedling):
            return 30...36
        case (.mh, .vegetative):
            return 24...30
        case (.mh, .flowering):
            return 18...24

        // CMH distances
        case (.cmh, .seedling):
            return 30...36
        case (.cmh, .vegetative):
            return 24...30
        case (.cmh, .flowering):
            return 18...24

        // CFL distances (much closer due to lower intensity)
        case (.cfl, .seedling), (.cfl, .vegetative), (.cfl, .flowering):
            return 6...12

        // Sunlight (natural light - distance doesn't apply)
        case (.sunlight, _):
            return 0...0

        // Drying and curing stages (no light needed)
        case (_, .drying), (_, .curing):
            return 0...0
        }
    }
}
