import Testing
@testable import GroBroDomain

@Suite("Environmental Status Tests")
struct EnvironmentalStatusTests {
    @Test("Optimal conditions for seedling")
    func testOptimalSeedling() {
        let status = EnvironmentalStatus.calculate(
            temp: 75,
            humidity: 70,
            vpd: 0.6,
            stage: .seedling
        )

        #expect(status == .optimal)
    }

    @Test("Optimal conditions for vegetative")
    func testOptimalVegetative() {
        let status = EnvironmentalStatus.calculate(
            temp: 77,
            humidity: 60,
            vpd: 1.0,
            stage: .vegetative
        )

        #expect(status == .optimal)
    }

    @Test("Optimal conditions for flowering")
    func testOptimalFlowering() {
        let status = EnvironmentalStatus.calculate(
            temp: 72,
            humidity: 50,
            vpd: 1.2,
            stage: .flowering
        )

        #expect(status == .optimal)
    }

    @Test("Critical high temperature")
    func testCriticalHighTemp() {
        let status = EnvironmentalStatus.calculate(
            temp: 96,
            humidity: 60,
            vpd: 1.0,
            stage: .vegetative
        )

        #expect(status == .critical)
    }

    @Test("Critical low temperature")
    func testCriticalLowTemp() {
        let status = EnvironmentalStatus.calculate(
            temp: 55,
            humidity: 60,
            vpd: 1.0,
            stage: .vegetative
        )

        #expect(status == .critical)
    }

    @Test("Critical low humidity")
    func testCriticalLowHumidity() {
        let status = EnvironmentalStatus.calculate(
            temp: 75,
            humidity: 15,
            vpd: 2.0,
            stage: .vegetative
        )

        #expect(status == .critical)
    }

    @Test("Critical high humidity")
    func testCriticalHighHumidity() {
        let status = EnvironmentalStatus.calculate(
            temp: 75,
            humidity: 90,
            vpd: 0.1,
            stage: .vegetative
        )

        #expect(status == .critical)
    }

    @Test("Caution - slightly off optimal")
    func testCaution() {
        let status = EnvironmentalStatus.calculate(
            temp: 88,
            humidity: 45,
            vpd: 1.6,
            stage: .vegetative
        )

        #expect(status == .caution)
    }

    @Test("VPD calculation accuracy")
    func testVPDCalculation() {
        let vpd = EnvironmentalData.calculateVPD(
            temperatureFahrenheit: 75,
            humidityPercent: 60
        )

        // At 75°F (23.9°C) and 60% RH, VPD should be ~1.2 kPa
        #expect(vpd > 1.1 && vpd < 1.3)
    }
}
