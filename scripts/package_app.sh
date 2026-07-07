#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
APP_NAME="TouchDeck"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
BUILD_PRODUCT="$ROOT_DIR/.build/$CONFIGURATION/$APP_NAME"

cd "$ROOT_DIR"

swift build -c "$CONFIGURATION" --product "$APP_NAME"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_PRODUCT" "$MACOS_DIR/$APP_NAME"
cp "$ROOT_DIR/Packaging/Info.plist" "$CONTENTS_DIR/Info.plist"
printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

chmod +x "$MACOS_DIR/$APP_NAME"

if [[ "${CODESIGN_IDENTITY:-}" != "" ]]; then
  codesign \
    --force \
    --options runtime \
    --entitlements "$ROOT_DIR/Packaging/TouchDeck.entitlements" \
    --sign "$CODESIGN_IDENTITY" \
    "$APP_DIR"
else
  codesign --force --sign - "$APP_DIR" >/dev/null 2>&1 || true
fi

echo "$APP_DIR"
