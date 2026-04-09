#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_ID="com.bbdyno.app.WorkoutPlaza"
DERIVED_DATA_PATH="$ROOT_DIR/.derivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/WorkoutPlaza.app"
BASE_OUTPUT_DIR="$ROOT_DIR/app-store-screens"
DESKTOP_OUTPUT_DIR="$HOME/Desktop/WorkoutPlaza-AppStore-Screens"

typeset -a SCREEN_KEYS=(
  "01-home:home:2.8"
  "02-statistics-all:statistics-all:3.0"
  "03-saved-card-detail:saved-card-detail:2.8"
  "04-climbing-input:climbing-input:2.4"
  "05-running-detail:running-detail:3.4"
)

find_device_udid() {
  local device_name="$1"

  xcrun simctl list devices available |
    grep -F "    $device_name (" |
    grep -v "paired Apple Watch" |
    tail -n 1 |
    sed -E 's/.*\(([0-9A-F-]+)\).*/\1/'
}

capture_set() {
  local label="$1"
  local device_name="$2"
  local output_dir="$BASE_OUTPUT_DIR/$label"
  local desktop_dir="$DESKTOP_OUTPUT_DIR/$label"
  local device_udid

  device_udid="$(find_device_udid "$device_name")"

  if [[ -z "$device_udid" ]]; then
    echo "Device not found: $device_name" >&2
    exit 1
  fi

  mkdir -p "$output_dir" "$desktop_dir"
  rm -f "$output_dir"/* "$desktop_dir"/*

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

  xcrun simctl uninstall "$device_udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl install "$device_udid" "$APP_PATH"

  for screen_spec in "${SCREEN_KEYS[@]}"; do
    local file_name="${screen_spec%%:*}"
    local rest="${screen_spec#*:}"
    local screen_key="${rest%%:*}"
    local wait_seconds="${rest##*:}"

    xcrun simctl terminate "$device_udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$device_udid" "$BUNDLE_ID" \
      -AppleLanguages "(en)" \
      -AppleLocale en_US \
      --showcase-screen "$screen_key" >/dev/null

    sleep "$wait_seconds"
    xcrun simctl io "$device_udid" screenshot --type=jpeg "$output_dir/$file_name.jpg"
  done

  cp "$output_dir"/*.jpg "$desktop_dir"/

  xcrun simctl terminate "$device_udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl status_bar "$device_udid" clear
}

mkdir -p "$BASE_OUTPUT_DIR" "$DESKTOP_OUTPUT_DIR"

cd "$ROOT_DIR"

tuist generate

xcodebuild \
  -workspace WorkoutPlaza.xcworkspace \
  -scheme WorkoutPlaza \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

capture_set "iPhone-6.5" "iPhone 11 Pro Max"
capture_set "iPad-13" "iPad Pro 13-inch (M5)"

echo "Captured App Store screenshots to $BASE_OUTPUT_DIR"
echo "Copied App Store screenshots to $DESKTOP_OUTPUT_DIR"
