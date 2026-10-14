#!/usr/bin/env bash
# Suite for guard-prose-quality.sh: banned prose tells in a written artifact
# block, and the same text in a test, fixture, probe or replay file is a
# deliberate example and does not. GUARD_UNDER_TEST points the suite at a
# mutated copy (the copy must sit in scripts/hooks/).
set -uo pipefail
HOOK="${GUARD_UNDER_TEST:-$(cd "$(dirname "$0")" && pwd)/guard-prose-quality.sh}"
REAL_SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

# Sandbox HOME: the style linters resolve through $HOME/.claude/scripts.
T=$(mktemp -d)
mkdir -p "$T/.claude"
ln -s "$REAL_SCRIPTS" "$T/.claude/scripts"

DASH=$'\xe2\x80\x94'
PROSE="The new cache keeps recent reads in memory $DASH it avoids a round trip to disk on every call."
CODE="MESSAGE = \"Saved $DASH your changes are safe\""

fire() { # fire <path> <content>
  jq -nc --arg f "$1" --arg c "$2" '{tool_name:"Write", tool_input:{file_path:$f, content:$c}, session_id:"t"}' \
    | HOME="$T" bash "$HOOK" 2>/dev/null
}
blocked() { [ -n "$(fire "$1" "$2")" ] && ok "BLOCKED: $3" || bad "not blocked: $3"; }
allowed() { [ -z "$(fire "$1" "$2")" ] && ok "allow: $3" || bad "blocked (should pass): $3"; }

blocked "$T/proj/docs/guide.md" "$PROSE" "an em-dash in earnest prose (.md)"
blocked "$T/proj/src/messages.py" "$CODE" "an em-dash in a user-facing string (.py)"
allowed "$T/proj/docs/guide.md" $'The new cache keeps recent reads in memory. It avoids a round trip to disk on every call.\n' "clean prose"

allowed "$T/proj/src/messages.test.py" "$CODE" "a *.test.* file"
allowed "$T/proj/src/fixtures/messages.py" "$CODE" "a fixture path"
allowed "$T/proj/scripts/hooks/replay/replay-copy.py" "$CODE" "a replay script"
allowed "$T/proj/assets/stop_probe.py" "$CODE" "a probe script"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
