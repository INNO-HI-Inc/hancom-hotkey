import AppKit
import Combine

final class MenuBarController {
    private let statusItem: NSStatusItem
    private let store: KeyMappingStore
    private let permission: PermissionMonitor
    private let onOpenSettings: () -> Void
    private let onOpenOnboarding: () -> Void
    private let onCheckForUpdates: () -> Void
    private let onExportLog: () -> Void
    private let onOpenStyleGuide: () -> Void
    private let onQuit: () -> Void

    private var cancellables: Set<AnyCancellable> = []

    init(
        store: KeyMappingStore,
        permission: PermissionMonitor,
        onOpenSettings: @escaping () -> Void,
        onOpenOnboarding: @escaping () -> Void,
        onCheckForUpdates: @escaping () -> Void,
        onExportLog: @escaping () -> Void,
        onOpenStyleGuide: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.store = store
        self.permission = permission
        self.onOpenSettings = onOpenSettings
        self.onOpenOnboarding = onOpenOnboarding
        self.onCheckForUpdates = onCheckForUpdates
        self.onExportLog = onExportLog
        self.onOpenStyleGuide = onOpenStyleGuide
        self.onQuit = onQuit

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureButton()
        rebuildMenu()

        store.$isEnabled.sink { [weak self] _ in
            DispatchQueue.main.async { self?.rebuildMenu(); self?.refreshStatus() }
        }.store(in: &cancellables)

        store.$rules.sink { [weak self] _ in
            DispatchQueue.main.async { self?.rebuildMenu() }
        }.store(in: &cancellables)

        permission.$isTrusted.sink { [weak self] _ in
            DispatchQueue.main.async { self?.rebuildMenu(); self?.refreshStatus() }
        }.store(in: &cancellables)
    }

    func refreshStatus() {
        configureButton()
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        let symbolName: String
        if !permission.isTrusted {
            symbolName = "keyboard.badge.exclamationmark"
        } else if store.isEnabled {
            symbolName = "keyboard"
        } else {
            symbolName = "keyboard.badge.ellipsis"
        }

        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "한컴단축키")
        image?.isTemplate = true
        button.image = image
        button.toolTip = statusTooltip
    }

    private var statusTooltip: String {
        if !permission.isTrusted { return "한컴단축키 — 접근성 권한 필요" }
        return store.isEnabled ? "한컴단축키 — 활성" : "한컴단축키 — 일시정지"
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        menu.addItem(statusHeader)
        menu.addItem(.separator())

        if !permission.isTrusted {
            let setupItem = NSMenuItem(title: "접근성 권한 설정…", action: #selector(handleOpenOnboarding), keyEquivalent: "")
            setupItem.target = self
            menu.addItem(setupItem)
            menu.addItem(.separator())
        }

        let toggle = NSMenuItem(
            title: store.isEnabled ? "일시정지" : "활성화",
            action: #selector(handleToggle),
            keyEquivalent: "p"
        )
        toggle.keyEquivalentModifierMask = [.control, .option, .command]
        toggle.target = self
        menu.addItem(toggle)

        menu.addItem(.separator())

        let styleGuide = NSMenuItem(title: "HWP 스타일 순서 바꾸기…", action: #selector(handleOpenStyleGuide), keyEquivalent: "")
        styleGuide.target = self
        menu.addItem(styleGuide)

        menu.addItem(.separator())

        let settings = NSMenuItem(title: "설정…", action: #selector(handleOpenSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let updates = NSMenuItem(title: "업데이트 확인…", action: #selector(handleCheckForUpdates), keyEquivalent: "")
        updates.target = self
        menu.addItem(updates)

        let log = NSMenuItem(title: "로그 저장…", action: #selector(handleExportLog), keyEquivalent: "")
        log.target = self
        menu.addItem(log)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "한컴단축키 종료", action: #selector(handleQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    private var statusHeader: NSMenuItem {
        let title: String
        if !permission.isTrusted {
            title = "⚠︎ 접근성 권한 필요"
        } else if store.isEnabled {
            let activeRules = store.rules.filter { $0.enabled }.count
            title = "● 활성 — 매핑 \(activeRules)개"
        } else {
            title = "⏸ 일시정지"
        }
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc private func handleToggle() {
        store.isEnabled.toggle()
    }

    @objc private func handleOpenSettings() {
        onOpenSettings()
    }

    @objc private func handleOpenOnboarding() {
        onOpenOnboarding()
    }

    @objc private func handleCheckForUpdates() {
        onCheckForUpdates()
    }

    @objc private func handleExportLog() {
        onExportLog()
    }

    @objc private func handleOpenStyleGuide() {
        onOpenStyleGuide()
    }

    @objc private func handleQuit() {
        onQuit()
    }
}
