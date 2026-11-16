#!/bin/sh
# Copies the built app into /Applications.
set -eu
cd "$(dirname "$0")/.."
[ -d build/LidAwake.app ] || { echo "Run 'make build' first." >&2; exit 1; }
rm -rf /Applications/LidAwake.app
cp -R build/LidAwake.app /Applications/LidAwake.app
echo "Installed /Applications/LidAwake.app — open it with: open /Applications/LidAwake.app"
