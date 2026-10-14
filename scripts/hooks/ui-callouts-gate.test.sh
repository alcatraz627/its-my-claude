#!/usr/bin/env bash
# Lag-regression tests for ui-callouts-gate.sh: the done-claim is read from the
# Stop input's last_assistant_message, never the one-message-stale transcript tail.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/ui-callouts-gate.sh"
T=$(mktemp -d)
export WARN_LOG_STORE="$T/warn.jsonl"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
if [ -f "$HOME/.claude/.no-ui-callouts-gate" ]; then echo "mute file present, test would pass vacuously"; exit 2; fi

PROJ="$T/proj"
mkdir -p "$PROJ/.claude"
jq -nc '{id:"co-lag-1", ts:"2026-10-15T00:00:00Z", surface:"lagwidget", words:"the header is cramped", status:"open", rechecks:[]}' > "$PROJ/.claude/callouts.jsonl"

BAD_REPLY="Done, the lagwidget header is fixed."
CLEAN_REPLY="Still looking at the lagwidget header."

run() { # run <sid> <reply> <transcript-tail-reply>
  local tp="$T/$1.jsonl"
  { jq -nc '{type:"user", message:{role:"user", content:"fix the header"}}'
    jq -nc --arg t "$3" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
  printf '%s/lagwidget.css\n' "$PROJ" > "/tmp/claude-edited-files-${1:0:8}"
  jq -nc --arg s "$1" --arg m "$2" --arg tp "$tp" \
    '{session_id:$s, transcript_path:$tp, last_assistant_message:$m}' | bash "$HOOK" 2>/dev/null
}
blocks() { printf '%s' "$1" | jq -e '.decision == "block"' >/dev/null 2>&1; }
ids="lagco001 lagco002 lagco003"
cleanup() { for s in $ids; do rm -f /tmp/claude-edited-files-$s /tmp/claude-ui-callouts-gate-$s; done; }
cleanup

out=$(run lagco001 "$BAD_REPLY" "$CLEAN_REPLY")
blocks "$out" && ok "current reply claims done on an open surface, clean tail: blocks" || bad "current bad, clean tail ($out)"

out=$(run lagco002 "$CLEAN_REPLY" "$BAD_REPLY")
[ -z "$out" ] && ok "current reply clean, done-claiming tail: silent" || bad "current clean, bad tail ($out)"

tp="$T/lagco003.jsonl"
{ jq -nc '{type:"user", message:{role:"user", content:"x"}}'
  jq -nc --arg t "$BAD_REPLY" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
printf '%s/lagwidget.css\n' "$PROJ" > /tmp/claude-edited-files-lagco003
out=$(jq -nc --arg tp "$tp" '{session_id:"lagco003", transcript_path:$tp}' | bash "$HOOK" 2>/dev/null)
blocks "$out" && ok "no last_assistant_message: falls back to the transcript" || bad "fallback to transcript ($out)"

cleanup
echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
