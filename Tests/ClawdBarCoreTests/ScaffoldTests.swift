import XCTest
@testable import ClawdBarCore

final class ScaffoldTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(ClawdBar.version, "0.1.0")
    }
}
