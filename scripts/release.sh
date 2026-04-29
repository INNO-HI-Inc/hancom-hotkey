#!/usr/bin/env bash
# Full release pipeline: archive → export → notarize → staple → DMG → sign DMG → staple DMG → Sparkle sign → appcast entry.
# Usage: scripts/release.sh <version>   (e.g. scripts/release.sh 0.4.0)
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?usage: $0 <version>}"
TEAM_ID="${TEAM_ID:-4AL4PF4BK4}"
NOTARY_PROFILE="${NOTARY_PROFILE:-HancomHotkey}"
SPARKLE_BIN="${SPARKLE_BIN:-/tmp/sparkle/bin}"
APP_NAME="HancomHotkey"
DISPLAY_NAME="한컴단축키"
BUNDLE_ID="com.innohi.hancomhotkey"
SIGN_ID="Developer ID Application: INNO-HI Inc. (${TEAM_ID})"
DOWNLOAD_BASE_URL="${DOWNLOAD_BASE_URL:-https://github.com/INNO-HI-Inc/hancom-hotkey/releases/download}"

ARCHIVE_PATH="build/${APP_NAME}.xcarchive"
EXPORT_DIR="build/export"
EXPORT_OPTS="build/ExportOptions.plist"
APP_PATH="${EXPORT_DIR}/${APP_NAME}.app"
ZIP_FOR_NOTARY="build/${APP_NAME}.zip"
STAGING_DIR="build/dmg-staging"
DMG_OUT="dist/${APP_NAME}-${VERSION}.dmg"
APPCAST_DIR="site"
APPCAST_FILE="${APPCAST_DIR}/appcast.xml"

log() { printf "\n\033[1;34m[release]\033[0m %s\n" "$*"; }

log "0) Prepare"
mkdir -p build dist "$APPCAST_DIR"
rm -rf build/derived "$ARCHIVE_PATH" "$EXPORT_DIR" "$STAGING_DIR" "$ZIP_FOR_NOTARY" "$DMG_OUT"

# Detach any stale DMG mounts that interfere with create-dmg.
for dev in $(hdiutil info | awk '/\/Volumes\/(dmg\.|한컴단축키 )/{print prev} {prev=$1}' | grep -E '^/dev/disk[0-9]+' | sort -u); do
  hdiutil detach "$dev" -force >/dev/null 2>&1 || true
done

log "1) Regenerate Xcode project"
xcodegen generate

log "2) Archive (MARKETING_VERSION=$VERSION)"
xcodebuild \
  -project HancomHotkey.xcodeproj \
  -scheme "$APP_NAME" \
  -configuration Release \
  -destination "platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$(date +%Y%m%d%H%M)" \
  archive

log "3) Export (Developer ID)"
cat > "$EXPORT_OPTS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>developer-id</string>
  <key>teamID</key><string>${TEAM_ID}</string>
  <key>signingStyle</key><string>manual</string>
  <key>signingCertificate</key><string>Developer ID Application</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTS"

log "4) Verify signature"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

log "5) Submit app for notarization"
/usr/bin/ditto -c -k --keepParent "$APP_PATH" "$ZIP_FOR_NOTARY"
xcrun notarytool submit "$ZIP_FOR_NOTARY" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

log "6) Staple ticket"
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

log "7) Stage DMG layout"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/$DISPLAY_NAME.app"

log "8) Create DMG"
create-dmg \
  --volname "$DISPLAY_NAME $VERSION" \
  --volicon "assets/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 128 \
  --icon "$DISPLAY_NAME.app" 150 200 \
  --hide-extension "$DISPLAY_NAME.app" \
  --app-drop-link 450 200 \
  --no-internet-enable \
  "$DMG_OUT" \
  "$STAGING_DIR" || {
    if [ ! -f "$DMG_OUT" ]; then
      echo "FATAL: DMG not created" >&2
      exit 1
    fi
    log "create-dmg exited non-zero (likely cosmetics); DMG exists, continuing"
  }

log "9) Sign DMG"
codesign --sign "$SIGN_ID" --timestamp "$DMG_OUT"

log "10) Submit DMG for notarization"
xcrun notarytool submit "$DMG_OUT" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

log "11) Staple DMG"
xcrun stapler staple "$DMG_OUT"
xcrun stapler validate "$DMG_OUT"

log "12) Gatekeeper check"
spctl --assess --type open --context context:primary-signature --verbose "$DMG_OUT" || true

log "13) Sparkle EdDSA signature"
if [ -x "$SPARKLE_BIN/sign_update" ]; then
  SIG_OUTPUT=$("$SPARKLE_BIN/sign_update" "$DMG_OUT")
  echo "  $SIG_OUTPUT"
  SPARKLE_SIG=$(echo "$SIG_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')
  SPARKLE_LEN=$(echo "$SIG_OUTPUT" | sed -n 's/.*length="\([^"]*\)".*/\1/p')
  if [ -z "$SPARKLE_SIG" ] || [ -z "$SPARKLE_LEN" ]; then
    echo "WARN: could not parse Sparkle signature output" >&2
  fi
else
  echo "WARN: Sparkle tools not found at $SPARKLE_BIN. Skipping signature." >&2
  echo "      Install via: curl -L https://github.com/sparkle-project/Sparkle/releases/download/2.7.2/Sparkle-2.7.2.tar.xz | tar -xJ -C /tmp/sparkle" >&2
  SPARKLE_SIG=""
  SPARKLE_LEN=""
fi

log "14) Update appcast.xml"
DMG_FILENAME=$(basename "$DMG_OUT")
PUB_DATE=$(date -u "+%a, %d %b %Y %H:%M:%S +0000")
ENCLOSURE_URL="${DOWNLOAD_BASE_URL}/v${VERSION}/${DMG_FILENAME}"

python3 scripts/update_appcast.py \
  --appcast "$APPCAST_FILE" \
  --version "$VERSION" \
  --build "$(date +%Y%m%d%H%M)" \
  --dmg-path "$DMG_OUT" \
  --enclosure-url "$ENCLOSURE_URL" \
  --pub-date "$PUB_DATE" \
  --signature "$SPARKLE_SIG" \
  --length "$SPARKLE_LEN"

log "15) Mirror DMG as -latest.dmg (stable URL for landing page)"
DMG_LATEST="dist/${APP_NAME}-latest.dmg"
cp "$DMG_OUT" "$DMG_LATEST"

echo
echo "✅ Release ready: $DMG_OUT"
ls -lh "$DMG_OUT" "$DMG_LATEST"
echo
echo "Next:"
echo "  1. Create GitHub release tag v${VERSION}, upload BOTH:"
echo "       - $DMG_OUT"
echo "       - $DMG_LATEST   (powers https://.../releases/latest/download/${APP_NAME}-latest.dmg)"
echo "  2. Commit and push ${APPCAST_FILE} to the gh-pages branch (or publish directory)"
echo "  3. Users on prior versions will auto-discover the update within 24 h"
