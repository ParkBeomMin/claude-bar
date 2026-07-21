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
            // NSStatusBarButton은 flipped 좌표계라 .minY가 위쪽 가장자리가 되어
            // 팝오버가 메뉴바를 덮는다. .maxY가 메뉴바 아래로 열린다.
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
