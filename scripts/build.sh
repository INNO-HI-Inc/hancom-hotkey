#!/usr/bin/env bash
# Local debug build. Outputs an unsigned Debug .app for quick iteration.
set -euo pipefail
cd "$(dirname "$0")/.."

xcodegen generate
xcodebuild \
  -project HancomHotkey.xcodeproj \
  -scheme HancomHotkey \
  -configuration Debug \
  -derivedDataPath build/derived \
  -destination "platform=macOS" \
  build

APP_PATH="build/derived/Build/Products/Debug/HancomHotkey.app"
echo "OK: $APP_PATH"
