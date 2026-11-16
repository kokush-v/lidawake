#!/bin/sh
# Checks the privilege scripts without root: syntax, user-name validation and the exact rule text.
set -u
cd "$(dirname "$0")/.."
grant=Resources/scripts/grant-access.sh
revoke=Resources/scripts/revoke-access.sh
fail=0
check() { if [ "$1" -ne 0 ]; then echo "FAIL: $2"; fail=1; else echo "ok:   $2"; fi; }

sh -n "$grant"; check $? "grant-access.sh syntax"
sh -n "$revoke"; check $? "revoke-access.sh syntax"

for bad in "" "bad user" "a;b" "a,b" "-x" "1abc" 'a\b' "root ALL=(ALL) ALL" "a#b" "a%b" "a!b"; do
    sh "$grant" --dry-run "$bad" > /dev/null 2>&1
    [ $? -eq 2 ]; check $? "rejects user name '$bad' with exit 2"
done

expected="alice ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"
actual="$(sh "$grant" --dry-run alice 2>/dev/null)"
[ "$actual" = "$expected" ]; check $? "dry-run prints exactly the contract rule"
sh "$grant" --dry-run john.smith > /dev/null 2>&1; check $? "accepts a user name with a dot"

exit $fail
