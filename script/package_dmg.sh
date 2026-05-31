#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Handy"
BUNDLE_ID="com.justin.handy.native"
MIN_SYSTEM_VERSION="14.0"
APP_VERSION="${APP_VERSION:-0.1.0}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
STAGE_DIR="$DIST_DIR/dmg-stage"
DMG_PATH="$DIST_DIR/$APP_NAME-$APP_VERSION.dmg"

rm -rf "$APP_BUNDLE" "$STAGE_DIR" "$DMG_PATH"
mkdir -p "$APP_MACOS" "$STAGE_DIR"

swift build -c release
BUILD_BINARY="$(swift build -c release --show-bin-path)/$APP_NAME"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_VERSION</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
  /usr/bin/codesign --force --deep --sign - "$APP_BUNDLE"
else
  /usr/bin/codesign --force --deep --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP_BUNDLE"
fi

/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

cp -R "$APP_BUNDLE" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

/usr/bin/hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

/usr/bin/hdiutil verify "$DMG_PATH"

echo "Created $DMG_PATH"
