import AppKit
import SwiftUI
import ClawdBarCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    var state: AppState!
    var statusController: StatusItemController!
    let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        state = AppState()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView(state: state))

        statusController = StatusItemController(state: state) { [weak self] in
            self?.togglePopover()
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
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
