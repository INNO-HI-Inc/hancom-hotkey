import AppKit
import Carbon.HIToolbox

enum KeyDescriptor {
    static func describe(keycode: UInt16, modifiers: UInt64) -> String {
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        parts.append(keyName(for: keycode))
        return parts.joined()
    }

    static func keyName(for keycode: UInt16) -> String {
        if let special = specialNames[Int(keycode)] { return special }
        return readableKey(for: keycode) ?? "Key(\(keycode))"
    }

    private static let specialNames: [Int: String] = [
        kVK_Space: "Space",
        kVK_Return: "Return",
        kVK_Tab: "Tab",
        kVK_Delete: "Delete",
        kVK_Escape: "Esc",
        kVK_LeftArrow: "←",
        kVK_RightArrow: "→",
        kVK_UpArrow: "↑",
        kVK_DownArrow: "↓",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
        kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8",
        kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]

    private static func readableKey(for keycode: UInt16) -> String? {
        let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue()
        guard let layout = source else { return nil }
        let layoutDataPtr = TISGetInputSourceProperty(layout, kTISPropertyUnicodeKeyLayoutData)
        guard let layoutData = layoutDataPtr else { return nil }
        let data = Unmanaged<CFData>.fromOpaque(layoutData).takeUnretainedValue() as Data
        var result: String?
        data.withUnsafeBytes { rawBuf in
            guard let keyLayoutPtr = rawBuf.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else { return }
            var deadKeyState: UInt32 = 0
            var chars = [UniChar](repeating: 0, count: 4)
            var actualLength = 0
            let status = UCKeyTranslate(
                keyLayoutPtr,
                keycode,
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                chars.count,
                &actualLength,
                &chars
            )
            if status == noErr, actualLength > 0 {
                let string = String(utf16CodeUnits: chars, count: actualLength).uppercased()
                if !string.isEmpty { result = string }
            }
        }
        return result
    }
}
