#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Handy"
BUNDLE_ID="com.justin.handy.native"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
for _ in {1..30}; do
  if ! pgrep -x "$APP_NAME" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  echo "failed to stop existing $APP_NAME process" >&2
  exit 1
fi

swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
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
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

open_app() {
  /usr/bin/open -n "$APP_BUNDLE" --args --demo "${HANDY_DEMO_STATE:-mouse}"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    export HANDY_DEMO_STATE="${HANDY_DEMO_STATE:-default}"
    open_app
    VISIBLE_WINDOW_COUNT="0"
    APP_PID=""
    for _ in {1..40}; do
      APP_PID="$(pgrep -x "$APP_NAME" | head -n 1)"
      if [[ -n "$APP_PID" ]]; then
        VISIBLE_WINDOW_COUNT="$(APP_PID="$APP_PID" /usr/bin/swift -e 'import CoreGraphics; import Foundation; let pid = Int32(ProcessInfo.processInfo.environment["APP_PID"] ?? "") ?? -1; let windows = (CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]]) ?? []; let count = windows.filter { window in guard (window[kCGWindowOwnerPID as String] as? Int32) == pid, let bounds = window[kCGWindowBounds as String] as? [String: Any] else { return false }; let width = bounds["Width"] as? Double ?? 0; let height = bounds["Height"] as? Double ?? 0; return width > 300 && height > 300 }.count; print(count)')"
        if [[ "$VISIBLE_WINDOW_COUNT" != "0" ]]; then
          break
        fi
      fi
      sleep 0.1
    done
    test -n "$APP_PID"
    if [[ "$VISIBLE_WINDOW_COUNT" == "0" ]]; then
      echo "$APP_NAME process is running but no onscreen main window is visible" >&2
      exit 1
    fi
    echo "$APP_NAME running pid=$APP_PID visibleWindows=$VISIBLE_WINDOW_COUNT bundle=$APP_BUNDLE"
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
