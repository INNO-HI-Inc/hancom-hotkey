import AppKit
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let logger = Logger(subsystem: "com.innohi.hancomhotkey", category: "app")

    private let store = KeyMappingStore.shared
    private let permission = PermissionMonitor()
    private let activeApp = ActiveAppMonitor()
    private var remapper: KeyRemapper?
    private var menuBar: MenuBarController?
    private var settingsWindow: SettingsWindow?
    private var onboardingWindow: OnboardingWindow?
    let updater = UpdateController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.logger.info("applicationDidFinishLaunching")

        activeApp.start()
        let remapper = KeyRemapper(store: store, activeApp: activeApp, permission: permission)
        self.remapper = remapper

        menuBar = MenuBarController(
            store: store,
            permission: permission,
            onOpenSettings: { [weak self] in self?.openSettings() },
            onOpenOnboarding: { [weak self] in self?.openOnboarding() },
            onCheckForUpdates: { [weak self] in self?.updater.checkForUpdates() },
            onExportLog: { [weak self] in self?.exportLog() },
            onOpenStyleGuide: { [weak self] in self?.openStyleGuide() },
            onQuit: { NSApp.terminate(nil) }
        )

        permission.start { [weak self] trusted in
            guard let self = self else { return }
            if trusted {
                _ = self.remapper?.start()
            } else {
                self.remapper?.stop()
            }
            self.menuBar?.refreshStatus()
        }

        if !permission.isTrusted {
            openOnboarding()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        remapper?.stop()
        permission.stop()
        activeApp.stop()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return true
    }

    private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindow(store: store, permission: permission, updater: updater)
        }
        settingsWindow?.show()
    }

    private func openOnboarding() {
        if onboardingWindow == nil {
            onboardingWindow = OnboardingWindow(permission: permission) { [weak self] in
                self?.onboardingWindow?.close()
                self?.onboardingWindow = nil
            }
        }
        onboardingWindow?.show()
    }

    private func openStyleGuide() {
        openSettings()
        // Defer so the window is key before selecting the tab.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.settingsWindow?.focusShortcutsTab()
        }
    }

    private func exportLog() {
        LogExporter.presentSaveAndExport(window: settingsWindow?.nsWindow)
    }
}
