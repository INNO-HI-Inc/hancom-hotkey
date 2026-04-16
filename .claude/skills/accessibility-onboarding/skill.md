---
name: accessibility-onboarding
description: macOS 유틸리티 앱의 접근성 권한 온보딩 UX를 설계하고 구현한다. 이탈률 최소화 화면 구성, 시스템 설정 유도 링크(x-apple.systempreferences), 권한 폴링 후 자동 활성화, 한국어 안내 문구. 권한 온보딩·첫 실행 플로우 설계 시 반드시 사용.
---

# Accessibility 권한 온보딩 UX

## 언제 사용하는가

키보드 이벤트 탭, 스크린 캡처, 화면 기록 등 사용자가 시스템 설정에서 명시적으로 권한을 부여해야 하는 앱의 첫 실행 플로우를 설계할 때. `ui-ux-designer` + `swift-developer` 공동 작업.

## 왜 중요한가

- Accessibility 권한 부여는 **앱 밖으로 나가서** 시스템 설정을 조작해야 함
- 이 지점에서 사용자 이탈률이 가장 높음 (유틸리티 앱 최대 이탈 포인트)
- 설정이 끝나도 앱으로 자동 복귀하지 않음 → 사용자가 길 잃음

## 온보딩 플로우 (3단계)

```
[1. 환영 화면]
   "HWP 단축키를 더 편하게"
   [시작하기] 버튼
        ↓
[2. 권한 요청 화면]
   "HWP 단축키 유틸리티가 동작하려면
    접근성 권한이 필요합니다"
   설명 + 스크린샷
   [시스템 설정 열기] 버튼
        ↓ (시스템 설정 열림)
        ↓ (사용자가 체크박스 on)
        ↓ (앱이 폴링으로 감지)
[3. 활성화 완료]
   "✓ 준비 완료!"
   "HWP에서 ⌘0~4를 눌러보세요"
   [닫기] 버튼
```

## 핵심 구현

### 1. 권한 상태 폴링

앱이 활성 상태로 돌아올 때마다 권한 재확인 + 0.5초 간격 폴링 (설정창이 열려있는 동안):

```swift
import AppKit

final class PermissionMonitor: ObservableObject {
    @Published var isTrusted: Bool = AXIsProcessTrusted()
    private var timer: Timer?
    
    func startPolling() {
        stopPolling()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            let trusted = AXIsProcessTrusted()
            if self?.isTrusted != trusted {
                DispatchQueue.main.async { self?.isTrusted = trusted }
            }
            if trusted { self?.stopPolling() }
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
}
```

### 2. 시스템 설정 딥링크

macOS 13+ 기준:

```swift
func openAccessibilitySettings() {
    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    NSWorkspace.shared.open(url)
}
```

### 3. 프롬프트 유도 (선택)

```swift
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
_ = AXIsProcessTrustedWithOptions(options as CFDictionary)
```

이 호출은 macOS가 직접 "열기" 다이얼로그를 띄움. 단, 사용자가 "거부"를 누르면 이후 자동 재프롬프트 불가 → **커스텀 온보딩 화면을 우선하고**, 프롬프트 API는 백업으로만 사용.

## SwiftUI 온보딩 화면 예시

```swift
struct OnboardingView: View {
    @EnvironmentObject var permission: PermissionMonitor
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            
            Text("접근성 권한이 필요합니다")
                .font(.title2).bold()
            
            Text("HWP 단축키 유틸리티가 키보드 입력을 처리하려면\n접근성 권한을 부여해주세요.\n\n시스템 설정 → 개인정보 보호 및 보안 → 접근성에서\nHwpUtility를 체크하세요.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button("시스템 설정 열기") {
                openAccessibilitySettings()
                permission.startPolling()
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            
            if permission.isTrusted {
                Label("권한 부여됨", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(40)
        .frame(width: 460)
    }
}
```

## 한국어 카피 가이드라인

**좋은 예 (담백, 명확):**
- "접근성 권한이 필요합니다"
- "시스템 설정 열기"
- "✓ 준비 완료"

**나쁜 예 (과한 존대, 마케팅 톤):**
- "고객님, HWP 단축키 유틸리티를 사용하시기 위해서는..."
- "지금 바로 시작해보세요! 🚀"

타깃(공무원/교사)은 담백한 톤을 선호한다.

## 폴백 시나리오

- 사용자가 시스템 설정에서 체크했는데 앱이 반응 안 함 → 앱 재시작 안내 문구 제공
- 권한 부여 후에도 EventTap 생성 실패 → 재부팅 안내
- 사용자가 거부 후 돌아옴 → 재진입 화면에 "다시 시도" 버튼

## 참고

- [AXIsProcessTrustedWithOptions](https://developer.apple.com/documentation/applicationservices/1462089-axisprocesstrustedwithoptions)
- 레퍼런스: Karabiner-Elements, Raycast, Rectangle의 온보딩
