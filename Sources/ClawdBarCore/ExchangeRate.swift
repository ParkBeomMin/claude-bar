import Foundation

public enum ExchangeRate {
    /// USD→KRW 환율. 실패 시 nil (원화 표시 생략).
    public static func fetchUSDKRW(session: URLSession = .shared) async -> Double? {
        struct Response: Decodable { let rates: [String: Double] }
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        guard let (data, _) = try? await session.data(for: request),
              let decoded = try? JSONDecoder().decode(Response.self, from: data) else { return nil }
        return decoded.rates["KRW"]
    }
}
