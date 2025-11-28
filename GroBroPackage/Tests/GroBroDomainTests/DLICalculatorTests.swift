import Testing
@testable import GroBroDomain

/// Tests for Daily Light Integral calculator
@Suite("DLI Calculator Tests")
struct DLICalculatorTests {

    let calculator = DLICalculator()

    // MARK: - Basic DLI Calculation Tests

    @Test("Calculate DLI for 18/6 photoperiod")
    func calculateDLI18_6() {
        let ppfd = 500.0
        let photoperiod = 18.0
        let dli = calculator.calculateDLI(ppfd: ppfd, photoperiodHours: photoperiod)

        // DLI = (500 * 18 * 3600) / 1,000,000 = 32.4
        #expect(abs(dli - 32.4) < 0.1)
    }

    @Test("Calculate DLI for 12/12 photoperiod")
    func calculateDLI12_12() {
        let ppfd = 800.0
        let photoperiod = 12.0
        let dli = calculator.calculateDLI(ppfd: ppfd, photoperiodHours: photoperiod)

        // DLI = (800 * 12 * 3600) / 1,000,000 = 34.56
        #expect(abs(dli - 34.56) < 0.1)
    }

    @Test("Calculate DLI for 24/0 photoperiod")
    func calculateDLI24_0() {
        let ppfd = 300.0
        let photoperiod = 24.0
        let dli = calculator.calculateDLI(ppfd: ppfd, photoperiodHours: photoperiod)

        // DLI = (300 * 24 * 3600) / 1,000,000 = 25.92
        #expect(abs(dli - 25.92) < 0.1)
    }

    @Test("Zero PPFD results in zero DLI")
    func zeroPPFD() {
        let dli = calculator.calculateDLI(ppfd: 0, photoperiodHours: 18)
        #expect(dli == 0)
    }

    @Test("Zero photoperiod results in zero DLI")
    func zeroPhotoperiod() {
        let dli = calculator.calculateDLI(ppfd: 500, photoperiodHours: 0)
        #expect(dli == 0)
    }

    // MARK: - Common Photoperiod Calculations

    @Test("Calculate DLI for all common photoperiods")
    func commonPhotoperiods() {
        let ppfd = 500.0
        let results = calculator.calculateDLIForCommonPhotoperiods(ppfd: ppfd)

        #expect(results.count == 4)
        #expect(results["12/12"] != nil)
        #expect(results["18/6"] != nil)
        #expect(results["20/4"] != nil)
        #expect(results["24/0"] != nil)

        // Verify calculations
        let dli12 = results["12/12"]!
        let dli18 = results["18/6"]!
        let dli20 = results["20/4"]!
        let dli24 = results["24/0"]!

        // 12/12 should give lowest DLI
        #expect(dli12 < dli18)
        #expect(dli18 < dli20)
        #expect(dli20 < dli24)

        // Verify specific values
        #expect(abs(dli12 - 21.6) < 0.1)  // 500 * 12 * 3600 / 1M
        #expect(abs(dli18 - 32.4) < 0.1)  // 500 * 18 * 3600 / 1M
    }

    // MARK: - DLI Adjustment Recommendations

    @Test("No adjustment needed when DLI is optimal")
    func noAdjustmentNeeded() {
        let currentDLI = 30.0
        let targetDLI = 25.0...40.0
        let adjustment = calculator.recommendAdjustment(
            currentDLI: currentDLI,
            targetDLI: targetDLI,
            currentPPFD: 500,
            currentPhotoperiod: 18
        )

        switch adjustment {
        case .none:
            #expect(Bool(true))
        default:
            #expect(Bool(false), "Expected no adjustment but got \(adjustment)")
        }
    }

    @Test("Increase recommendation when DLI is too low")
    func increaseDLI() {
        let currentDLI = 15.0
        let targetDLI = 25.0...40.0
        let currentPPFD = 300.0
        let currentPhotoperiod = 12.0

        let adjustment = calculator.recommendAdjustment(
            currentDLI: currentDLI,
            targetDLI: targetDLI,
            currentPPFD: currentPPFD,
            currentPhotoperiod: currentPhotoperiod
        )

        switch adjustment {
        case .increase(let ppfdOption, let photoperiodOption):
            // New PPFD should be higher
            #expect(ppfdOption > currentPPFD)
            // New photoperiod should be longer (but capped at 24)
            #expect(photoperiodOption >= currentPhotoperiod)
            #expect(photoperiodOption <= 24)
        default:
            #expect(Bool(false), "Expected increase adjustment but got \(adjustment)")
        }
    }

    @Test("Decrease recommendation when DLI is too high")
    func decreaseDLI() {
        let currentDLI = 50.0
        let targetDLI = 25.0...40.0
        let currentPPFD = 800.0
        let currentPhotoperiod = 18.0

        let adjustment = calculator.recommendAdjustment(
            currentDLI: currentDLI,
            targetDLI: targetDLI,
            currentPPFD: currentPPFD,
            currentPhotoperiod: currentPhotoperiod
        )

        switch adjustment {
        case .decrease(let ppfdOption, let photoperiodOption):
            // New PPFD should be lower
            #expect(ppfdOption < currentPPFD)
            // New photoperiod should be shorter
            #expect(photoperiodOption < currentPhotoperiod)
        default:
            #expect(Bool(false), "Expected decrease adjustment but got \(adjustment)")
        }
    }

    // MARK: - Edge Cases

    @Test("Very high PPFD calculation")
    func highPPFD() {
        let ppfd = 2000.0
        let photoperiod = 12.0
        let dli = calculator.calculateDLI(ppfd: ppfd, photoperiodHours: photoperiod)

        // DLI = (2000 * 12 * 3600) / 1,000,000 = 86.4
        #expect(abs(dli - 86.4) < 0.1)
    }

    @Test("Very low PPFD calculation")
    func lowPPFD() {
        let ppfd = 50.0
        let photoperiod = 18.0
        let dli = calculator.calculateDLI(ppfd: ppfd, photoperiodHours: photoperiod)

        // DLI = (50 * 18 * 3600) / 1,000,000 = 3.24
        #expect(abs(dli - 3.24) < 0.1)
    }
}
