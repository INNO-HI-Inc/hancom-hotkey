---
name: qa-mac-keyboard
description: macOS 키 리매핑 유틸리티 앱의 통합 품질을 검증한다. 경계면 교차 비교(store 스키마 ↔ EventTap 읽기), 키 매핑 정합성, Accessibility 권한 시나리오, Secure Input 회피, DMG Gatekeeper 통과 검증. 모듈 완성 직후 점진 QA·최종 회귀 QA 작업 시 반드시 사용.
---

# 맥 키 리매핑 앱 QA 가이드

## 언제 사용하는가

`qa-engineer` 에이전트가 각 모듈 완성 직후 검증할 때, 그리고 DMG 배포 직전 최종 회귀 테스트할 때.

## 핵심 원칙: 경계면 교차 비교

"파일이 존재하는지"가 아니라 **"A가 쓴 데이터 shape을 B가 정확히 읽는지"**를 본다. 이 앱에서 가장 위험한 경계면:

| 경계면 | 검증 대상 |
|---|---|
| `KeyMappingStore` ↔ `KeyRemapper` | Codable 필드명·타입 일치, 기본값 동일 |
| `KeyMappingStore` ↔ 설정 UI | 저장 후 UI가 올바른 값을 표시 |
| `PermissionMonitor` ↔ 온보딩 UI | 권한 상태 변화가 즉시 UI에 반영 |
| `Info.plist` ↔ 공증 요구사항 | LSMinimumSystemVersion, BundleID, Hardened Runtime |
| DMG 서명 ↔ Gatekeeper | staple 완료 후 격리 속성 있는 다운로드로 테스트 |

## 점진 QA 체크리스트

### Phase 1 완료 시 (프로젝트 골격 + Store)

- [ ] `KeyMappingStore.save()` 후 앱 재시작 → `load()`가 같은 값 복원
- [ ] 기본 규칙이 Hammerspoon `init.lua`의 매핑과 동일 (⌘0→Ctrl+2, ... ⌘4→Ctrl+6)
- [ ] `MappingRule` Codable 라운드트립 (encode → decode → 동일성 체크)
- [ ] Info.plist에 `LSUIElement=true` — dock 아이콘 안 나타남 확인

### Phase 2 완료 시 (EventTap)

- [ ] HWP 활성 + ⌘0 KeyDown → HWP에 Ctrl+2 KeyDown 도달 (HWP 로그 또는 실제 스타일 적용 확인)
- [ ] HWP 비활성 + ⌘0 → 기본 동작(Safari 축소 등) 방해 없음
- [ ] `IsSecureEventInputEnabled()` true일 때 매핑 스킵 (로그인 창에서 수동 검증)
- [ ] `.tapDisabledByTimeout` 발생 시 자동 재활성 (CPU 부하 테스트로 유도)
- [ ] 앱 10분 이상 켜둔 후에도 매핑 지속 작동 (메모리 누수·탭 disable 회귀)

### Phase 3 완료 시 (UI + 온보딩)

- [ ] 첫 실행 → 온보딩 화면 자동 표시
- [ ] 권한 부여 후 → 메인 상태로 전환 (재시작 없이)
- [ ] 권한 취소 후 재실행 → 다시 온보딩 화면
- [ ] 설정창에서 매핑 변경 → 즉시 `KeyRemapper.reload()` 호출 확인
- [ ] 한국어 문구 오탈자·어색함 검수

### Phase 4 완료 시 (패키징)

- [ ] `codesign --verify --deep --strict` 통과
- [ ] `xcrun stapler validate` 통과
- [ ] `spctl --assess --type execute` 통과
- [ ] DMG를 Safari로 다운로드 → 격리 속성 있는 상태에서 더블클릭 → Gatekeeper 경고 없음
- [ ] Applications 폴더로 드래그 → 실행 → 정상 동작
- [ ] DMG 용량 적정 (< 20MB 목표)

## 버그 리포트 형식

`_workspace/qa-bugs.md`에 누적:

```markdown
## BUG-001 — Cmd+0이 Safari에서도 리매핑됨 [blocker]

**재현 절차:**
1. 앱 실행, 접근성 권한 부여
2. Safari 활성화
3. ⌘+0 입력

**기대:** Safari 기본 동작 (확대 축소 원복)
**실제:** Ctrl+2 입력되어 아무 일 없음 (Safari에 Ctrl+2 매핑 없음)

**원인 추정:** `activeBundleID` 체크 누락 가능성. `EventTap/KeyRemapper.swift:127` 확인
**담당:** eventtap-specialist
```

## 자동화 가능한 부분

- Codable 라운드트립 — XCTest로 자동화
- 기본 매핑 값 일관성 — XCTest snapshot
- Info.plist 필수 키 존재 — 빌드 스크립트에 `plutil` 체크

## 자동화 불가(수동) 부분

- 실제 키 리매핑 — HWP 없으면 재현 불가. 사용자 환경에서 체크
- Gatekeeper 경고 — 실제 다운로드 경로 필요 (로컬 파일은 격리 속성 없음)
- 온보딩 이탈률 — 베타 테스터 관찰 필요

## 최종 배포 체크리스트

`_workspace/qa-final-checklist.md`:

- [ ] 버전 번호 일치 (Info.plist CFBundleShortVersionString / appcast.xml / DMG 파일명)
- [ ] README 업데이트 (설치 가이드, 권한 설명)
- [ ] 릴리스 노트 작성
- [ ] appcast.xml Sparkle EdDSA 서명 완료
- [ ] DMG 다운로드 링크 테스트 (실제 사용자 경로 시뮬레이션)
- [ ] 이전 버전에서 자동 업데이트 경로 검증
