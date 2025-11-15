import Foundation

/// Service for calculating nutrient dosages and conversions
@MainActor
public final class NutrientCalculator: Sendable {

    public init() {}

    // MARK: - PPM/EC/TDS Conversions

    /// Convert EC (mS/cm) to PPM using 500 scale (US/Hanna standard)
    public func ecToPPM500(_ ec: Double) -> Double {
        ec * 500.0
    }

    /// Convert EC (mS/cm) to PPM using 700 scale (Truncheon/Eutech)
    public func ecToPPM700(_ ec: Double) -> Double {
        ec * 700.0
    }

    /// Convert PPM to EC (assumes 500 scale by default)
    public func ppmToEC(_ ppm: Double, scale: PPMScale = .scale500) -> Double {
        switch scale {
        case .scale500:
            return ppm / 500.0
        case .scale700:
            return ppm / 700.0
        }
    }

    // MARK: - Dosage Scaling

    /// Scale dosage from per-gallon to actual reservoir volume
    /// - Parameters:
    ///   - dosagePerGallon: Dosage amount per gallon (ml)
    ///   - reservoirVolume: Target reservoir volume
    /// - Returns: Scaled dosage amount in ml
    public func scaleDosage(
        dosagePerGallon: Double,
        for reservoirVolume: ReservoirVolume
    ) -> Double {
        let gallons = reservoirVolume.gallons
        return dosagePerGallon * gallons
    }

    /// Calculate total dosage for a nutrient mix
    /// - Parameters:
    ///   - products: List of products with per-gallon dosages
    ///   - reservoirVolume: Target reservoir volume
    /// - Returns: Array of dosages in ml
    public func calculateDosages(
        for products: [(product: NutrientProduct, dosagePerGallon: Double)],
        reservoirVolume: ReservoirVolume
    ) -> [NutrientDosage] {
        products.map { product, dosagePerGallon in
            let scaledAmount = scaleDosage(
                dosagePerGallon: dosagePerGallon,
                for: reservoirVolume
            )
            return NutrientDosage(
                productId: product.id,
                productName: product.name,
                amount: scaledAmount,
                unit: .milliliters
            )
        }
    }

    // MARK: - PPM Estimation

    /// Estimate PPM from nutrient dosages (simplified calculation)
    /// This is a rough approximation. Actual PPM depends on product concentration.
    /// - Parameters:
    ///   - dosages: List of nutrient dosages
    ///   - reservoirVolume: Reservoir volume
    /// - Returns: Estimated PPM (500 scale)
    public func estimatePPM(
        from dosages: [NutrientDosage],
        reservoirVolume: ReservoirVolume
    ) -> Double {
        // Simplified: assume ~50 PPM per ml of nutrient per gallon
        // This varies greatly by product, so this is just an estimate
        let totalML = dosages.reduce(0.0) { $0 + $1.amountInMilliliters }
        let gallons = reservoirVolume.gallons

        guard gallons > 0 else { return 0 }

        let mlPerGallon = totalML / gallons
        return mlPerGallon * 50.0 // Rough approximation
    }

    // MARK: - Growth Stage Recommendations

    /// Get recommended PPM range for a plant stage
    /// - Parameter stage: Current plant growth stage
    /// - Returns: Recommended PPM range (500 scale)
    public func recommendedPPMRange(for stage: PlantStage) -> ClosedRange<Double> {
        switch stage {
        case .seedling:
            return 100...250
        case .vegetative:
            return 400...800
        case .flowering:
            return 800...1400
        }
    }

    /// Check if PPM is within recommended range for stage
    /// - Parameters:
    ///   - ppm: Current PPM value
    ///   - stage: Plant growth stage
    /// - Returns: Status of PPM (optimal, low, high)
    public func checkPPMStatus(
        _ ppm: Double,
        for stage: PlantStage
    ) -> NutrientStatus {
        let range = recommendedPPMRange(for: stage)

        if ppm < range.lowerBound {
            return .low
        } else if ppm > range.upperBound {
            return .high
        } else {
            return .optimal
        }
    }
}

// MARK: - Supporting Types

/// PPM measurement scale
public enum PPMScale: Sendable {
    case scale500  // US/Hanna standard
    case scale700  // Truncheon/Eutech
}

/// Nutrient level status
public enum NutrientStatus: Sendable {
    case low
    case optimal
    case high

    public var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .optimal:
            return "Optimal"
        case .high:
            return "High"
        }
    }

    public var warningMessage: String? {
        switch self {
        case .low:
            return "PPM is below recommended range. Consider increasing nutrient dosage."
        case .optimal:
            return nil
        case .high:
            return "PPM is above recommended range. Risk of nutrient burn. Consider reducing dosage."
        }
    }
}
