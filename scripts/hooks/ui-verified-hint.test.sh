#!/usr/bin/env bash
# Tests for ui-verified-hint.sh: the note queued by ui-verified-stop.py reaches the
# agent once, as UserPromptSubmit context, and only the session it belongs to.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/ui-verified-hint.sh"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
if [ -f "$HOME/.claude/.no-ui-verified-gate" ]; then echo "mute file present, test would pass vacuously"; exit 2; fi

run() { jq -nc --arg s "$1" '{session_id:$s, prompt:"next"}' | bash "$HOOK" 2>/dev/null; }
rm -f /tmp/claude-uiverified-note-uivhint1 /tmp/claude-uiverified-note-uivhint2

printf '%s' '[ui-verified] describe the frame first.' > /tmp/claude-uiverified-note-uivhint1
out=$(run uivhint1-aaaa-bbbb)
printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName=="UserPromptSubmit" and (.hookSpecificOutput.additionalContext | test("describe the frame"))' >/dev/null 2>&1 \
  && ok "the queued note arrives as UserPromptSubmit context" || bad "the queued note arrives as UserPromptSubmit context: $out"
[ ! -e /tmp/claude-uiverified-note-uivhint1 ] && ok "the note is consumed" || bad "the note is consumed"
out=$(run uivhint1-aaaa-bbbb); [ -z "$out" ] && ok "a second prompt gets nothing" || bad "a second prompt gets nothing"

printf '%s' 'for someone else' > /tmp/claude-uiverified-note-uivhint2
out=$(run uivhint1-aaaa-bbbb); [ -z "$out" ] && ok "another session's note is not delivered" || bad "another session's note is not delivered"
rm -f /tmp/claude-uiverified-note-uivhint2

out=$(printf '{}' | bash "$HOOK" 2>/dev/null); [ -z "$out" ] && ok "no session id: silent" || bad "no session id: silent"

echo "---- pass=$pass fail=$fail"
[ $fail -eq 0 ]
