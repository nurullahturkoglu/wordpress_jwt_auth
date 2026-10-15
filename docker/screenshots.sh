#!/usr/bin/env bash
# Captures the README screenshots from the iOS simulator and the Android
# emulator. Expects docker/setup.sh to have run and both devices to be booted.
set -euo pipefail
cd "$(dirname "$0")/../example"
OUT="${OUT:-../screenshots}"
mkdir -p "$OUT"

IOS_DEVICE="${IOS_DEVICE:-iPhone 15 Pro}"
IOS_BUNDLE="com.example.flutterJwtAuth"
ANDROID_PACKAGE="com.example.flutter_jwt_auth"
ADB="${ADB:-${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb}"

until xcrun simctl list devices booted | grep -q "$IOS_DEVICE"; do sleep 3; done
until [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 3; done

PLATFORMS="${PLATFORMS:-ios android}"
PAGES="${PAGES:-login:/login register:/register home:/ profile:/profile books:/book}"

for entry in $PAGES; do
  name="${entry%%:*}"; route="${entry#*:}"

  if [[ " $PLATFORMS " == *" ios "* ]]; then
  flutter build ios --simulator --debug -t lib/main_screenshots.dart \
    --dart-define=WP_BASE_URL=http://localhost:8080 \
    --dart-define=SCREENSHOT_ROUTE="$route" >/dev/null
  xcrun simctl install "$IOS_DEVICE" build/ios/iphonesimulator/Runner.app
  xcrun simctl launch "$IOS_DEVICE" "$IOS_BUNDLE" >/dev/null
  sleep 6
  xcrun simctl io "$IOS_DEVICE" screenshot "$OUT/ios-$name.png" >/dev/null
  xcrun simctl terminate "$IOS_DEVICE" "$IOS_BUNDLE"
  fi

  if [[ " $PLATFORMS " == *" android "* ]]; then
  flutter build apk --debug -t lib/main_screenshots.dart \
    --dart-define=WP_BASE_URL=http://10.0.2.2:8080 \
    --dart-define=SCREENSHOT_ROUTE="$route" >/dev/null
  "$ADB" uninstall "$ANDROID_PACKAGE" >/dev/null 2>&1 || true
  "$ADB" install build/app/outputs/flutter-apk/app-debug.apk >/dev/null
  "$ADB" shell am start -n "$ANDROID_PACKAGE/.MainActivity" >/dev/null
  # A cold debug start on the emulator can take a while; the launch screen
  # compresses to a few KB, so keep capturing until the real page is drawn.
  for _ in $(seq 1 30); do
    sleep 3
    "$ADB" exec-out screencap -p > "$OUT/android-$name.png"
    [ "$(stat -f %z "$OUT/android-$name.png")" -gt 60000 ] && break
  done
  sleep 2
  "$ADB" exec-out screencap -p > "$OUT/android-$name.png"
  "$ADB" shell am force-stop "$ANDROID_PACKAGE"
  fi

  echo "captured $name"
done
