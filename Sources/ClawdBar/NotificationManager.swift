import Foundation
import UserNotifications
import ClawdBarCore

final class NotificationManager {
    static var isAvailable: Bool { Bundle.main.bundleIdentifier != nil }

    func requestPermission() {
        guard Self.isAvailable else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func deliver(_ alert: NotificationPlanner.Alert) {
        guard Self.isAvailable else { return }
        let defaults = UserDefaults.standard
        let content = UNMutableNotificationContent()
        switch alert {
        case .warning20:
            guard defaults.object(forKey: "notify20") == nil || defaults.bool(forKey: "notify20") else { return }
            content.title = "Claude 한도 주의"
            content.body = "잔여량이 20% 아래로 내려갔어요."
        case .warning5:
            guard defaults.object(forKey: "notify5") == nil || defaults.bool(forKey: "notify5") else { return }
            content.title = "Claude 한도 임박!"
            content.body = "잔여량이 5% 아래예요. 마무리할 시간!"
        case .exhausted(let message):
            content.title = "오늘은 여기까지! 🦞"
            content.body = message
        }
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
