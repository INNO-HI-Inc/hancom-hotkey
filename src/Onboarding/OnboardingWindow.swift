import AppKit
import SwiftUI

final class OnboardingWindow: NSObject {
    private var window: NSWindow?
    private let permission: PermissionMonitor
    private let onDismiss: () -> Void

    init(permission: PermissionMonitor, onDismiss: @escaping () -> Void) {
        self.permission = permission
        self.onDismiss = onDismiss
    }

    func show() {
        if window == nil {
            let root = OnboardingView(
                permission: permission,
                onFinish: { [weak self] in self?.close() }
            )
            let host = NSHostingController(rootView: root)
            let win = NSWindow(contentViewController: host)
            win.title = "한컴단축키"
            win.styleMask = [.titled, .closable]
            win.isReleasedWhenClosed = false
            win.setContentSize(NSSize(width: 520, height: 560))
            win.center()
            win.delegate = self
            window = win
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.close()
        window = nil
        NSApp.setActivationPolicy(.accessory)
        onDismiss()
    }
}

extension OnboardingWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
