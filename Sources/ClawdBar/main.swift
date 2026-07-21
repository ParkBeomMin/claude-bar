import AppKit
import SwiftUI
import ClawdBarCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    var state: AppState!
    var statusController: StatusItemController!
    let popover = NSPopover()
    let notifications = NotificationManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        state = AppState()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView(state: state))

        statusController = StatusItemController(state: state) { [weak self] in
            self?.togglePopover()
        }
        notifications.requestPermission()
        state.onAlerts = { [weak self] alerts in
            for alert in alerts { self?.notifications.deliver(alert) }
        }
        state.start()
    }

    private func togglePopover() {
        guard let button = statusController.statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            // NSPopover가 상태바를 덮는 위치에 열리는 문제가 있어,
            // 표시 직후 팝오버 창의 상단을 메뉴바 하단에 맞춰 강제 이동한다.
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      let popWindow = self.popover.contentViewController?.view.window,
                      let barWindow = button.window else { return }
                var frame = popWindow.frame
                let targetTop = barWindow.frame.minY - 4
                if frame.maxY != targetTop {
                    frame.origin.y = targetTop - frame.height
                    popWindow.setFrame(frame, display: true)
                }
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
