---
name: hwp-mac-build
description: 맥용 HWP 단축키 리매핑 유틸리티 앱(Swift 메뉴바 앱, DMG 배포)을 5명의 에이전트 팀으로 구축하는 오케스트레이터. Hammerspoon init.lua를 네이티브 Swift로 포팅, CGEventTap 기반 키 리매핑, 접근성 온보딩, 코드사이닝/공증, DMG 패키징 전 과정 조율. 'HWP 유틸리티 만들어', '맥 HWP 앱', 'HWP 단축키 앱', '한컴 단축키 앱', 'HWP 리매퍼', 'DMG 배포용 HWP 앱' 요청 시 반드시 사용.
---

# HWP Mac Utility Build — 오케스트레이터

맥 네이티브 HWP 단축키 리매핑 유틸리티를 5명의 에이전트가 협업해 **서명된 DMG** 까지 만들어낸다.

## 에이전트 팀

| 에이전트 | 역할 | 주요 스킬 |
|---|---|---|
| `swift-developer` | Swift/AppKit 메뉴바 앱 골격, Store, UI 통합 | `swift-menubar-app` |
| `eventtap-specialist` | CGEventTap, 앱 활성 감지, 모디파이어 교체 | `cgeventtap-keyremap` |
| `ui-ux-designer` | 메뉴바/설정/온보딩 UX, 한국어 카피 | `accessibility-onboarding` |
| `packaging-engineer` | Xcode 빌드, 서명, 공증, DMG, Sparkle | `mac-app-packaging` |
| `qa-engineer` | 점진 QA, 경계면 검증, 최종 회귀 | `qa-mac-keyboard` |

## 실행 모드

**서브 에이전트 + 파이프라인**. 각 Phase마다 `Agent` 도구로 필요한 에이전트를 호출하고, 병렬 가능 구간은 `run_in_background`로 fan-out 한다. 중간 산출물은 `~/hwp-mac-utility/_workspace/`에 파일로 전달한다.

## 프로젝트 루트

`~/hwp-mac-utility/`
- `src/` — Swift 코드
- `scripts/` — 빌드/서명/공증/DMG 스크립트
- `assets/` — 앱 아이콘, DMG 배경
- `_workspace/` — 에이전트 간 중간 산출물 (감사 추적용 보존)
- `dist/` — 최종 DMG

## 데이터 전달 프로토콜

### 파일 기반 산출물

| 파일 | 작성자 | 소비자 |
|---|---|---|
| `_workspace/ui-wireframes.md` | ui-ux-designer | swift-developer |
| `_workspace/onboarding-flow.md` | ui-ux-designer | swift-developer, eventtap-specialist |
| `_workspace/copy-ko.md` | ui-ux-designer | swift-developer |
| `_workspace/mapping-schema.md` | swift-developer ↔ eventtap-specialist | 양쪽 합의 문서 |
| `_workspace/swift-developer-progress.md` | swift-developer | 전체 |
| `_workspace/eventtap-notes.md` | eventtap-specialist | qa-engineer |
| `_workspace/packaging-checklist.md` | packaging-engineer | qa-engineer, 사용자 |
| `_workspace/qa-report-phaseN.md` | qa-engineer | 전체 |
| `_workspace/qa-bugs.md` | qa-engineer | 관련 에이전트 |

### 공유 불변식

- HWP 번들 ID: `com.hancom.office.hwp12.mac.general` (Hammerspoon 원본과 동일)
- 기본 매핑: ⌘0→Ctrl+2, ⌘1→Ctrl+3, ⌘2→Ctrl+4, ⌘3→Ctrl+5, ⌘4→Ctrl+6
- 타깃 macOS: 13.0+
- 배포: 직판 DMG (샌드박스 미사용, App Store 경로 포기)

## 실행 Phase

### Phase 0: 사전 확인

오케스트레이터는 시작 전 사용자에게 확인:

- [ ] Apple Developer Program 가입 상태
- [ ] Developer ID Application 인증서 Keychain 설치 여부
- [ ] notarytool keychain profile 저장 여부
- [ ] Team ID / Bundle ID 결정

미진행 항목이 있으면 Phase 4 직전에 다시 멈춰서 사용자 확인 요청.

