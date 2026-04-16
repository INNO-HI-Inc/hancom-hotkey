---
name: swift-menubar-app
description: macOS 네이티브 메뉴바 유틸리티 앱을 Swift/AppKit로 구축한다. NSStatusItem, SwiftUI 설정 윈도우, UserDefaults 영속화, LSUIElement, SMAppService 로그인 자동실행. Swift 메뉴바 앱 구현·수정 작업 시 반드시 사용.
---

# Swift 메뉴바 앱 구현 패턴

## 언제 사용하는가

사용자가 macOS 메뉴바 유틸리티 앱을 Swift로 구현하라고 요청할 때. `swift-developer` 에이전트가 주요 소비자.

## 프로젝트 골격

### 파일 구조

```
src/
├── HwpUtility.xcodeproj  (또는 Package.swift)
├── App/
│   ├── HwpUtilityApp.swift       ← @main entry (SwiftUI App protocol)
│   ├── AppDelegate.swift         ← NSApplicationDelegate
│   └── Info.plist
├── MenuBar/
│   ├── MenuBarController.swift   ← NSStatusItem 관리
│   └── StatusMenuBuilder.swift   ← 드롭다운 메뉴 생성
├── Settings/
│   ├── SettingsWindow.swift      ← NSWindow + SwiftUI 호스팅
│   ├── GeneralTabView.swift
│   ├── ShortcutsTabView.swift
│   └── AboutTabView.swift
├── Store/
│   ├── KeyMappingStore.swift     ← ObservableObject, Codable, UserDefaults 영속화
│   └── MappingRule.swift         ← Codable struct
├── EventTap/                     ← eventtap-specialist가 채움
└── Resources/
    ├── Assets.xcassets           ← AppIcon, 메뉴바 아이콘(Template)
    └── Localizable.strings
```

### Info.plist 필수 키

```xml
<key>LSUIElement</key><true/>                    <!-- Dock 미표시 -->
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>CFBundleIdentifier</key><string>com.yourcompany.hwputility</string>
<key>NSHumanReadableCopyright</key><string>© 2026</string>
```

샌드박스는 **사용하지 않는다**. `CGEventTap`이 샌드박스에서 불가능. App Store 출시 경로는 포기.

## 핵심 구현 패턴

### 1. 메뉴바 아이콘

```swift
import AppKit

final class MenuBarController {
    private let statusItem: NSStatusItem
    
    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "HWP Utility")
            button.image?.isTemplate = true  // 다크/라이트 자동 대응
        }
        statusItem.menu = buildMenu()
    }
}
```

**템플릿 이미지 필수** (`isTemplate = true`). 컬러 아이콘은 UX 가이드 위반이자 다크모드에서 깨짐.

### 2. KeyMappingStore (SSOT)

```swift
import Combine

final class KeyMappingStore: ObservableObject {
    static let shared = KeyMappingStore()
    
    @Published private(set) var rules: [MappingRule] = []
    @Published var isEnabled: Bool = true
    
    private let defaults = UserDefaults.standard
    private let rulesKey = "mappingRules.v1"
    
    init() { load() }
    
    func load() {
        guard let data = defaults.data(forKey: rulesKey),
              let decoded = try? JSONDecoder().decode([MappingRule].self, from: data) else {
            rules = MappingRule.defaultHwpRules()   // ⌘0~4 → Ctrl+2~6
            save()
            return
        }
        rules = decoded
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(rules) {
            defaults.set(data, forKey: rulesKey)
        }
    }
    
    func update(_ newRules: [MappingRule]) {
        rules = newRules
        save()
        NotificationCenter.default.post(name: .keyMappingDidChange, object: nil)
    }
}

extension Notification.Name {
    static let keyMappingDidChange = Notification.Name("keyMappingDidChange")
}
```

**주의:** `eventtap-specialist`가 이 `keyMappingDidChange` 알림을 구독해 탭을 `reload()` 해야 한다. 인터페이스 합의 필수.

### 3. 설정 윈도우

메뉴바 앱에서 `NSWindow`를 띄울 때는 `NSApp.activate(ignoringOtherApps: true)` 호출 후 `window.makeKeyAndOrderFront()`.

```swift
import SwiftUI

final class SettingsWindow: NSObject {
    private var window: NSWindow?
    
    func show() {
        if window == nil {
            let rootView = SettingsRootView().environmentObject(KeyMappingStore.shared)
            let hosting = NSHostingController(rootView: rootView)
            let w = NSWindow(contentViewController: hosting)
            w.title = "HWP 단축키 설정"
            w.styleMask = [.titled, .closable, .miniaturizable]
            w.setContentSize(NSSize(width: 600, height: 400))
            w.center()
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
```

### 4. 로그인 자동실행 (macOS 13+)

```swift
import ServiceManagement

func setLaunchAtLogin(_ enabled: Bool) throws {
    if enabled {
        try SMAppService.mainApp.register()
    } else {
        try SMAppService.mainApp.unregister()
    }
}
```

구버전 `SMLoginItemSetEnabled`는 **쓰지 않는다** (macOS 13에서 deprecated).

## 작업 원칙

1. **AppKit + SwiftUI 하이브리드** — 메뉴바/윈도우는 AppKit, 콘텐츠 뷰는 SwiftUI. 두 세계를 NSHostingController로 연결
2. **ObservableObject 단일 store** — 여러 화면이 같은 store를 구독. 매핑 변경이 모든 곳에 즉시 반영
3. **에러는 `Result` 또는 `throws`로** — 특히 `SMAppService.register()`는 실패 가능. UI에 명확한 에러 메시지 노출

## 에러 핸들링

- `NSStatusItem`이 nil을 반환할 일은 없지만, `button`은 옵셔널 — 안전하게 풀기
- `UserDefaults` 디코딩 실패 → 기본값으로 복구 후 경고 로그
- SwiftUI 뷰에서 `@Published` 속성 변경은 메인 스레드에서만

## 참고

- [SwiftUI + AppKit Bridging](https://developer.apple.com/documentation/swiftui/nshostingcontroller)
- [NSStatusItem](https://developer.apple.com/documentation/appkit/nsstatusitem)
