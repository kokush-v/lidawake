#!/bin/sh
# Builds a release binary and assembles build/LidAwake.app (ad-hoc signed).
set -eu
cd "$(dirname "$0")/.."
swift build -c release
bin="$(swift build -c release --show-bin-path)"
app="build/LidAwake.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/LidAwake" "$app/Contents/MacOS/LidAwake"
cp Resources/Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app"
echo "Built $app"
