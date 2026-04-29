import Foundation
import Combine
import os

final class KeyMappingStore: ObservableObject {
    static let shared = KeyMappingStore()
    private static let logger = Logger(subsystem: "com.innohi.hancomhotkey", category: "store")

    @Published var rules: [MappingRule] = [] {
        didSet {
            guard isLoaded, rules != oldValue else { return }
            persistRules()
            notifyChange()
        }
    }

    @Published var isEnabled: Bool = true {
        didSet {
            guard isLoaded, isEnabled != oldValue else { return }
            defaults.set(isEnabled, forKey: enabledKey)
            notifyChange()
        }
    }

    @Published var launchAtLogin: Bool = false {
        didSet {
            guard isLoaded, launchAtLogin != oldValue else { return }
            defaults.set(launchAtLogin, forKey: launchAtLoginKey)
        }
    }

    private let defaults: UserDefaults
    private let rulesKey = "mappingRules.v1"
    private let enabledKey = "mappingEnabled.v1"
    private let launchAtLoginKey = "launchAtLogin.v1"
    private let schemaVersionKey = "schemaVersion"
    private let currentSchemaVersion = 5
    private var isLoaded = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
        isLoaded = true
    }

    private func load() {
        let storedSchema = defaults.integer(forKey: schemaVersionKey)

        if storedSchema < currentSchemaVersion {
            // 0.3.0 onward: custom mapping editor removed. Always ship fixed defaults.
            rules = MappingRule.defaultHwpRules()
            persistRules()
            defaults.set(currentSchemaVersion, forKey: schemaVersionKey)
            Self.logger.info("migrated to schema \(self.currentSchemaVersion); rules reset to defaults")
        } else if let data = defaults.data(forKey: rulesKey),
                  let decoded = try? JSONDecoder().decode([MappingRule].self, from: data) {
            rules = decoded
        } else {
            rules = MappingRule.defaultHwpRules()
            persistRules()
        }

        if defaults.object(forKey: enabledKey) != nil {
            isEnabled = defaults.bool(forKey: enabledKey)
        }
        launchAtLogin = defaults.bool(forKey: launchAtLoginKey)
    }

    func resetToDefaults() {
        rules = MappingRule.defaultHwpRules()
    }

    func add(_ rule: MappingRule) {
        rules.append(rule)
    }

    func remove(ruleID: UUID) {
        rules.removeAll { $0.id == ruleID }
    }

    func update(_ rule: MappingRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }), rules[index] != rule {
            rules[index] = rule
        }
    }

    private func persistRules() {
        if let data = try? JSONEncoder().encode(rules) {
            defaults.set(data, forKey: rulesKey)
        }
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: .keyMappingDidChange, object: nil)
        Self.logger.info("mapping changed: rules=\(self.rules.count) enabled=\(self.isEnabled)")
    }
}

extension Notification.Name {
    static let keyMappingDidChange = Notification.Name("com.innohi.hancomhotkey.keyMappingDidChange")
}
