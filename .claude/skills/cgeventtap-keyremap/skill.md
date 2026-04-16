---
name: cgeventtap-keyremap
description: macOS CGEventTap으로 전역 키 리매핑을 구현한다. 모디파이어 플래그 교체, 앱별 활성화 조건, Secure Input 회피, 이벤트 탭 자동 복구. 키 후킹·리매핑·모디파이어 타이밍 이슈 해결 시 반드시 사용.
---

# CGEventTap 키 리매핑 구현 패턴

## 언제 사용하는가

전역 키 이벤트를 가로채 모디파이어/키코드를 재작성해야 할 때. `eventtap-specialist` 에이전트가 주요 소비자. 이 앱의 핵심 기능(⌘0~4 → Ctrl+2~6 매핑)이 여기에 해당.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| `kCGHIDEventTap` | 가장 이른 단계에서 이벤트 가로채기. 키 리매핑에 적합 |
| `kCGSessionEventTap` | 세션 레벨. 시스템 단축키 이후 |
| `headInsert` | 탭 체인의 맨 앞에 삽입 |
| `defaultTap` | 이벤트 수정 가능 (listenOnly 아님) |
| `CGEventFlags` | cmd/ctrl/shift/alt 같은 모디파이어 비트 마스크 |

## 구현 스켈레톤

```swift
import Cocoa
import Carbon.HIToolbox  // kVK_* 키코드

final class KeyRemapper {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let store: KeyMappingStore
    private var activeBundleID: String?
    
    init(store: KeyMappingStore) {
        self.store = store
        observeActiveApp()
        observeMappingChanges()
    }
    
    func start() -> Bool {
        guard AXIsProcessTrusted() else { return false }
        
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: eventCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let tap = tap else { return false }
        
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        self.eventTap = tap
        self.runLoopSource = source
        return true
    }
    
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), src, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
    
    func reload() { /* store 변경 시 내부 캐시만 갱신 */ }
}
```

### C 콜백 (Swift `@convention(c)`)

```swift
private let eventCallback: CGEventTapCallBack = { proxy, type, event, refcon in
    guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
    let remapper = Unmanaged<KeyRemapper>.fromOpaque(refcon).takeUnretainedValue()
    
    // 탭 disable 복구
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = remapper.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }
    
    // Secure Input 중에는 손대지 않음
    if IsSecureEventInputEnabled() {
        return Unmanaged.passUnretained(event)
    }
    
    // 타깃 앱 체크
    guard remapper.activeBundleID == "com.hancom.office.hwp12.mac.general" else {
        return Unmanaged.passUnretained(event)
    }
    
    // 매핑 적용
    if let newEvent = remapper.remap(event: event, type: type) {
        return Unmanaged.passUnretained(newEvent)
    }
    return Unmanaged.passUnretained(event)
}
```

## 모디파이어 교체 (핵심)

Hammerspoon 스크립트의 "Cmd 릴리즈 기다리기" 트릭은 `hs.eventtap.keyStroke`로 **새 이벤트를 발행**하기 때문에 필요했다. `CGEventTap`에서는 **원본 이벤트의 flags와 keycode를 직접 수정**하면 해당 문제가 원천적으로 발생하지 않는다.

```swift
func remap(event: CGEvent, type: CGEventType) -> CGEvent? {
    let keycode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
    let flags = event.flags
    
    // 매핑 규칙: Cmd+0~4 → Ctrl+2~6
    guard flags.contains(.maskCommand),
          let rule = store.rules.first(where: { $0.matches(keycode: keycode, flags: flags) }) else {
        return nil
    }
    
    // 1. keycode 교체
    event.setIntegerValueField(.keyboardEventKeycode, value: Int64(rule.toKeycode))
    // 2. Cmd 제거, Ctrl 추가
    var newFlags = flags
    newFlags.remove(.maskCommand)
    newFlags.insert(.maskControl)
    event.flags = newFlags
    
    return event
}
```

**왜 이것이 Hammerspoon보다 안정적인가:** 원본 KeyDown 이벤트의 flags만 바꾸기 때문에 이벤트 순서(KeyDown → KeyUp)와 모디파이어 동기화가 시스템에 의해 자동 유지된다. 별도로 Cmd 릴리즈를 기다릴 필요 없음.

## 앱 활성화 감지

```swift
private func observeActiveApp() {
    let ws = NSWorkspace.shared.notificationCenter
    ws.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                   object: nil, queue: .main) { [weak self] note in
        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        self?.activeBundleID = app?.bundleIdentifier
    }
}
```

## Accessibility 권한

```swift
func requestAccessibilityPermission() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
}
```

권한 부여는 사용자가 시스템 설정으로 나가서 체크해야 하며, 그 즉시 앱에 반영되지 않을 수 있다 (재시작 또는 권한 폴링 필요). `ui-ux-designer`의 온보딩 플로우와 합을 맞춰야 함.

## 재진입 방지

자신이 수정한 이벤트를 다시 탭이 수신하지 않도록, 수정된 이벤트는 반환만 하고 `CGEvent.post`로 재발행하지 않는다. 이 패턴은 재진입 위험이 없음.

## 에러 핸들링

- `CGEvent.tapCreate` 반환 nil → Accessibility 미부여. UI에 온보딩 표시
- `.tapDisabledByTimeout` → 콜백 내에서 `tapEnable(true)` 재활성
- `IsSecureEventInputEnabled()` → 암호 필드 감지. 리매핑 스킵 필수

## 테스트 포인트

- HWP 활성 + ⌘0 KeyDown → Ctrl+2 KeyDown으로 변환되어 HWP가 수신
- Safari 활성 + ⌘0 → 변환 없이 그대로 전달 (⌘0은 기본 축소)
- 로그인창 활성 + ⌘0 → 절대 변환 금지

## 참고

- [Quartz Event Services Reference](https://developer.apple.com/documentation/coregraphics/quartz_event_services)
- 기존 Hammerspoon 구현: `~/.hammerspoon/init.lua`
