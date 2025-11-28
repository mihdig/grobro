import Testing
@testable import GroBroDomain

/// Tests for light distance recommendation engine
@Suite("Light Distance Recommendation Engine Tests")
struct LightDistanceRecommendationEngineTests {

    let engine = LightDistanceRecommendationEngine()

    // MARK: - LED Distance Tests

    @Test("LED seedling optimal range is 24-30 inches")
    func ledSeedlingRange() {
        let range = engine.optimalRange(for: .fullSpectrumLED, stage: .seedling)
        #expect(range == 24...30)
    }

    @Test("LED vegetative optimal range is 18-24 inches")
    func ledVegetativeRange() {
        let range = engine.optimalRange(for: .fullSpectrumLED, stage: .vegetative)
        #expect(range == 18...24)
    }

    @Test("LED flowering optimal range is 12-18 inches")
    func ledFloweringRange() {
        let range = engine.optimalRange(for: .fullSpectrumLED, stage: .flowering)
        #expect(range == 12...18)
    }

    // MARK: - HPS Distance Tests

    @Test("HPS seedling optimal range is 30-36 inches")
    func hpsSeedlingRange() {
        let range = engine.optimalRange(for: .hps, stage: .seedling)
        #expect(range == 30...36)
    }

    @Test("HPS vegetative optimal range is 24-30 inches")
    func hpsVegetativeRange() {
        let range = engine.optimalRange(for: .hps, stage: .vegetative)
        #expect(range == 24...30)
    }

    @Test("HPS flowering optimal range is 18-24 inches")
    func hpsFloweringRange() {
        let range = engine.optimalRange(for: .hps, stage: .flowering)
        #expect(range == 18...24)
    }

    // MARK: - CFL Distance Tests

    @Test("CFL optimal range is 6-12 inches for all stages")
    func cflRange() {
        #expect(engine.optimalRange(for: .cfl, stage: .seedling) == 6...12)
        #expect(engine.optimalRange(for: .cfl, stage: .vegetative) == 6...12)
        #expect(engine.optimalRange(for: .cfl, stage: .flowering) == 6...12)
    }

    // MARK: - Recommendation Status Tests

    @Test("Distance within range returns optimal status")
    func optimalDistance() {
        let recommendation = engine.evaluate(
            distance: 20,
            lightType: .fullSpectrumLED,
            stage: .vegetative
        )

        #expect(recommendation.status == .optimal)
        #expect(recommendation.message.contains("Perfect"))
    }

    @Test("Distance below range returns too close status")
    func tooCloseDistance() {
        let recommendation = engine.evaluate(
            distance: 10,
            lightType: .fullSpectrumLED,
            stage: .vegetative
        )

        #expect(recommendation.status == .tooClose)
        #expect(recommendation.message.contains("Move light up"))
    }

    @Test("Distance above range returns too far status")
    func tooFarDistance() {
        let recommendation = engine.evaluate(
            distance: 30,
            lightType: .fullSpectrumLED,
            stage: .vegetative
        )

        #expect(recommendation.status == .tooFar)
        #expect(recommendation.message.contains("Move light down"))
    }

    // MARK: - Special Cases

    @Test("Drying stage has no light requirement")
    func dryingStage() {
        let range = engine.optimalRange(for: .fullSpectrumLED, stage: .drying)
        #expect(range == 0...0)
    }

    @Test("Curing stage has no light requirement")
    func curingStage() {
        let range = engine.optimalRange(for: .fullSpectrumLED, stage: .curing)
        #expect(range == 0...0)
    }

    @Test("Sunlight type has no distance recommendation")
    func sunlightType() {
        let range = engine.optimalRange(for: .sunlight, stage: .vegetative)
        #expect(range == 0...0)
    }

    // MARK: - CMH and MH Tests

    @Test("MH distances match HPS recommendations")
    func mhDistances() {
        #expect(engine.optimalRange(for: .mh, stage: .seedling) == 30...36)
        #expect(engine.optimalRange(for: .mh, stage: .vegetative) == 24...30)
        #expect(engine.optimalRange(for: .mh, stage: .flowering) == 18...24)
    }

    @Test("CMH distances match HPS recommendations")
    func cmhDistances() {
        #expect(engine.optimalRange(for: .cmh, stage: .seedling) == 30...36)
        #expect(engine.optimalRange(for: .cmh, stage: .vegetative) == 24...30)
        #expect(engine.optimalRange(for: .cmh, stage: .flowering) == 18...24)
    }
}
