#!/bin/sh
# Runs `swift test`. With Command Line Tools only, the Swift Testing macro plugin sometimes
# fails to load right after sources change; building again succeeds, so retry the build.
set -u
cd "$(dirname "$0")/.."
for attempt in 1 2 3 4 5 6; do
    if swift build --build-tests >/dev/null 2>&1; then break; fi
done
exec swift test
