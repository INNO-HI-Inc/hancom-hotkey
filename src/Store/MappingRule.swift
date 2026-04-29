import Foundation
import AppKit
import Carbon.HIToolbox

struct MappingRule: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var fromKeycode: UInt16
    var fromModifiers: UInt64
    var toKeycode: UInt16
    var toModifiers: UInt64
    var targetBundleIDs: [String]
    var enabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        fromKeycode: UInt16,
        fromModifiers: UInt64,
        toKeycode: UInt16,
        toModifiers: UInt64,
        targetBundleIDs: [String],
        enabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.fromKeycode = fromKeycode
        self.fromModifiers = fromModifiers
        self.toKeycode = toKeycode
        self.toModifiers = toModifiers
        self.targetBundleIDs = targetBundleIDs
        self.enabled = enabled
    }
}

extension MappingRule {
    /// Bundle IDs of Hancom Office products we target.
    static let hwpBundleID = "com.hancom.office.hwp12.mac.general"
    static let hancellBundleID = "com.hancom.office.hcell12.mac.general"
    static let hanshowBundleID = "com.hancom.office.hshow12.mac.general"

    static var hancomFamilyBundleIDs: [String] {
        [hwpBundleID, hancellBundleID, hanshowBundleID]
    }

    static func defaultHwpRules() -> [MappingRule] {
        let cmd = UInt64(NSEvent.ModifierFlags.command.rawValue)
        let ctrl = UInt64(NSEvent.ModifierFlags.control.rawValue)
        let targets = hancomFamilyBundleIDs

        return [
            MappingRule(name: "스타일 1번째 (바탕글)", fromKeycode: UInt16(kVK_ANSI_0), fromModifiers: cmd,
                        toKeycode: UInt16(kVK_ANSI_1), toModifiers: ctrl, targetBundleIDs: targets),
            MappingRule(name: "스타일 2번째", fromKeycode: UInt16(kVK_ANSI_1), fromModifiers: cmd,
                        toKeycode: UInt16(kVK_ANSI_2), toModifiers: ctrl, targetBundleIDs: targets),
            MappingRule(name: "스타일 3번째", fromKeycode: UInt16(kVK_ANSI_2), fromModifiers: cmd,
                        toKeycode: UInt16(kVK_ANSI_3), toModifiers: ctrl, targetBundleIDs: targets),
            MappingRule(name: "스타일 4번째", fromKeycode: UInt16(kVK_ANSI_3), fromModifiers: cmd,
                        toKeycode: UInt16(kVK_ANSI_4), toModifiers: ctrl, targetBundleIDs: targets),
            MappingRule(name: "스타일 5번째", fromKeycode: UInt16(kVK_ANSI_4), fromModifiers: cmd,
                        toKeycode: UInt16(kVK_ANSI_5), toModifiers: ctrl, targetBundleIDs: targets),
        ]
    }

    func matches(keycode: UInt16, flags: CGEventFlags) -> Bool {
        guard enabled, keycode == fromKeycode else { return false }
        let relevantMask: UInt64 = UInt64(
            NSEvent.ModifierFlags.command.rawValue
                | NSEvent.ModifierFlags.control.rawValue
                | NSEvent.ModifierFlags.option.rawValue
                | NSEvent.ModifierFlags.shift.rawValue
        )
        let incoming = UInt64(flags.rawValue) & relevantMask
        let expected = fromModifiers & relevantMask
        return incoming == expected
    }

    func targets(bundleID: String) -> Bool {
        targetBundleIDs.contains(bundleID)
    }

    var fromDescription: String {
        KeyDescriptor.describe(keycode: fromKeycode, modifiers: fromModifiers)
    }

    var toDescription: String {
        KeyDescriptor.describe(keycode: toKeycode, modifiers: toModifiers)
    }
}
