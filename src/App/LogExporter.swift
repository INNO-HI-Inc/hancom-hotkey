import AppKit
import Foundation

/// Collects recent app logs from the unified logging system and writes them to a file.
enum LogExporter {
    static func presentSaveAndExport(window: NSWindow?) {
        let panel = NSSavePanel()
        panel.title = "로그 저장"
        panel.nameFieldStringValue = "HancomHotkey-log-\(isoTimestamp()).txt"
        panel.allowedContentTypes = []
        panel.canCreateDirectories = true

        let completion: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .OK, let url = panel.url else { return }
            exportLogs(to: url)
        }

        if let window = window {
            panel.beginSheetModal(for: window, completionHandler: completion)
        } else {
            completion(panel.runModal())
        }
    }

    private static func exportLogs(to url: URL) {
        let process = Process()
        process.launchPath = "/usr/bin/log"
        process.arguments = [
            "show",
            "--predicate", "subsystem == \"com.innohi.hancomhotkey\"",
            "--info",
            "--last", "1h",
        ]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            try data.write(to: url)

            let alert = NSAlert()
            alert.messageText = "로그 저장 완료"
            alert.informativeText = "경로: \(url.path)"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Finder에서 보기")
            alert.addButton(withTitle: "닫기")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    private static func isoTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}
