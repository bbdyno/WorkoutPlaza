#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE_NAME="${1:-iPhone Air}"
BUNDLE_ID="com.bbdyno.app.WorkoutPlaza"
DERIVED_DATA_PATH="$ROOT_DIR/.derivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/WorkoutPlaza.app"
SCREEN_DIR="$ROOT_DIR/docs/assets/screens"

device_udid="$(
  xcrun simctl list devices available |
    grep -F "$DEVICE_NAME (" |
    grep -v "paired Apple Watch" |
    head -n 1 |
    sed -E 's/.*\(([0-9A-F-]+)\).*/\1/'
)"

if [[ -z "$device_udid" ]]; then
  echo "Device not found: $DEVICE_NAME" >&2
  exit 1
fi

mkdir -p "$SCREEN_DIR"

cd "$ROOT_DIR"

open -a Simulator >/dev/null 2>&1 || true
xcrun simctl boot "$device_udid" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$device_udid" -b

xcrun simctl status_bar "$device_udid" override \
  --time 12:38 \
  --dataNetwork wifi \
  --wifiMode active \
  --wifiBars 3 \
  --cellularMode notSupported \
  --batteryState charged \
  --batteryLevel 100

tuist generate

xcodebuild \
  -workspace WorkoutPlaza.xcworkspace \
  -scheme WorkoutPlaza \
  -destination "platform=iOS Simulator,id=$device_udid" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

xcrun simctl uninstall "$device_udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$device_udid" "$APP_PATH"

capture_screen() {
  local screen="$1"
  local output="$2"
  local wait_seconds="${3:-2.8}"

  xcrun simctl terminate "$device_udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch "$device_udid" "$BUNDLE_ID" \
    -AppleLanguages "(en)" \
    -AppleLocale en_US \
    --showcase-screen "$screen" >/dev/null

  sleep "$wait_seconds"
  xcrun simctl io "$device_udid" screenshot --type=png --mask=alpha "$SCREEN_DIR/$output"
}

capture_screen "home" "home-framed.png" 2.8
capture_screen "statistics-all" "statistics-all-framed.png" 3.0
capture_screen "saved-card-detail" "saved-card-detail-framed.png" 2.8
capture_screen "climbing-input" "climbing-input-framed.png" 2.4
capture_screen "running-detail" "running-detail-framed.png" 3.4

xcrun simctl terminate "$device_udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl status_bar "$device_udid" clear

echo "Captured showcase screens to $SCREEN_DIR"
