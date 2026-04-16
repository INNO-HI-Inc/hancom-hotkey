import Cocoa
import Carbon.HIToolbox
import os

final class KeyRemapper {
    private static let logger = Logger(subsystem: "com.innohi.hancomhotkey", category: "remapper")

    /// Global toggle hotkey (⌃⌥⌘P) — pauses / resumes mapping from anywhere.
    private static let toggleKeycode: UInt16 = UInt16(kVK_ANSI_P)
    private static let toggleModifiers: UInt64 = UInt64(
        NSEvent.ModifierFlags.control.rawValue
            | NSEvent.ModifierFlags.option.rawValue
            | NSEvent.ModifierFlags.command.rawValue
    )

    private let store: KeyMappingStore
    private let activeApp: ActiveAppMonitor
    private let permission: PermissionMonitor

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var cachedRules: [MappingRule] = []
    private var cachedEnabled: Bool = true
    private var notificationObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    init(store: KeyMappingStore, activeApp: ActiveAppMonitor, permission: PermissionMonitor) {
        self.store = store
        self.activeApp = activeApp
        self.permission = permission
        refreshCache()
        observeMappingChanges()
        observeWake()
    }

    deinit {
        stop()
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let wakeObserver = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
    }

    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else { return true }
        guard permission.isTrusted else {
            Self.logger.error("start() failed: accessibility not trusted")
            return false
        }

        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: KeyRemapper.eventCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            Self.logger.error("CGEvent.tapCreate returned nil")
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.eventTap = tap
        self.runLoopSource = source
        Self.logger.info("event tap started")
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    func reload() {
        refreshCache()
    }

    private func refreshCache() {
        cachedRules = store.rules.filter { $0.enabled }
        cachedEnabled = store.isEnabled
    }

    private func observeMappingChanges() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .keyMappingDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshCache()
        }
    }

    private func observeWake() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recoverFromSleep()
        }
    }

    private func recoverFromSleep() {
        guard permission.isTrusted else { return }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
            Self.logger.info("woke from sleep; re-enabled event tap")
        } else {
            _ = start()
            Self.logger.info("woke from sleep; event tap re-created")
        }
    }

    fileprivate func process(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                Self.logger.warning("event tap disabled (\(type.rawValue)); re-enabled")
            }
            return Unmanaged.passUnretained(event)
        }

        if IsSecureEventInputEnabled() {
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }

        let flags = event.flags
        let keycode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))

        // Global toggle hotkey (⌃⌥⌘P) — works from anywhere, always active once accessibility granted.
        if type == .keyDown && matchesToggleHotkey(keycode: keycode, flags: flags) {
            DispatchQueue.main.async { [weak self] in
                self?.store.isEnabled.toggle()
            }
            return nil // swallow
        }

        guard cachedEnabled else { return Unmanaged.passUnretained(event) }

        let bundleID = activeApp.currentBundleID ?? ""
        guard let rule = cachedRules.first(where: { rule in
            rule.targets(bundleID: bundleID) && rule.matches(keycode: keycode, flags: flags)
        }) else {
            return Unmanaged.passUnretained(event)
        }

        event.setIntegerValueField(.keyboardEventKeycode, value: Int64(rule.toKeycode))

        var newFlags = flags
        let fromMaskNS = NSEvent.ModifierFlags(rawValue: UInt(rule.fromModifiers))
        let toMaskNS = NSEvent.ModifierFlags(rawValue: UInt(rule.toModifiers))

        if fromMaskNS.contains(.command) && !toMaskNS.contains(.command) { newFlags.remove(.maskCommand) }
        if fromMaskNS.contains(.control) && !toMaskNS.contains(.control) { newFlags.remove(.maskControl) }
        if fromMaskNS.contains(.option) && !toMaskNS.contains(.option) { newFlags.remove(.maskAlternate) }
        if fromMaskNS.contains(.shift) && !toMaskNS.contains(.shift) { newFlags.remove(.maskShift) }

        if toMaskNS.contains(.command) { newFlags.insert(.maskCommand) }
        if toMaskNS.contains(.control) { newFlags.insert(.maskControl) }
        if toMaskNS.contains(.option) { newFlags.insert(.maskAlternate) }
        if toMaskNS.contains(.shift) { newFlags.insert(.maskShift) }

        event.flags = newFlags

        if type == .keyDown {
            Self.logger.debug("remapped \(rule.fromDescription) → \(rule.toDescription) in \(bundleID)")
        }

        return Unmanaged.passUnretained(event)
    }

    private func matchesToggleHotkey(keycode: UInt16, flags: CGEventFlags) -> Bool {
        guard keycode == Self.toggleKeycode else { return false }
        let relevantMask: UInt64 = UInt64(
            NSEvent.ModifierFlags.command.rawValue
                | NSEvent.ModifierFlags.control.rawValue
                | NSEvent.ModifierFlags.option.rawValue
                | NSEvent.ModifierFlags.shift.rawValue
        )
        let incoming = UInt64(flags.rawValue) & relevantMask
        return incoming == Self.toggleModifiers
    }

    private static let eventCallback: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
        let remapper = Unmanaged<KeyRemapper>.fromOpaque(refcon).takeUnretainedValue()
        return remapper.process(type: type, event: event) ?? Unmanaged.passUnretained(event)
    }
}
