import Foundation

public struct NotificationPlanner {
    public enum Alert: Equatable {
        case warning20
        case warning5
        case exhausted(message: String)
    }

    public static let exhaustedMessages = [
        "오늘 몫은 다 썼어요! 이제 퇴근하세요 🦞",
        "Clawd도 쉬고 싶대요. 내일 만나요! 👋",
        "한도 끝! 잠깐 산책 어때요? 🚶",
        "수고했어요, 오늘은 여기까지! 🌙",
    ]

    private static let thresholds = [20, 5, 0]

    private var fired = Set<Int>()
    private var lastRemaining: Double?

    public init() {}

    public mutating func update(remaining: Double, messageIndex: Int? = nil) -> [Alert] {
        defer { lastRemaining = remaining }

        // 잔여량이 10%p 이상 회복되면 한도 리셋으로 간주하고 재활성화
        if let last = lastRemaining, remaining > last + 10 {
            fired.removeAll()
        }

        let crossed = Self.thresholds.filter { remaining <= Double($0) && !fired.contains($0) }
        guard let lowest = crossed.min() else { return [] }
        fired.formUnion(crossed)

        switch lowest {
        case 20: return [.warning20]
        case 5: return [.warning5]
        default:
            let index = messageIndex ?? Int.random(in: 0..<Self.exhaustedMessages.count)
            return [.exhausted(message: Self.exhaustedMessages[index % Self.exhaustedMessages.count])]
        }
    }
}
