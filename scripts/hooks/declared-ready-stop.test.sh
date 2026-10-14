#!/usr/bin/env bash
# Lag-regression tests for declared-ready-stop.sh: the reply judged is the Stop
# input's last_assistant_message, never the (one message stale) transcript tail.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/declared-ready-stop.sh"
T=$(mktemp -d)
export WARN_LOG_STORE="$T/warn.jsonl"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
if [ -f "$HOME/.claude/.no-declared-ready-gate" ]; then echo "mute file present, test would pass vacuously"; exit 2; fi

BAD_REPLY="Done. The fix works."
CLEAN_REPLY="Reading the file now."

run() { # run <sid> <reply> <transcript-tail-reply>
  local tp="$T/$1.jsonl"
  { jq -nc '{type:"user", message:{role:"user", content:"please fix the thing"}}'
    jq -nc --arg t "$3" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
  printf '%s/fixed.py\n' "$T" > "/tmp/claude-edited-files-${1:0:8}"
  jq -nc --arg s "$1" --arg m "$2" --arg tp "$tp" \
    '{session_id:$s, transcript_path:$tp, stop_hook_active:false, last_assistant_message:$m}' | bash "$HOOK" 2>/dev/null
}
blocks() { printf '%s' "$1" | jq -e '.decision == "block"' >/dev/null 2>&1; }
ids="lagdr001 lagdr002 lagdr003"
cleanup() { for s in $ids; do rm -f /tmp/claude-edited-files-$s /tmp/claude-declared-ready-$s /tmp/claude-declared-ready-heeded-$s; done; }
cleanup

out=$(run lagdr001 "$BAD_REPLY" "$CLEAN_REPLY")
blocks "$out" && ok "current reply over-claims, clean tail: blocks" || bad "current reply over-claims, clean tail: blocks ($out)"

out=$(run lagdr002 "$CLEAN_REPLY" "$BAD_REPLY")
[ -z "$out" ] && ok "current reply clean, over-claiming tail: silent" || bad "current reply clean, over-claiming tail: silent ($out)"

# Baseline: the same bad reply with no input field falls back to the transcript.
tp="$T/lagdr003.jsonl"
{ jq -nc '{type:"user", message:{role:"user", content:"fix it"}}'
  jq -nc --arg t "$BAD_REPLY" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
printf '%s/fixed.py\n' "$T" > /tmp/claude-edited-files-lagdr003
out=$(jq -nc --arg tp "$tp" '{session_id:"lagdr003", transcript_path:$tp}' | bash "$HOOK" 2>/dev/null)
blocks "$out" && ok "no last_assistant_message: falls back to the transcript" || bad "fallback to transcript ($out)"

cleanup
echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
