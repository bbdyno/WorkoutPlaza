#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_ID="com.bbdyno.app.WorkoutPlaza"
DERIVED_DATA_PATH="$ROOT_DIR/.derivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/WorkoutPlaza.app"
ARTIFACT_ROOT="$ROOT_DIR/artifacts/app-store-marketing"
RAW_DIR="$ARTIFACT_ROOT/raw"
FINAL_DIR="$ARTIFACT_ROOT/final"
DESKTOP_OUTPUT_DIR="$HOME/Desktop/WorkoutPlaza-AppStore-Screens"

typeset -a SCREEN_KEYS=(
  "01-home:home:2.8"
  "02-statistics-all:statistics-all:3.0"
  "03-saved-card-detail:saved-card-detail:2.8"
  "04-climbing-input:climbing-input:2.4"
  "05-running-detail:running-detail:3.4"
)

typeset -a LANGUAGE_SPECS=(
  "en:en_US:(en)"
  "ko:ko_KR:(ko)"
)

typeset -a PHONE_DEVICE_CANDIDATES=(
  "iPhone 17 Pro Max"
  "iPhone Air"
  "iPhone 17 Pro"
  "iPhone 17"
)

typeset -a TABLET_DEVICE_CANDIDATES=(
  "iPad Pro 13-inch (M5)"
  "iPad Air 13-inch (M4)"
)

find_device_udid() {
  local device_name="$1"

  xcrun simctl list devices available |
    grep -F "    $device_name (" |
    grep -v "paired Apple Watch" |
    tail -n 1 |
    sed -E 's/.*\(([0-9A-F-]+)\).*/\1/'
}

find_first_available_device() {
  local device_name
  local device_udid

  for device_name in "$@"; do
    device_udid="$(find_device_udid "$device_name")"
    if [[ -n "$device_udid" ]]; then
      echo "$device_name|$device_udid"
      return 0
    fi
  done

  return 1
}

capture_set() {
  local label="$1"
  local device_name="$2"
  local device_udid="$3"

  mkdir -p "$RAW_DIR/en/$label" "$RAW_DIR/ko/$label"
  rm -f "$RAW_DIR/en/$label"/*(N) "$RAW_DIR/ko/$label"/*(N)

  open -a Simulator >/dev/null 2>&1 || true
  xcrun simctl boot "$device_udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$device_udid" -b

  xcrun simctl status_bar "$device_udid" override \
    --time 9:41 \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --cellularMode notSupported \
    --batteryState charged \
    --batteryLevel 100

  xcrun simctl uninstall "$device_udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl install "$device_udid" "$APP_PATH"

  for language_spec in "${LANGUAGE_SPECS[@]}"; do
    local lang_code="${language_spec%%:*}"
    local language_rest="${language_spec#*:}"
    local apple_locale="${language_rest%%:*}"
    local apple_languages="${language_rest##*:}"

    for screen_spec in "${SCREEN_KEYS[@]}"; do
      local file_name="${screen_spec%%:*}"
      local rest="${screen_spec#*:}"
      local screen_key="${rest%%:*}"
      local wait_seconds="${rest##*:}"

      xcrun simctl terminate "$device_udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
      xcrun simctl launch "$device_udid" "$BUNDLE_ID" \
        -AppleLanguages "$apple_languages" \
        -AppleLocale "$apple_locale" \
        --showcase-screen "$screen_key" >/dev/null

      sleep "$wait_seconds"
      xcrun simctl io "$device_udid" screenshot --type=png --mask=alpha "$RAW_DIR/$lang_code/$label/$file_name.png"
    done
  done

  xcrun simctl terminate "$device_udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl status_bar "$device_udid" clear
  xcrun simctl shutdown "$device_udid" >/dev/null 2>&1 || true

  echo "Captured $label sources from $device_name"
}

mkdir -p "$ARTIFACT_ROOT"
rm -rf "$RAW_DIR" "$FINAL_DIR" "$DESKTOP_OUTPUT_DIR"
mkdir -p "$RAW_DIR" "$FINAL_DIR" "$DESKTOP_OUTPUT_DIR"

cd "$ROOT_DIR"

tuist generate

xcodebuild \
  -workspace WorkoutPlaza.xcworkspace \
  -scheme WorkoutPlaza \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

phone_selection="$(find_first_available_device "${PHONE_DEVICE_CANDIDATES[@]}")"
tablet_selection="$(find_first_available_device "${TABLET_DEVICE_CANDIDATES[@]}")"

if [[ -z "$phone_selection" || -z "$tablet_selection" ]]; then
  echo "Required simulator device is not available." >&2
  exit 1
fi

phone_name="${phone_selection%%|*}"
phone_udid="${phone_selection##*|}"
tablet_name="${tablet_selection%%|*}"
tablet_udid="${tablet_selection##*|}"

capture_set "iPhone-6.5" "$phone_name" "$phone_udid"
capture_set "iPad-13" "$tablet_name" "$tablet_udid"

/usr/bin/swift "$ROOT_DIR/scripts/render_app_store_marketing.swift" \
  --sources "$RAW_DIR" \
  --output "$FINAL_DIR"

for locale in en ko; do
  sips -z 2778 1284 "$FINAL_DIR/$locale/iPhone-6.5"/*.png >/dev/null
  sips -z 2752 2064 "$FINAL_DIR/$locale/iPad-13"/*.png >/dev/null
done

cp -R "$FINAL_DIR"/. "$DESKTOP_OUTPUT_DIR"/

echo "Rendered localized App Store screenshots to $FINAL_DIR"
echo "Copied localized App Store screenshots to $DESKTOP_OUTPUT_DIR"
