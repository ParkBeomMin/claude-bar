import XCTest
@testable import ClawdBarCore

final class ModelsTests: XCTestCase {
    func testPercentRemaining() {
        XCTAssertEqual(UsageWindow(percentUsed: 38, resetsAt: nil).percentRemaining, 62)
        XCTAssertEqual(UsageWindow(percentUsed: 120, resetsAt: nil).percentRemaining, 0)
    }

    func testDisplayRemainingIsMinOfWindows() {
        let snap = UsageSnapshot(
            session: UsageWindow(percentUsed: 38, resetsAt: nil),
            weekly: UsageWindow(percentUsed: 76, resetsAt: nil)
        )
        XCTAssertEqual(snap.displayRemaining, 24)
    }

    func testFaceStageMapping() {
        XCTAssertEqual(FaceStage(remaining: 100), .calm)
        XCTAssertEqual(FaceStage(remaining: 60), .calm)
        XCTAssertEqual(FaceStage(remaining: 59.9), .smile)
        XCTAssertEqual(FaceStage(remaining: 40), .smile)
        XCTAssertEqual(FaceStage(remaining: 39.9), .worried)
        XCTAssertEqual(FaceStage(remaining: 20), .worried)
        XCTAssertEqual(FaceStage(remaining: 19.9), .struggling)
        XCTAssertEqual(FaceStage(remaining: 5), .struggling)
        XCTAssertEqual(FaceStage(remaining: 4.9), .knockedOut)
        XCTAssertEqual(FaceStage(remaining: 0), .knockedOut)
        XCTAssertEqual(FaceStage(remaining: nil), .unknown)
    }
}
