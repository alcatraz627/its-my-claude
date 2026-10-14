#!/usr/bin/env bash
# Suite for guard-ai-signature.sh: a signature line added to a human-read
# document blocks, and the same text in a test, fixture, probe or replay file is
# a mention and does not. GUARD_UNDER_TEST points the suite at a mutated copy
# (the copy must sit in scripts/hooks/).
set -uo pipefail
HOOK="${GUARD_UNDER_TEST:-$(cd "$(dirname "$0")" && pwd)/guard-ai-signature.sh}"
REAL_HOOKS="$(cd "$(dirname "$0")" && pwd)"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

# Sandbox HOME so heed tracking and the HOME-based exemptions never touch the real tree.
T=$(mktemp -d)
mkdir -p "$T/.claude/scripts"
ln -s "$REAL_HOOKS" "$T/.claude/scripts/hooks"

# Built from pieces so this file never carries a whole signature line itself.
SIG="Co-Authored-By: Cla""ude <noreply@anthropic"".com>"

fire() { # fire <path> <content>
  jq -nc --arg f "$1" --arg c "$2" '{tool_name:"Write", tool_input:{file_path:$f, content:$c}, session_id:"t"}' \
    | HOME="$T" bash "$HOOK" 2>/dev/null
}
blocked() { [ -n "$(fire "$1" "$2")" ] && ok "BLOCKED: $3" || bad "not blocked: $3"; }
allowed() { [ -z "$(fire "$1" "$2")" ] && ok "allow: $3" || bad "blocked (should pass): $3"; }

BODY=$'Release notes\n\n'"$SIG"$'\n'

blocked "$T/proj/docs/notes.md" "$BODY" "signature added to a document"
blocked "$T/proj/CHANGELOG.md" "$BODY" "signature added to a changelog"
allowed "$T/proj/docs/notes.md" $'Release notes\n\nNothing to sign.\n' "clean document"

allowed "$T/proj/src/sig.test.ts" "$BODY" "a *.test.* file"
allowed "$T/proj/src/fixtures/commit.txt" "$BODY" "a fixture path"
allowed "$T/proj/scripts/hooks/replay/replay-sig.py" "$BODY" "a replay script"
allowed "$T/proj/assets/gate_probe.py" "$BODY" "a probe script"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
