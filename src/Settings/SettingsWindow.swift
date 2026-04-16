import AppKit
import SwiftUI

final class SettingsWindow: NSObject {
    private(set) var nsWindow: NSWindow?
    private let store: KeyMappingStore
    private let permission: PermissionMonitor
    private let updater: UpdateController
    private let tabSelection = TabSelection()

    init(store: KeyMappingStore, permission: PermissionMonitor, updater: UpdateController) {
        self.store = store
        self.permission = permission
        self.updater = updater
    }

    func show() {
        if nsWindow == nil {
            let root = SettingsRootView()
                .environmentObject(store)
                .environmentObject(permission)
                .environmentObject(UpdaterViewModel(updater: updater))
                .environmentObject(tabSelection)
            let host = NSHostingController(rootView: root)
            let win = NSWindow(contentViewController: host)
            win.title = "한컴단축키 설정"
            win.styleMask = [.titled, .closable, .miniaturizable]
            win.isReleasedWhenClosed = false
            win.setContentSize(NSSize(width: 640, height: 500))
            win.center()
            win.delegate = self
            nsWindow = win
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        nsWindow?.makeKeyAndOrderFront(nil)
    }

    func focusShortcutsTab() {
        show()
        tabSelection.current = .shortcuts
    }
}

extension SettingsWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

final class TabSelection: ObservableObject {
    enum Tab: String { case general, shortcuts, about }
    @Published var current: Tab = .general
}

final class UpdaterViewModel: ObservableObject {
    let updater: UpdateController
    @Published var autoCheck: Bool {
        didSet { updater.automaticallyChecksForUpdates = autoCheck }
    }

    init(updater: UpdateController) {
        self.updater = updater
        self.autoCheck = updater.automaticallyChecksForUpdates
    }

    func checkNow() {
        updater.checkForUpdates()
    }
}
