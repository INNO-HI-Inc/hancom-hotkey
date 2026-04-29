# Changelog

본 파일은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/) 형식을 따르며, 버전 관리는 [Semantic Versioning](https://semver.org/lang/ko/)을 따른다.

## [0.5.0] — 2026-04-29

### Changed
- **기본 매핑을 1~5번째 슬롯으로 시프트**: ⌘0~4 → `⌃1~5` (이전: `⌃2~6`)
  - ⌘0 = HWP 스타일 목록 1번째 (대개 "바탕글")
  - ⌘1 = 2번째, …, ⌘4 = 5번째
  - 이유: 이전 매핑은 `⌘0`이 첫 번째 슬롯을 건너뛰어(2번째부터 시작) 사용자 멘탈 모델과 어긋남. 1:1 직관 매핑이 학습 비용 ↓
- schema v5 마이그레이션: 기존 사용자는 새 기본값으로 자동 초기화

### Docs
- README, 사이트 매핑표, 5단계 가이드, FAQ를 모두 새 매핑(1~5번째)으로 갱신
- 사이트에 "두 번 눌러야 글씨체까지 바뀜" FAQ 추가 — 한컴 HWP의 의도된 동작이며 앱 버그가 아님을 명시 (한컴 공식 문서 인용)

## [0.4.0] — 2026-04-16

### Added
- **Sparkle 자동 업데이트**: `SUFeedURL` + EdDSA 서명 기반. 사용자가 버그 수정본을 즉시 받을 수 있음. 메뉴바 / 설정 / 정보 탭에서 수동 확인도 가능
- **한셀 · 한쇼 지원**: 한글(HWP) 뿐 아니라 `com.hancom.office.hcell12.mac.general`, `com.hancom.office.hshow12.mac.general` 번들 ID도 자동 감지 매핑
- **전역 토글 단축키**: 어디서든 `⌃⌥⌘P` 누르면 매핑 일시정지 / 재개
- **슬립·웨이크 복구**: 맥 슬립 후 깨어날 때 `NSWorkspace.didWakeNotification` 수신하여 EventTap 자동 재등록
- **로그 내보내기**: 메뉴바 / 설정 > 문제 해결에서 최근 1시간 로그를 `.txt` 로 저장 (`log show` 기반)
- **메뉴바 드롭다운 개편**: 상단에 상태 헤더 (`● 활성 — 매핑 N개` / `⏸ 일시정지` / `⚠︎ 접근성 권한 필요`), "HWP 스타일 순서 바꾸기" 바로가기, "업데이트 확인"·"로그 저장" 메뉴 추가
- **랜딩 페이지**: `site/index.html` (GitHub Pages 호스팅용). 제품 소개 + 기능 + 기본 매핑표 + 설치 가이드 + 다운로드 CTA
- **appcast.xml 자동 갱신**: `scripts/update_appcast.py` 로 릴리즈마다 자동 엔트리 추가

### Technical
- `MappingRule.targetBundleID: String` → `targetBundleIDs: [String]` 로 변경. 한 규칙이 여러 한컴 앱을 한번에 타깃
- schema v4 마이그레이션: 이전 버전 규칙을 기본값으로 초기화
- `KeyRemapper` 가 예약 단축키(⌃⌥⌘P) 를 내부에서 인터셉트하여 `store.isEnabled.toggle()` 실행
- `release.sh` 가 Sparkle `sign_update` 로 EdDSA 서명 추출 → `update_appcast.py` 호출 → `site/appcast.xml` 갱신까지 한 번에 수행

## [0.3.0] — 2026-04-16

### Changed
- **핵심 단순화**: 커스텀 매핑 편집 UI 제거 (⌘0~4 → Ctrl+2~6 고정 매핑만 유지)
  - HWP는 스타일 이름이 아니라 **스타일 목록 순서**로 단축키를 붙이므로, 앱에서 이름·타깃키를 편집하는 건 실사용에서 혼란만 초래함
  - 원하는 결과는 HWP **안에서** 스타일 순서를 바꾸는 것으로 해결
- 설정 → 단축키 탭을 **읽기 전용 매핑 표 + HWP 스타일 순서 변경 5단계 가이드** 로 재구성
- 0.2.x 에서 커스텀 편집한 규칙은 **0.3.0 으로 업그레이드 시 기본값으로 초기화** (schema v3 마이그레이션)

### Removed
- `KeyCaptureView` (NSButton 기반 키 캡처)
- `AddMappingSheet` (모달 매핑 추가 시트)
- `HwpShortcutGuideView` (별도 시트 — ShortcutsTabView 본문으로 흡수)

## [0.2.3] — 2026-04-16

### Fixed
- **매핑 편집·추가가 실제로 반영되지 않던 치명적 버그**
  - `@Published` 의 sink 관찰자가 willSet 타이밍에 실행되어, 저장/알림 시 `self.rules` 가 이전 값을 참조
  - UI는 새 값을 보여주지만 디스크 저장과 EventTap 캐시 갱신이 옛 값으로 발생 → 사용자가 보기엔 "수정해도 매핑 안 됨"
- `KeyMappingStore` 를 `didSet` 속성 관찰자 기반으로 재작성하여 항상 assignment 이후 시점에 저장·알림 실행

## [0.2.2] — 2026-04-16

### Changed
- "매핑 추가" 를 인라인 즉시 삽입 대신 **모달 시트 + 확인 버튼** 방식으로 개선
  - 이름 / 입력 단축키 / HWP 단축키 를 시트 안에서 먼저 입력
  - 입력 단축키가 기존 매핑과 중복이면 경고 후 추가 차단
  - 모든 필드 채워야 "추가" 버튼 활성화

## [0.2.1] — 2026-04-16

### Fixed
- 설정 → 단축키 탭에서 매핑 편집 시 Auto Layout 무한 제약 루프로 앱이 강제 종료되던 문제
  - `KeyCaptureView` 를 커스텀 NSView 에서 `NSButton` 기반으로 재작성 (Auto Layout 제거)
  - `RuleRow` 상태 동기화 로직 제거, 스토어 ID 조회로 단순화
  - 이름 편집은 Return 또는 포커스 해제 시점에만 저장 (키 입력마다 저장 금지)
  - 키 캡처 시 keycode + modifiers를 단일 콜백으로 원자적 업데이트

## [0.2.0] — 2026-04-16

### Added
- **커스텀 매핑 편집** — 설정 → 단축키 탭에서:
  - 매핑 이름 인라인 편집
  - "입력 단축키" 키 캡처 (클릭 후 원하는 키 조합 입력)
  - "HWP 단축키" 키 캡처 (HWP에서 스타일에 할당한 단축키)
  - 매핑 추가/삭제 버튼
- HWP 스타일에 단축키 할당하는 법 가이드 시트

### Technical
- `KeyCaptureView` (NSViewRepresentable) 로 키 캡처 구현
- `KeyMappingStore.update/add/remove` API

## [0.1.0] — 2026-04-16

### Added
- HWP 활성 시 `⌘0~4` → `Ctrl+2~6` 자동 리매핑 (5개 기본 스타일)
- 메뉴바 상주 유틸리티 (NSStatusItem, LSUIElement)
- 접근성 권한 온보딩 화면 (SwiftUI)
- 설정 윈도우 3탭: 일반 / 단축키 / 정보
- 전체 일시정지 및 개별 규칙 ON/OFF
- 로그인 시 자동 실행 (SMAppService)
- Secure Input(암호 입력) 감지 시 자동 비활성
- CGEventTap이 `tapDisabledByTimeout` 발생 시 자동 재활성
- macOS 13+ Universal binary (arm64 + x86_64)
- Developer ID 코드사이닝 + Apple 공증
- DMG 배포 패키지 (create-dmg 기반)
