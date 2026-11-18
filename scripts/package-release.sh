#!/bin/sh
# Packs build/LidAwake.app into build/LidAwake-<version>.zip plus a .sha256 file.
# Usage: scripts/package-release.sh 1.2.0
set -eu
cd "$(dirname "$0")/.."
[ $# -eq 1 ] || { echo "Usage: $0 <version>" >&2; exit 1; }
version="$1"
[ -d build/LidAwake.app ] || { echo "Run 'make build' first." >&2; exit 1; }
zip="LidAwake-$version.zip"
rm -f "build/$zip" "build/$zip.sha256"
ditto -c -k --keepParent build/LidAwake.app "build/$zip"
(cd build && shasum -a 256 "$zip" > "$zip.sha256")
echo "Packed build/$zip"
cat "build/$zip.sha256"
