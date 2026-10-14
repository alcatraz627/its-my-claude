#!/usr/bin/env bash
# Lag-regression tests for counter-gate-stop.sh: the counted reply is the Stop
# input's last_assistant_message, never the one-message-stale transcript tail.
# Runs under a throwaway HOME so the real counter-gate.jsonl is never written.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/counter-gate-stop.sh"
COMMON="$(cd "$(dirname "$0")" && pwd)/hook-common.sh"
T=$(mktemp -d)
export HOME="$T/home"
mkdir -p "$HOME/.claude/scripts/hooks"
ln -s "$COMMON" "$HOME/.claude/scripts/hooks/hook-common.sh"
LOG="$HOME/.claude/logs/counter-gate.jsonl"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

LONG_REPLY=$(printf 'x%.0s' $(seq 1 500))
SHORT_REPLY="Short and clean."

run() { # run <sid> <reply> <transcript-tail-reply>
  local tp="$T/$1.jsonl"
  { jq -nc '{type:"user", message:{role:"user", content:"how is it going?"}}'
    jq -nc --arg t "$3" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
  jq -nc --arg s "$1" --arg m "$2" --arg tp "$tp" \
    '{session_id:$s, transcript_path:$tp, last_assistant_message:$m}' | bash "$HOOK" 2>/dev/null
}
rows() { [ -f "$LOG" ] && jq -c --arg s "$1" 'select(.sid==$s)' "$LOG" 2>/dev/null || true; }

run lagcg001 "$LONG_REPLY" "$SHORT_REPLY"
r=$(rows lagcg001)
[ "$(printf '%s' "$r" | jq -r '.rchars' 2>/dev/null)" = "500" ] && ok "long current reply, short tail: counted at the current length" || bad "long current reply, short tail ($r)"

run lagcg002 "$SHORT_REPLY" "$LONG_REPLY"
r=$(rows lagcg002)
[ -z "$r" ] && ok "short current reply, long tail: nothing counted" || bad "short current reply, long tail ($r)"

# Fallback: no last_assistant_message reads the transcript tail.
tp="$T/lagcg003.jsonl"
{ jq -nc '{type:"user", message:{role:"user", content:"x"}}'
  jq -nc --arg t "$LONG_REPLY" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
jq -nc --arg tp "$tp" '{session_id:"lagcg003", transcript_path:$tp}' | bash "$HOOK" 2>/dev/null
r=$(rows lagcg003)
[ "$(printf '%s' "$r" | jq -r '.rchars' 2>/dev/null)" = "500" ] && ok "no last_assistant_message: falls back to the transcript" || bad "fallback to transcript ($r)"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
