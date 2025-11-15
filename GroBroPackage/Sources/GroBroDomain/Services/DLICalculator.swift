import Foundation

/// Calculator for Daily Light Integral (DLI) and recommendations
public final class DLICalculator: Sendable {

    public init() {}

    /// DLI adjustment recommendation
    public enum DLIAdjustment: Sendable {
        case none
        case increase(ppfdOption: Double, photoperiodOption: Double)
        case decrease(ppfdOption: Double, photoperiodOption: Double)
    }

    /// Calculate DLI from PPFD and photoperiod
    /// - Parameters:
    ///   - ppfd: Photosynthetic Photon Flux Density in μmol/m²/s
    ///   - photoperiodHours: Hours of light per day
    /// - Returns: Daily Light Integral in mol/m²/day
    public func calculateDLI(ppfd: Double, photoperiodHours: Double) -> Double {
        // DLI = (PPFD × photoperiod in seconds) / 1,000,000
        return (ppfd * photoperiodHours * 3600) / 1_000_000
    }

    /// Recommend adjustment to reach target DLI
    /// - Parameters:
    ///   - currentDLI: Current DLI value
    ///   - targetDLI: Target DLI range
    ///   - currentPPFD: Current PPFD value
    ///   - currentPhotoperiod: Current photoperiod in hours
    /// - Returns: Adjustment recommendation
    public func recommendAdjustment(
        currentDLI: Double,
        targetDLI: ClosedRange<Double>,
        currentPPFD: Double,
        currentPhotoperiod: Double
    ) -> DLIAdjustment {
        if targetDLI.contains(currentDLI) {
            return .none
        } else if currentDLI < targetDLI.lowerBound {
            // Need to increase DLI
            // Option 1: Increase PPFD (keeping photoperiod constant)
            let newPPFD = (targetDLI.lowerBound * 1_000_000) / (currentPhotoperiod * 3600)

            // Option 2: Increase photoperiod (keeping PPFD constant)
            let newPhotoperiod = (targetDLI.lowerBound * 1_000_000) / (currentPPFD * 3600)

            return .increase(ppfdOption: newPPFD, photoperiodOption: min(newPhotoperiod, 24))
        } else {
            // Need to decrease DLI
            // Option 1: Decrease PPFD (keeping photoperiod constant)
            let newPPFD = (targetDLI.upperBound * 1_000_000) / (currentPhotoperiod * 3600)

            // Option 2: Decrease photoperiod (keeping PPFD constant)
            let newPhotoperiod = (targetDLI.upperBound * 1_000_000) / (currentPPFD * 3600)

            return .decrease(ppfdOption: max(newPPFD, 0), photoperiodOption: max(newPhotoperiod, 0))
        }
    }

    /// Calculate DLI for multiple photoperiods (e.g., 18/6, 20/4, 24/0)
    /// - Parameter ppfd: PPFD value
    /// - Returns: Dictionary of photoperiod string to DLI value
    public func calculateDLIForCommonPhotoperiods(ppfd: Double) -> [String: Double] {
        let photoperiods: [(hours: Double, label: String)] = [
            (12, "12/12"),
            (18, "18/6"),
            (20, "20/4"),
            (24, "24/0")
        ]

        return photoperiods.reduce(into: [:]) { result, period in
            let dli = calculateDLI(ppfd: ppfd, photoperiodHours: period.hours)
            result[period.label] = dli
        }
    }
}
