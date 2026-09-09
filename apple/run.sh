#!/usr/bin/env bash
# Build, install and launch on the Simulator without touching Xcode.
#
#   ./run.sh              build, launch
#   ./run.sh shot         build, launch, save a screenshot to shot.png
#   ./run.sh shot out.png build, launch, save a screenshot to out.png
#
# Xcode still has to exist — this drives its command-line tools. The win is
# that a build, a launch and a screenshot become one command you can repeat.
set -euo pipefail
cd "$(dirname "$0")"

DEVICE="${DEVICE:-iPhone 17 Pro}"
SCHEME="Mood"
BUNDLE_ID="com.nodedesignagency.Mood"
BUILD_DIR="build"
APP="$BUILD_DIR/Build/Products/Debug-iphonesimulator/$SCHEME.app"

echo "▸ Building for $DEVICE"
# `| xcbeautify` is nicer if you have it; grep keeps the noise down without it.
xcodebuild \
  -project "$SCHEME.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -derivedDataPath "$BUILD_DIR" \
  -quiet \
  build

# `simctl boot` errors if the device is already up, which is not a failure.
echo "▸ Booting"
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" -b >/dev/null 2>&1 || true
open -a Simulator

echo "▸ Installing"
xcrun simctl install booted "$APP"

echo "▸ Launching"
# Terminate first so a relaunch always picks up the new build.
xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch booted "$BUNDLE_ID" >/dev/null

if [ "${1:-}" = "shot" ]; then
  OUT="${2:-shot.png}"
  # The launch returns before the first frame is on screen.
  sleep 2
  xcrun simctl io booted screenshot "$OUT"
  echo "▸ Saved $OUT"
fi

echo "✓ Done"
