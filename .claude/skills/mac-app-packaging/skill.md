---
name: mac-app-packaging
description: macOS 앱을 Developer ID로 서명하고 Apple 공증을 받은 후 Gatekeeper 통과 가능한 DMG로 패키징한다. xcodebuild archive/exportArchive, codesign, notarytool, create-dmg, Sparkle 자동 업데이트 설정. DMG 배포 준비 작업 시 반드시 사용.
---

# macOS 앱 패키징·배포 패턴

## 언제 사용하는가

완성된 Swift 앱을 Gatekeeper 통과 가능한 DMG로 만들 때. `packaging-engineer` 에이전트가 주요 소비자.

## 사전 준비 (사용자가 직접 수행)

앱을 생성하는 에이전트가 대신할 수 없는 작업. 진행 전 사용자에게 확인:

1. **Apple Developer Program 가입** ($99/년)
2. **Developer ID Application 인증서** 발급 → 로컬 Keychain에 설치
3. **App-specific password** 생성 (appleid.apple.com → 보안 → 앱 암호)
4. **notarytool keychain profile 저장**:
   ```bash
   xcrun notarytool store-credentials "HwpUtilityNotary" \
     --apple-id "your@email.com" \
     --team-id "TEAM1234XX" \
     --password "xxxx-xxxx-xxxx-xxxx"
   ```

사용자가 이 준비를 안 했다면 스킬 진행을 멈추고 체크리스트를 보여준다.

## 빌드 스크립트

### scripts/build.sh (로컬 디버그 빌드)

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

xcodebuild -project HwpUtility.xcodeproj \
  -scheme HwpUtility \
  -configuration Debug \
  -derivedDataPath build/derived \
  build

echo "Build complete: build/derived/Build/Products/Debug/HwpUtility.app"
```

### scripts/release.sh (서명+공증+DMG 전체 파이프라인)

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?usage: release.sh <version>}"
TEAM_ID="${TEAM_ID:?set TEAM_ID env var}"
NOTARY_PROFILE="${NOTARY_PROFILE:-HwpUtilityNotary}"
APP_NAME="HwpUtility"
BUNDLE_ID="com.yourcompany.hwputility"

ARCHIVE_PATH="build/${APP_NAME}.xcarchive"
EXPORT_PATH="build/export"
DMG_OUT="dist/${APP_NAME}-${VERSION}.dmg"

rm -rf build/ dist/
mkdir -p build dist

# 1) Archive
xcodebuild -project ${APP_NAME}.xcodeproj \
  -scheme ${APP_NAME} \
  -configuration Release \
  -archivePath "${ARCHIVE_PATH}" \
  archive

# 2) Export (Developer ID)
cat > build/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>developer-id</string>
  <key>teamID</key><string>${TEAM_ID}</string>
  <key>signingStyle</key><string>automatic</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist build/ExportOptions.plist

APP_PATH="${EXPORT_PATH}/${APP_NAME}.app"

# 3) 서명 검증
codesign --verify --deep --strict --verbose=2 "${APP_PATH}"

# 4) Notarize (zip으로 submit)
ZIP_PATH="build/${APP_NAME}.zip"
/usr/bin/ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"

xcrun notarytool submit "${ZIP_PATH}" \
  --keychain-profile "${NOTARY_PROFILE}" \
  --wait

# 5) Staple
xcrun stapler staple "${APP_PATH}"
xcrun stapler validate "${APP_PATH}"

# 6) DMG 생성 (create-dmg 권장; brew install create-dmg)
create-dmg \
  --volname "${APP_NAME} ${VERSION}" \
  --volicon "assets/dmg-icon.icns" \
  --background "assets/dmg-background.png" \
  --window-size 600 400 \
  --icon "${APP_NAME}.app" 150 200 \
  --app-drop-link 450 200 \
  --hdiutil-quiet \
  "${DMG_OUT}" \
  "${APP_PATH}"

# 7) DMG 서명 + staple
codesign --sign "Developer ID Application: YOUR NAME (${TEAM_ID})" \
  --timestamp "${DMG_OUT}"
xcrun stapler staple "${DMG_OUT}"

echo "✓ Release built: ${DMG_OUT}"
```

## Hardened Runtime + 엔타이틀먼트

`HwpUtility.entitlements` 최소 구성:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.automation.apple-events</key><false/>
</dict>
</plist>
```

Xcode 타깃:
- **Enable Hardened Runtime**: YES (공증 필수 조건)
- **Code Signing Style**: Automatic
- **Team**: (사용자 개발자 팀)

샌드박스는 사용하지 않는다 (`com.apple.security.app-sandbox` 키 없음).

## Sparkle 자동 업데이트 (선택)

1. SwiftPM 의존성 추가: `https://github.com/sparkle-project/Sparkle`
2. EdDSA 서명 키 생성: `sparkle/bin/generate_keys`
3. `Info.plist`에 `SUFeedURL`, `SUPublicEDKey` 추가
4. 릴리스마다 `sparkle/bin/sign_update HwpUtility.dmg` 실행 → `appcast.xml` 업데이트

## 배포 채널

- **직판**: 정적 웹사이트(랜딩 + 다운로드 링크 + appcast.xml 호스팅). GitHub Pages도 가능
- **Setapp**: 별도 심사. `Setapp 입점 가이드 (Mac developers)` 기준으로 SDK 통합 필요. 심사 3~6주

## 에러 패턴

| 증상 | 원인 | 조치 |
|------|------|------|
| `codesign` 실패 "no identity found" | 인증서 미설치 | `security find-identity -v -p codesigning`로 확인 |
| notarytool "Invalid" | Hardened Runtime 미활성 | Xcode 타깃 설정에서 활성화 후 재아카이브 |
| notarytool "Unsigned" | 서명되지 않은 dylib 포함 | `codesign --force --deep`로 재서명 |
| Gatekeeper 경고 표시 | Staple 누락 | `stapler staple` 실행 후 재검증 |
| DMG 마운트 실패 | 생성 중 리소스 누락 | `hdiutil attach -verbose ...` 로그 확인 |

## 참고

- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing_the_notarization_workflow)
- [create-dmg](https://github.com/create-dmg/create-dmg)
- [Sparkle](https://sparkle-project.org/documentation/)
