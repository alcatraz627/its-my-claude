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

# Detection 1b: a pass claimed on a named environment needs that environment in
# this turn's tool activity.
run_tool() { # run_tool <sid> <reply> <bash command run this turn>
  local tp="$T/$1.jsonl"
  { jq -nc '{type:"user", message:{role:"user", content:"is it working on the pi?"}}'
    jq -nc --arg c "$3" '{type:"assistant", message:{content:[{type:"tool_use", id:"t1", name:"Bash", input:{command:$c}}]}}'
    jq -nc '{type:"user", message:{content:[{type:"tool_result", tool_use_id:"t1", content:"ok"}]}}'; } > "$tp"
  jq -nc --arg s "$1" --arg m "$2" --arg tp "$tp" \
    '{session_id:$s, transcript_path:$tp, stop_hook_active:false, last_assistant_message:$m}' | bash "$HOOK" 2>/dev/null
}
ids="$ids envdr001 envdr002 envdr003 envdr004 envdr005"
for s in envdr001 envdr002 envdr003 envdr004 envdr005; do rm -f /tmp/claude-declared-ready-env-$s; done
out=$(run_tool envdr001 "The upload path is proven from the Pi API and green on laptop." "git status")
blocks "$out" && ok "env claim with no tool touching it blocks" || bad "env claim unbacked ($out)"
printf '%s' "$out" | jq -r '.reason' | rg -q 'proven from the Pi' && ok "the block quotes the claim" || bad "claim quoted ($out)"
out=$(run_tool envdr002 "The upload path is proven from the Pi API." "ssh pi@raspberrypi.local curl -s localhost:8080/health")
[ -z "$out" ] && ok "env claim backed by a tool call on that env passes" || bad "env claim backed ($out)"
out=$(run_tool envdr003 "The upload path is not yet verified, but it was passing on staging in the last session." "git status")
[ -z "$out" ] && ok "a hedged env claim passes" || bad "hedged env claim ($out)"
out=$(run_tool envdr004 "Reading the staging config next." "git status")
[ -z "$out" ] && ok "naming an env without a pass claim passes" || bad "env mention ($out)"
out=$(run_tool envdr005 "It is green on laptop." "git status")
out2=$(run_tool envdr005 "It is green on laptop." "git status")
{ blocks "$out" && ! blocks "$out2"; } && ok "the same env claim blocks once, then steps aside" || bad "env loop safety ($out2)"
for s in envdr001 envdr002 envdr003 envdr004 envdr005; do rm -f /tmp/claude-declared-ready-env-$s; done

cleanup
echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
