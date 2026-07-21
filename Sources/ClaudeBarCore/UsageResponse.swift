import Foundation

public struct UsageResponse: Decodable {
    public struct Window: Decodable {
        public let utilization: Double?
        public let resets_at: String?
    }

    public let five_hour: Window
    public let seven_day: Window

    public func snapshot() -> UsageSnapshot {
        UsageSnapshot(
            session: UsageWindow(
                percentUsed: five_hour.utilization ?? 0,
                resetsAt: Self.parseDate(five_hour.resets_at)
            ),
            weekly: UsageWindow(
                percentUsed: seven_day.utilization ?? 0,
                resetsAt: Self.parseDate(seven_day.resets_at)
            )
        )
    }

    /// ISO8601DateFormatter는 6자리 마이크로초를 지원하지 않으므로 소수점 초를 제거 후 파싱한다.
    public static func parseDate(_ s: String?) -> Date? {
        guard var s else { return nil }
        if let dotRange = s.range(of: #"\.\d+"#, options: .regularExpression) {
            s.removeSubrange(dotRange)
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: s)
    }
}
