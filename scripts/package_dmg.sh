#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="TouchDeck"
VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$ROOT_DIR/Packaging/Info.plist")"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
DMG_STAGING_DIR="$DIST_DIR/dmg-staging"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"
VOLUME_NAME="$APP_NAME $VERSION"

cd "$ROOT_DIR"

"$ROOT_DIR/scripts/package_app.sh"

rm -rf "$DMG_STAGING_DIR" "$DMG_PATH"
mkdir -p "$DMG_STAGING_DIR"

cp -R "$APP_DIR" "$DMG_STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING_DIR/Applications"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

hdiutil verify "$DMG_PATH" >/dev/null

echo "$DMG_PATH"
