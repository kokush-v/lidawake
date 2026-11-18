#!/bin/sh
# Builds a release binary and assembles build/LidAwake.app (ad-hoc signed).
set -eu
cd "$(dirname "$0")/.."
swift build -c release --arch arm64 --arch x86_64
bin="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
app="build/LidAwake.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/LidAwake" "$app/Contents/MacOS/LidAwake"
cp Resources/Info.plist "$app/Contents/Info.plist"
# Release builds pass VERSION (e.g. 1.2.0); it must be set before codesign.
if [ -n "${VERSION:-}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$app/Contents/Info.plist"
fi
cp Resources/Icons/Menubar/*.png "$app/Contents/Resources/"
cp Resources/Icons/Panel/*.png "$app/Contents/Resources/"
cp Resources/AppIcon.icns "$app/Contents/Resources/"
codesign --force --sign - "$app"
echo "Built $app"
