#!/bin/sh
# LidAwake: allow the given user to run exactly two commands as root without a password:
#   /usr/bin/pmset -a disablesleep 0
#   /usr/bin/pmset -a disablesleep 1
# Usage: grant-access.sh [--dry-run] <user>
# Exit codes: 0 ok, 2 bad argument, 3 rule failed validation (nothing activated), 4 install failed.
# --dry-run prints the rule and validates it with visudo -cf without installing anything.
export LC_ALL=C
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
set -u

RULE_FILE=/etc/sudoers.d/lidawake

dry_run=0
if [ "${1:-}" = "--dry-run" ]; then
    dry_run=1
    shift
fi
user="${1:-}"

# A conservative user name: no spaces, commas, '#', '!', '%', '\' or other sudoers syntax.
case "$user" in
    '' | [!A-Za-z_]* | *[!A-Za-z0-9._-]*)
        echo "invalid user name" >&2
        exit 2
        ;;
esac

rule="$user ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"

tmp="$(mktemp /tmp/lidawake-rule.XXXXXX)" || exit 4
trap 'rm -f "$tmp"' EXIT
printf '%s\n' "$rule" > "$tmp" || exit 4

if ! visudo -cf "$tmp" > /dev/null 2>&1; then
    echo "rule failed validation" >&2
    exit 3
fi

if [ "$dry_run" -eq 1 ]; then
    printf '%s\n' "$rule"
    exit 0
fi

# Stage under a name sudo ignores (contains a dot), validate again, then move into place.
staged="$RULE_FILE.staged"
trap 'rm -f "$tmp" "$staged"' EXIT
install -m 0440 -o root -g wheel "$tmp" "$staged" || exit 4
if ! visudo -cf "$staged" > /dev/null 2>&1; then
    echo "staged rule failed validation" >&2
    exit 3
fi
mv -f "$staged" "$RULE_FILE" || exit 4

# The whole configuration must still be valid; otherwise remove our rule again.
if ! visudo -c > /dev/null 2>&1; then
    rm -f "$RULE_FILE"
    echo "sudoers configuration invalid after install; rule removed" >&2
    exit 4
fi
exit 0
