import AppKit
import ClawdBarCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    var state: AppState!
    var statusController: StatusItemController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        state = AppState()
        statusController = StatusItemController(state: state) {
            // 팝오버는 Task 10에서 연결. 임시로 수동 새로고침.
            Task { @MainActor in await self.state.refreshUsage() }
        }
        state.start()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
