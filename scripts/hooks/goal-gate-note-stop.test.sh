#!/usr/bin/env bash
# Lag-regression tests for goal-gate-note-stop.sh: the /goal line is read from the
# Stop input's last_assistant_message, never the one-message-stale transcript tail.
# The repo under test is a throwaway protected repo, so the note never depends on
# the live push policy.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/goal-gate-note-stop.sh"
T=$(mktemp -d)
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
if [ -f "$HOME/.claude/.no-goal-gate-note" ]; then echo "mute file present, test would pass vacuously"; exit 2; fi

REPO="$T/repo"
mkdir -p "$REPO/.claude"
git -C "$REPO" init -q
: > "$REPO/.claude/require-user-commit"

BAD_REPLY=$'Starting now.\n\n/goal The change is pushed to main.'
CLEAN_REPLY="Starting now, nothing proposed."

run() { # run <sid> <reply> <transcript-tail-reply>
  local tp="$T/$1.jsonl"
  { jq -nc '{type:"user", message:{role:"user", content:"go"}}'
    jq -nc --arg t "$3" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
  jq -nc --arg s "$1" --arg m "$2" --arg tp "$tp" --arg cwd "$REPO" \
    '{session_id:$s, transcript_path:$tp, cwd:$cwd, last_assistant_message:$m}' | bash "$HOOK" 2>/dev/null
}
notes() { printf '%s' "$1" | jq -e '.systemMessage | test("goal-gate")' >/dev/null 2>&1; }
ids="lagggn01 lagggn02 lagggn03"
cleanup() { for s in $ids; do rm -f /tmp/claude-goalgate-$s; done; }
cleanup

out=$(run lagggn01 "$BAD_REPLY" "$CLEAN_REPLY")
notes "$out" && ok "current reply proposes a push goal, clean tail: notes" || bad "current bad, clean tail ($out)"

out=$(run lagggn02 "$CLEAN_REPLY" "$BAD_REPLY")
[ -z "$out" ] && ok "current reply clean, goal-proposing tail: silent" || bad "current clean, bad tail ($out)"

tp="$T/lagggn03.jsonl"
{ jq -nc '{type:"user", message:{role:"user", content:"x"}}'
  jq -nc --arg t "$BAD_REPLY" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
out=$(jq -nc --arg tp "$tp" --arg cwd "$REPO" '{session_id:"lagggn03", transcript_path:$tp, cwd:$cwd}' | bash "$HOOK" 2>/dev/null)
notes "$out" && ok "no last_assistant_message: falls back to the transcript" || bad "fallback to transcript ($out)"

cleanup
echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
