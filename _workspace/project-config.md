# 한컴단축키 — 프로젝트 설정

## 앱 정보
- **표시 이름 (한국어)**: 한컴단축키
- **내부/번들 이름 (영문)**: HancomHotkey
- **Bundle ID**: `com.innohi.hancomhotkey`
- **최소 macOS**: 13.0
- **초기 버전**: 0.1.0

## Apple Developer 정보
- **법인**: INNO-HI Inc.
- **Team ID**: `4AL4PF4BK4`
- **등록 유형**: 조직 (Organization)
- **계정 소유자**: MINWOO HAN
- **갱신일**: 2027-03-25

## Phase 3 (패키징) 시 추가로 필요한 정보
- [x] **Apple ID 이메일**: `board@innohi.ai.kr`
- [x] **App-specific password 생성 완료** — 이름 `HancomHotkey`
- [x] **notarytool keychain profile 등록 완료** (프로필 이름: `HancomHotkey`)
  ```
  xcrun notarytool store-credentials "HancomHotkey" \
    --apple-id "board@innohi.ai.kr" \
    --team-id "4AL4PF4BK4" \
    --password "<앱-암호>"
  ```
  ※ 프로필 이름은 앱 암호 이름과 동일하게 `HancomHotkey` 사용

## 코드사이닝 인증서
- [x] **Developer ID Application: INNO-HI Inc. (4AL4PF4BK4)** 설치 완료
  - SHA1: `D9FD6730A4BE6FF670103495CEE83DCAC7A742DF`

## 배포 채널
- **Phase 1**: 직판 DMG (INNO-HI 웹사이트 또는 GitHub Releases)
- **Phase 2 (옵션)**: Setapp 입점
- **Sparkle 자동 업데이트**: 도입 (Phase 3에서 EdDSA 키 생성)
