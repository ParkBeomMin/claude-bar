import XCTest
@testable import ClaudeBarCore

final class UsageResponseTests: XCTestCase {
    // 실제 /api/oauth/usage 응답 축약본 (2026-07-21 캡처)
    let fixture = """
    {
      "five_hour": {"utilization": 38.0, "resets_at": "2026-07-21T02:40:00.074959+00:00",
                    "limit_dollars": null, "used_dollars": null, "remaining_dollars": null},
      "seven_day": {"utilization": 24.0, "resets_at": "2026-07-25T04:00:00.074981+00:00",
                    "limit_dollars": null, "used_dollars": null, "remaining_dollars": null},
      "extra_usage": {"is_enabled": false},
      "limits": [{"kind": "session", "percent": 38, "resets_at": "2026-07-21T02:40:00.074959+00:00"}]
    }
    """

    func testDecodeAndSnapshot() throws {
        let response = try JSONDecoder().decode(UsageResponse.self, from: Data(fixture.utf8))
        let snap = response.snapshot()
        XCTAssertEqual(snap.session.percentUsed, 38.0)
        XCTAssertEqual(snap.weekly.percentUsed, 24.0)
        XCTAssertEqual(snap.displayRemaining, 62.0)
        XCTAssertNotNil(snap.session.resetsAt)
        // 2026-07-21T02:40:00Z (소수점 초는 버림)
        XCTAssertEqual(snap.session.resetsAt!.timeIntervalSince1970, 1784601600, accuracy: 1)
    }

    func testParseDateHandlesMicrosecondsAndOffset() {
        XCTAssertNotNil(UsageResponse.parseDate("2026-07-21T02:40:00.074959+00:00"))
        XCTAssertNotNil(UsageResponse.parseDate("2026-07-21T02:40:00Z"))
        XCTAssertNil(UsageResponse.parseDate(nil))
        XCTAssertNil(UsageResponse.parseDate("not-a-date"))
    }
}
