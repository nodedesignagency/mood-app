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
BUNDLE_ID="${BUNDLE_ID:-com.nodedesignagency.Mood}"
BUILD_DIR="build"

# Find the project rather than assuming where it sits: Xcode wraps a new
# project in a folder of its own, so it lands a level deeper than you'd expect.
PROJECT="$(find . -maxdepth 3 -name '*.xcodeproj' -not -path './build/*' -print -quit)"
if [ -z "$PROJECT" ]; then
  echo "✗ No .xcodeproj found under $(pwd)." >&2
  echo "  Create one in Xcode (File → New → Project → iOS App) first." >&2
  exit 1
fi
SCHEME="$(basename "$PROJECT" .xcodeproj)"

# Xcode's "Add Files" dialog defaults to "Copy files to destination", which
# silently duplicates the sources inside the project folder. The build then
# compiles the copy while git updates the original, and every change appears
# to do nothing. Catch it here rather than after a confusing build failure.
DUPES="$(find . -path ./Sources -prune -o -type d -name Sources -print 2>/dev/null)"
if [ -n "$DUPES" ]; then
  echo "✗ A second copy of Sources exists:" >&2
  echo "$DUPES" | sed 's/^/    /' >&2
  echo "  Xcode is probably compiling that instead of ./Sources, so pulled" >&2
  echo "  changes will not take effect. Delete it, then re-add ./Sources in" >&2
  echo "  Xcode with Action set to 'Reference files in place'." >&2
  exit 1
fi
APP="$BUILD_DIR/Build/Products/Debug-iphonesimulator/$SCHEME.app"

echo "▸ Building $SCHEME for $DEVICE"
# `| xcbeautify` is nicer if you have it; grep keeps the noise down without it.
xcodebuild \
  -project "$PROJECT" \
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
