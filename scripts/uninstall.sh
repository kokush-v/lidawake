#!/bin/sh
# Removes LidAwake: revokes the sudoers rule (asks for your password in Terminal) and deletes the app.
# Turn off "Launch at login" in the app's panel first if you enabled it.
set -eu
cd "$(dirname "$0")/.."
pkill -x LidAwake 2>/dev/null || true
echo "Removing the LidAwake sudoers rule (sudo may ask for your password)..."
sudo /bin/sh Resources/scripts/revoke-access.sh
rm -rf /Applications/LidAwake.app
echo "LidAwake removed."
