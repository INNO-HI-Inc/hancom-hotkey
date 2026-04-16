# 한컴단축키 0.1.0 최종 QA 체크리스트

**생성일**: 2026-04-16
**산출물**: `dist/HancomHotkey-0.1.0.dmg` (321 KB)

## 서명 & 공증

| 항목 | 결과 |
|---|---|
| DMG 서명 권한 | Developer ID Application: INNO-HI Inc. (4AL4PF4BK4) ✓ |
| DMG 공증 | Accepted (submission 90950fc1-c954-401f-ac06-45e84d7e1c67) ✓ |
| DMG staple | validated ✓ |
| DMG Gatekeeper | accepted / source=Notarized Developer ID ✓ |
| 앱 서명 (deep strict) | valid + satisfies Designated Requirement ✓ |
| 앱 공증 ticket | stapled ✓ |
| 앱 Gatekeeper | accepted / source=Notarized Developer ID ✓ |
| Hardened Runtime | enabled ✓ |

## 바이너리

| 항목 | 값 |
|---|---|
| Bundle ID | `com.innohi.hancomhotkey` |
| 표시 이름 | 한컴단축키 |
| 내부 실행명 | HancomHotkey |
| CFBundleShortVersionString | 0.1.0 |
| CFBundleVersion | 202604161446 |
| 최소 OS | macOS 13.0 |
| 아키텍처 | Universal (x86_64 + arm64) ✓ |
| 앱 사이즈 | 588 KB |
| 엔타이틀먼트 | `com.apple.security.automation.apple-events=false` (최소 권한) |
| LSUIElement | true (Dock 미표시) ✓ |

## 기능 커버리지 (코드 레벨)

| 기능 | 구현 위치 |
|---|---|
| CGEventTap 생성 + runloop 등록 | `src/EventTap/KeyRemapper.swift` |
| `tapDisabledByTimeout` 자동 재활성 | `KeyRemapper.process` |
| Secure Input 감지 시 리매핑 스킵 | `KeyRemapper.process` |
| HWP 번들 ID 활성 시에만 매핑 | `MappingRule.targetBundleID` + `ActiveAppMonitor` |
| 모디파이어 flags 직접 교체 (Cmd 릴리즈 대기 불필요) | `KeyRemapper.process` |
| 매핑 변경 시 즉시 재캐시 | `NotificationCenter` + `keyMappingDidChange` |
| 접근성 권한 폴링 (0.5s) | `src/Permission/PermissionMonitor.swift` |
| 시스템 설정 딥링크 | `PermissionMonitor.openSystemSettings` |
| 로그인 자동 실행 (SMAppService) | `src/Settings/GeneralTabView.swift` |
| 메뉴바 상태 아이콘 (권한/활성 상태별) | `src/MenuBar/MenuBarController.swift` |
| 설정 윈도우 3탭 | `src/Settings/SettingsRootView.swift` |
| 온보딩 + 완료 화면 | `src/Onboarding/OnboardingView.swift` |

## 사용자 수동 검증 필요 항목 (배포 후)

다운로드한 DMG에 대해 실제 사용자 환경에서 아래 절차로 최종 검증 권장:

1. **다운로드 경로 재현**
   - Safari 또는 Chrome으로 다운로드 (격리 속성 부여됨)
   - `xattr -p com.apple.quarantine dist/HancomHotkey-0.1.0.dmg` 로 속성 확인
   - 더블클릭 시 Gatekeeper 경고 없이 마운트되어야 함
2. **설치 플로우**
   - DMG 마운트 → `한컴단축키.app` → `Applications` 드래그
   - Launchpad에서 실행
3. **온보딩 플로우**
   - 첫 실행 시 온보딩 화면 표시
   - [시스템 설정 열기] 클릭 → 접근성 목록에 "한컴단축키" 노출
   - 체크 → 앱 자동으로 "준비 완료" 상태 전환
4. **HWP 매핑 실동작**
   - 한글(HWP) 실행 후 문서 열기
   - `⌘+0` → 본문 가. 스타일 적용 (스타일창에서 확인)
   - `⌘+1~4` → 각각의 스타일 적용
5. **매핑 비활성 확인**
   - Safari 활성 후 `⌘+0` → 페이지 확대 축소 (macOS 기본 동작 유지)
   - 로그인 창 등 Secure Input 상태에서는 매핑 비활성
6. **지속성**
   - 앱 10분 이상 켜두고 간헐적 사용 → 매핑 지속 동작
   - 재부팅 후 자동 실행 (설정에서 켰을 때)

## 배포 준비 완료 여부

- [x] 서명 ✓
- [x] 공증 ✓
- [x] Staple ✓
- [x] Gatekeeper 통과 ✓
- [x] Universal binary ✓
- [x] Info.plist 필수 키 ✓
- [x] 최소 OS 지정 ✓
- [x] README.md ✓
- [x] CHANGELOG.md ✓
- [ ] 사용자 실기 검증 (HWP 설치된 환경에서)
- [ ] 공개 다운로드 URL 준비 (웹사이트 / GitHub Releases)
- [ ] (선택) Sparkle appcast.xml 호스팅
