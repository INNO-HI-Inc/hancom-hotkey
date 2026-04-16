#!/usr/bin/env bash
# Generate AppIcon PNGs from SVG and produce .icns + asset catalog PNGs.
# Requires: rsvg-convert (brew install librsvg)
set -euo pipefail

cd "$(dirname "$0")/.."

SRC_SVG="assets/icon.svg"
MASTER_PNG="assets/icon_master_1024.png"
ICONSET_DIR="assets/AppIcon.iconset"
OUT_ICNS="assets/AppIcon.icns"
APPICON_DIR="src/Resources/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$SRC_SVG" ]; then
  echo "ERROR: missing $SRC_SVG" >&2
  exit 1
fi
if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "ERROR: install rsvg-convert (brew install librsvg)" >&2
  exit 1
fi

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR" "$APPICON_DIR"

# Master PNG.
rsvg-convert -w 1024 -h 1024 "$SRC_SVG" -o "$MASTER_PNG"

# name=pixels pairs (bash 3 compatible).
TARGETS=(
  "icon_16x16.png:16"
  "icon_16x16@2x.png:32"
  "icon_32x32.png:32"
  "icon_32x32@2x.png:64"
  "icon_128x128.png:128"
  "icon_128x128@2x.png:256"
  "icon_256x256.png:256"
  "icon_256x256@2x.png:512"
  "icon_512x512.png:512"
  "icon_512x512@2x.png:1024"
)

for entry in "${TARGETS[@]}"; do
  name="${entry%%:*}"
  px="${entry##*:}"
  rsvg-convert -w "$px" -h "$px" "$SRC_SVG" -o "$ICONSET_DIR/$name"
done

# Build .icns.
iconutil -c icns -o "$OUT_ICNS" "$ICONSET_DIR"

# Sync into Xcode asset catalog.
for entry in "${TARGETS[@]}"; do
  name="${entry%%:*}"
  cp "$ICONSET_DIR/$name" "$APPICON_DIR/$name"
done

echo "OK: icns=$OUT_ICNS  appiconset=$APPICON_DIR"
