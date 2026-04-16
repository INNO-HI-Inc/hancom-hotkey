import AppKit
import os

final class ActiveAppMonitor {
    private static let logger = Logger(subsystem: "com.innohi.hancomhotkey", category: "activeApp")

    private(set) var currentBundleID: String?
    private var observer: NSObjectProtocol?

    func start() {
        currentBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self?.currentBundleID = app.bundleIdentifier
            Self.logger.debug("active app: \(app.bundleIdentifier ?? "unknown")")
        }
    }

    func stop() {
        if let observer = observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            self.observer = nil
        }
    }
}
