import Foundation
import Security

public protocol TokenProviding {
    func accessToken() throws -> String
}

public struct KeychainTokenProvider: TokenProviding {
    public init() {}

    public func accessToken() throws -> String {
        // 같은 서비스명("Claude Code-credentials") 항목이 여러 개일 수 있다.
        // 1단계: 메타데이터만 조회(암호 프롬프트 없음)해 최신 수정순으로 정렬하고,
        // 2단계: 최신 항목부터 하나씩 실제 데이터를 읽는다(프롬프트는 읽는 항목에만 뜸).
        let attrQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnAttributes as String: true,
            kSecReturnPersistentRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]
        var result: CFTypeRef?
        let listStatus = SecItemCopyMatching(attrQuery as CFDictionary, &result)
        guard listStatus == errSecSuccess else {
            throw ClaudeBarError.keychainUnavailable(listStatus)
        }

        let entries: [[String: Any]]
        if let array = result as? [[String: Any]] {
            entries = array
        } else if let single = result as? [String: Any] {
            entries = [single]
        } else {
            throw ClaudeBarError.keychainUnavailable(errSecItemNotFound)
        }

        let sorted = entries.sorted { a, b in
            let da = a[kSecAttrModificationDate as String] as? Date ?? .distantPast
            let db = b[kSecAttrModificationDate as String] as? Date ?? .distantPast
            return da > db
        }

        var lastStatus: OSStatus = errSecItemNotFound
        var sawMalformed = false
        for entry in sorted {
            guard let ref = entry[kSecValuePersistentRef as String] else { continue }
            let dataQuery: [String: Any] = [
                kSecValuePersistentRef as String: ref,
                kSecReturnData as String: true,
            ]
            var item: CFTypeRef?
            let status = SecItemCopyMatching(dataQuery as CFDictionary, &item)
            guard status == errSecSuccess, let data = item as? Data else {
                lastStatus = status
                continue
            }
            if let token = try? Self.parseCredentials(data) {
                return token
            }
            sawMalformed = true
        }
        if sawMalformed { throw ClaudeBarError.credentialsMalformed }
        throw ClaudeBarError.keychainUnavailable(lastStatus)
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
