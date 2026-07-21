import XCTest
@testable import ClawdBarCore

final class NotificationPlannerTests: XCTestCase {
    func testFiresOnceWhenCrossingThreshold() {
        var planner = NotificationPlanner()
        XCTAssertEqual(planner.update(remaining: 50), [])
        XCTAssertEqual(planner.update(remaining: 18), [.warning20])
        XCTAssertEqual(planner.update(remaining: 15), [])            // 이미 발송됨
        XCTAssertEqual(planner.update(remaining: 4), [.warning5])
        XCTAssertEqual(planner.update(remaining: 3), [])
    }

    func testCrossingMultipleThresholdsFiresOnlyLowest() {
        var planner = NotificationPlanner()
        _ = planner.update(remaining: 80)
        XCTAssertEqual(planner.update(remaining: 2), [.warning5])    // 20과 5를 동시에 지남 → 5만
    }

    func testExhaustedFiresFunMessage() {
        var planner = NotificationPlanner()
        _ = planner.update(remaining: 10)
        let alerts = planner.update(remaining: 0, messageIndex: 0)
        XCTAssertEqual(alerts, [.exhausted(message: NotificationPlanner.exhaustedMessages[0])])
    }

    func testResetRearmsThresholds() {
        var planner = NotificationPlanner()
        _ = planner.update(remaining: 18)                            // warning20 발송됨
        _ = planner.update(remaining: 95)                            // 리셋 (크게 회복)
        XCTAssertEqual(planner.update(remaining: 19), [.warning20])  // 다시 발송 가능
    }
}
