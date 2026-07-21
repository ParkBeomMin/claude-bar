import XCTest
@testable import ClaudeBarCore

final class ScaffoldTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(ClaudeBar.version, "0.1.0")
    }
}
