import Foundation

/// Service responsible for computing suggested watering intervals and
/// next watering dates per plant.
///
/// This is a minimal stub aligned with the architecture; detailed
/// heuristics can be refined in later iterations.
final class WateringScheduler {
    struct Parameters {
        let potSizeLiters: Double?
        let substrateType: SubstrateType?
        let stage: PlantStage
    }

    /// Returns a suggested watering interval in days for the given parameters.
    func suggestedIntervalDays(for parameters: Parameters) -> Double {
        // Very simple heuristic: later stories can refine this logic.
        let base: Double
        switch parameters.stage {
        case .seedling: base = 4
        case .vegetative: base = 3
        case .flowering: base = 2.5
        }

        // Adjust for pot size (larger pots -> slightly longer interval).
        let potAdjustment: Double
        if let pot = parameters.potSizeLiters {
            if pot < 5 {
                potAdjustment = -0.5
            } else if pot > 15 {
                potAdjustment = 0.5
            } else {
                potAdjustment = 0
            }
        } else {
            potAdjustment = 0
        }

        // Substrate adjustment (e.g., coco drains faster than soil).
        let substrateAdjustment: Double
        switch parameters.substrateType {
        case .coco:
            substrateAdjustment = -0.5
        case .hydro:
            substrateAdjustment = -1.0
        default:
            substrateAdjustment = 0
        }

        let interval = base + potAdjustment + substrateAdjustment
        return max(1.0, min(interval, 7.0))
    }
}

