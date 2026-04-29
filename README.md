# 한컴단축키 (HancomHotkey)

> macOS에서 한글(HWP)의 스타일 단축키를 `⌘ + 숫자`로 편하게 쓰는 메뉴바 유틸리티

한컴오피스 Mac판의 기본 스타일 단축키는 `Ctrl + 숫자` 조합이라 맥 사용자에게 번거롭습니다. **한컴단축키**는 한글(HWP)·한셀·한쇼가 활성일 때만 `⌘0~4` 를 자동으로 `Ctrl+1~5` 로 변환하여 전송합니다. 그 외 다른 앱에서는 원래 단축키 그대로 동작합니다.

## 기능

- 한글·한셀·한쇼 활성 감지 후 자동 매핑
- 고정 매핑 5종: ⌘0~4 → Ctrl+1~5 (HWP 스타일 목록의 1~5번째 항목)
- 전체 일시정지 / 활성화 토글 (`⌃⌥⌘P`)
- 접근성 권한 온보딩
- 로그인 시 자동 실행 (선택)
- Secure Input(암호 입력창) 감지 시 자동 비활성
- Sparkle 자동 업데이트

## 어떤 스타일이 적용될까?

HWP는 **스타일 이름이 아니라 목록 순서**로 단축키를 결정합니다. ⌘0 → Ctrl+1 은 HWP 스타일 목록의 **1번째 항목** (보통 "바탕글")을 적용합니다.

원하는 스타일을 ⌘0~4 에 배치하려면, HWP 안에서 **스타일 목록의 순서**를 바꾸세요. 앱 설정 → 단축키 탭에 5단계 가이드가 있습니다.

## 설치

### 요구 사항

- macOS 13 (Ventura) 이상
- Apple Silicon / Intel 모두 지원 (Universal binary)

### 다운로드 & 실행

1. `HancomHotkey-0.1.0.dmg` 다운로드
2. DMG 더블클릭하여 마운트
3. `한컴단축키` 를 `Applications` 폴더로 드래그
4. Launchpad에서 `한컴단축키` 실행
5. 처음 실행 시 **접근성 권한 부여** 온보딩 화면이 뜸
   - [시스템 설정 열기] 버튼
   - `개인정보 보호 및 보안 → 접근성` 에서 **한컴단축키** 체크
   - 앱으로 돌아오면 자동으로 활성 상태가 됨

## 사용법

HWP를 열고 `⌘ + 0~4` 를 누르세요.

| 단축키 | 스타일 |
|---|---|
| `⌘ 0` | 본문 가. |
| `⌘ 1` | 네모 12폰트 |
| `⌘ 2` | 본문_동그라미 |
| `⌘ 3` | 본문_삼각화살 |
| `⌘ 4` | 본문점 |

메뉴바 아이콘(⌨︎)에서 일시정지 · 설정 열기 · 종료 가능합니다.

## 개발자 가이드

### 개발 환경

- Xcode 15+
- macOS 13+ SDK
- Homebrew: `xcodegen`, `create-dmg`, `librsvg`

### 로컬 빌드

```bash
./scripts/build.sh
open build/derived/Build/Products/Debug/HancomHotkey.app
```

### 릴리즈 빌드 (서명 + 공증 + DMG)

```bash
./scripts/release.sh 0.1.0
# 산출물: dist/HancomHotkey-0.1.0.dmg
```

사전 조건:
- Developer ID Application 인증서가 Keychain에 설치됨
- `xcrun notarytool store-credentials` 로 `HancomHotkey` 프로필 저장됨
- 환경변수 `TEAM_ID` (기본값 `4AL4PF4BK4`), `NOTARY_PROFILE` (기본값 `HancomHotkey`)

### 프로젝트 구조

```
src/
├── App/           ← 엔트리 포인트, Info.plist, 엔타이틀먼트
├── MenuBar/       ← NSStatusItem 메뉴바 컨트롤러
├── Settings/      ← 설정 윈도우 (SwiftUI)
├── Onboarding/    ← 접근성 권한 온보딩
├── Store/         ← KeyMappingStore (SSOT), MappingRule
├── EventTap/      ← CGEventTap 기반 KeyRemapper
├── Permission/    ← AXIsProcessTrusted 폴링
└── Resources/     ← Assets.xcassets (AppIcon)
```

## 라이선스

© 2026 INNO-HI Inc. All rights reserved.

## 문의

- 이메일: board@innohi.ai.kr