### Phase 1: 설계 (병렬)

두 에이전트를 `run_in_background=true`로 동시 실행:

- `ui-ux-designer` → 온보딩 플로우, 설정창 와이어프레임, 한국어 카피
- `swift-developer` → Xcode 프로젝트 골격, `KeyMappingStore` 초안, Info.plist

양쪽 산출물이 도착하면 동기화 포인트: `_workspace/mapping-schema.md`를 두 에이전트가 합의한 내용으로 최종화.

### Phase 2: 핵심 구현 (순차)

1. `eventtap-specialist` → `src/EventTap/KeyRemapper.swift` 구현. Phase 1 결과(mapping schema, 온보딩 훅 타이밍) 소비
2. `swift-developer` → EventTap 모듈 통합, 설정 UI 연결, 온보딩 화면 SwiftUI 구현
3. `qa-engineer` → Phase 2 점진 QA. 결과 `qa-report-phase2.md`

버그 발견 시 해당 에이전트에 재작업 지시 후 재QA.

### Phase 3: 마감 + 패키징

1. `ui-ux-designer` → 앱 아이콘(.icns), DMG 배경 이미지 자산 전달
2. `packaging-engineer` → `scripts/build.sh`, `scripts/release.sh` 작성, Hardened Runtime + 엔타이틀먼트 설정
3. 사용자 개입 필요: `TEAM_ID`, notarytool 프로필 이름 환경변수 설정 확인
4. `packaging-engineer` → 실제 `release.sh 0.1.0` 실행 → DMG 산출
5. `qa-engineer` → Gatekeeper 통과 검증, 최종 회귀 체크리스트

### Phase 4: 배포 준비

- Sparkle appcast.xml 템플릿 생성 (선택)
- README.md 작성 (설치·권한 부여 가이드)
- 릴리스 노트 초안

## 에러 핸들링

| 상황 | 대응 |
|---|---|
| 에이전트가 설계 문서 없이 구현 시도 | 즉시 중단, 의존 문서 작성 에이전트 재호출 |
| `codesign` 실패 | `packaging-engineer`에 환경 점검 지시. 실패 지속 시 사용자에게 Keychain 확인 요청 |
| 공증 거부 | notarytool log를 `_workspace/notary-log.txt`에 저장, 원인 요약 후 `packaging-engineer`에 전달 |
| QA blocker 버그 | 배포 단계 진입 차단. 관련 에이전트 재호출 |
| 에이전트 간 인터페이스 불일치 | `mapping-schema.md` 재협의 후 양쪽 재구현 |

## 팀 크기 적정성

5명 에이전트, 추정 작업 15~20개. 권장 범위(3~5명, 4~6개/인당) 상단. 조율 오버헤드 관리를 위해 각 Phase 종료 시 오케스트레이터가 진척 요약.

## 테스트 시나리오

### 정상 흐름

1. 사용자: "HWP 유틸리티 만들어줘"
2. Phase 0: 사용자에게 Apple Dev 상태 확인
3. Phase 1 병렬: UX + Swift 골격
4. Phase 2 순차: EventTap 구현 → 통합 → QA
5. Phase 3: 패키징 → DMG 생성
6. 최종: `dist/HwpUtility-0.1.0.dmg` 출력

### 에러 흐름

1. Phase 3에서 공증 실패 (Hardened Runtime 미활성)
2. `packaging-engineer`가 원인 파악 → Xcode 설정 수정 지시
3. `swift-developer`가 Xcode 프로젝트 설정 업데이트
4. 재아카이브 → 재공증 → 성공

## 산출물 체크리스트

완료 후 확인:

- [ ] `~/hwp-mac-utility/src/` — Swift 프로젝트 완성
- [ ] `~/hwp-mac-utility/scripts/release.sh` 실행 성공
- [ ] `~/hwp-mac-utility/dist/HwpUtility-*.dmg` 존재 + 서명·공증·staple 완료
- [ ] `_workspace/qa-final-checklist.md` 모든 항목 체크됨
- [ ] README.md 존재 (설치 가이드)
- [ ] Gatekeeper 통과 (실제 다운로드 경로에서 경고 없음)
