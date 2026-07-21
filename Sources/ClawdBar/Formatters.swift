import Foundation

enum Formatters {
    static func tokens(_ n: Int) -> String {
        switch n {
        case 1_000_000...: return String(format: "%.1fM", Double(n) / 1_000_000)
        case 1_000...: return String(format: "%.1fK", Double(n) / 1_000)
        default: return "\(n)"
        }
    }

    static func usd(_ d: Double) -> String {
        String(format: "$%.2f", d)
    }

    static func timeUntil(_ date: Date?) -> String {
        guard let date else { return "—" }
        let seconds = Int(date.timeIntervalSinceNow)
        guard seconds > 0 else { return "곧 리셋" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours >= 24 {
            let days = hours / 24
            return "\(days)일 \(hours % 24)시간 후"
        }
        if hours > 0 { return "\(hours)시간 \(minutes)분 후" }
        return "\(minutes)분 후"
    }
}
