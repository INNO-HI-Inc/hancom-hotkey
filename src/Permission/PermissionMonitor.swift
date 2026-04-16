import AppKit
import ApplicationServices
import Combine
import os

final class PermissionMonitor: ObservableObject {
    private static let logger = Logger(subsystem: "com.innohi.hancomhotkey", category: "permission")

    @Published private(set) var isTrusted: Bool = false

    private var timer: Timer?
    private var onChange: ((Bool) -> Void)?

    init() {
        isTrusted = AXIsProcessTrusted()
    }

    func start(onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange
        onChange(isTrusted)
        startPolling()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func requestAccessWithPrompt() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        startPolling()
    }

    func openSystemSettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
        startPolling()
    }

    private func startPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let trusted = AXIsProcessTrusted()
            if self.isTrusted != trusted {
                DispatchQueue.main.async {
                    self.isTrusted = trusted
                    self.onChange?(trusted)
                    Self.logger.info("permission changed: \(trusted)")
                }
            }
        }
    }
}
