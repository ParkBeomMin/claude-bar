import XCTest
@testable import ClaudeBarCore

final class CredentialsTests: XCTestCase {
    func testParseCredentials() throws {
        let json = #"{"claudeAiOauth":{"accessToken":"sk-ant-oat01-TEST","refreshToken":"rt","expiresAt":1}}"#
        let token = try KeychainTokenProvider.parseCredentials(Data(json.utf8))
        XCTAssertEqual(token, "sk-ant-oat01-TEST")
    }

    func testParseCredentialsMalformed() {
        XCTAssertThrowsError(try KeychainTokenProvider.parseCredentials(Data("{}".utf8))) { error in
            guard case ClaudeBarError.credentialsMalformed = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }
}
