import Foundation
import Security

public protocol TokenProviding {
    func accessToken() throws -> String
}

public struct KeychainTokenProvider: TokenProviding {
    public init() {}

    public func accessToken() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            throw ClaudeBarError.keychainUnavailable(status)
        }
        return try Self.parseCredentials(data)
    }

    static func parseCredentials(_ data: Data) throws -> String {
        struct Credentials: Decodable {
            struct OAuth: Decodable { let accessToken: String }
            let claudeAiOauth: OAuth
        }
        guard let creds = try? JSONDecoder().decode(Credentials.self, from: data) else {
            throw ClaudeBarError.credentialsMalformed
        }
        return creds.claudeAiOauth.accessToken
    }
}

public protocol UsageProviding {
    func fetch() async throws -> UsageSnapshot
}

public final class UsageFetcher: UsageProviding {
    let tokenProvider: TokenProviding
    let session: URLSession
    /// 키체인 접근 팝업을 실행당 1회로 줄이기 위해 토큰을 메모리에 캐시한다.
    private var cachedToken: String?

    public init(tokenProvider: TokenProviding = KeychainTokenProvider(), session: URLSession = .shared) {
        self.tokenProvider = tokenProvider
        self.session = session
    }

    public func fetch() async throws -> UsageSnapshot {
        let token: String
        if let cachedToken {
            token = cachedToken
        } else {
            token = try tokenProvider.accessToken()
            cachedToken = token
        }
        do {
            return try await request(token: token)
        } catch ClaudeBarError.apiError(let code) where code == 401 {
            // 토큰이 갱신된 경우: 키체인에서 새로 읽어 1회 재시도
            let fresh = try tokenProvider.accessToken()
            cachedToken = fresh
            return try await request(token: fresh)
        }
    }

    private func request(token: String) async throws -> UsageSnapshot {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ClaudeBarError.apiError((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        return try JSONDecoder().decode(UsageResponse.self, from: data).snapshot()
    }
}
