#!/bin/sh
# LidAwake: remove the sudoers rule installed by grant-access.sh.
# Exit codes: 0 ok (also when already absent), 4 failed.
export LC_ALL=C
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
set -u

RULE_FILE=/etc/sudoers.d/lidawake

rm -f "$RULE_FILE" "$RULE_FILE.staged" || exit 4
[ ! -e "$RULE_FILE" ] || exit 4
exit 0
