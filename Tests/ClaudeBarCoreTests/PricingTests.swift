import XCTest
@testable import ClaudeBarCore

final class PricingTests: XCTestCase {
    func testKnownModelRates() {
        XCTAssertEqual(Pricing.pricing(forModel: "claude-opus-4-8").input, 5)
        XCTAssertEqual(Pricing.pricing(forModel: "claude-opus-4-8").output, 25)
        XCTAssertEqual(Pricing.pricing(forModel: "claude-opus-4-1-20250805").input, 15)
        XCTAssertEqual(Pricing.pricing(forModel: "claude-sonnet-5").input, 3)
        XCTAssertEqual(Pricing.pricing(forModel: "claude-haiku-4-5-20251001").input, 1)
        XCTAssertEqual(Pricing.pricing(forModel: "claude-fable-5").input, 10)
    }

    func testUnknownModelFallsBackToSonnetRates() {
        XCTAssertEqual(Pricing.pricing(forModel: "claude-future-9").input, 3)
    }

    func testCacheRatesDerivedFromInput() {
        let p = Pricing.pricing(forModel: "claude-opus-4-8")
        XCTAssertEqual(p.cacheWrite, 6.25)  // 5 * 1.25
        XCTAssertEqual(p.cacheRead, 0.5)    // 5 * 0.1
    }

    func testCostCalculation() {
        // opus 4.8: 1M input = $5, 1M output = $25
        let cost = Pricing.cost(model: "claude-opus-4-8",
                                input: 1_000_000, output: 1_000_000,
                                cacheWrite: 0, cacheRead: 0)
        XCTAssertEqual(cost, 30.0, accuracy: 0.001)
    }
}
