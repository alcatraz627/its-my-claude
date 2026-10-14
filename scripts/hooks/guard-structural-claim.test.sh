#!/usr/bin/env bash
# Lag-regression tests for guard-structural-claim.sh: the claim is read from the
# Stop input's last_assistant_message, never the one-message-stale transcript tail.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/guard-structural-claim.sh"
T=$(mktemp -d)
export WARN_LOG_STORE="$T/warn.jsonl"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
if [ -f "$HOME/.claude/.no-structural-claim-gate" ]; then echo "mute file present, test would pass vacuously"; exit 2; fi

BAD_REPLY='The `session_cache` layer is the source of truth for login state.'
CLEAN_REPLY="Nothing to report on that yet."

run() { # run <sid> <reply> <transcript-tail-reply>
  local tp="$T/$1.jsonl"
  { jq -nc '{type:"user", message:{role:"user", content:"how does login work?"}}'
    jq -nc --arg t "$3" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
  jq -nc --arg s "$1" --arg m "$2" --arg tp "$tp" --arg cwd "$T" \
    '{session_id:$s, transcript_path:$tp, cwd:$cwd, last_assistant_message:$m}' | bash "$HOOK" 2>/dev/null
}
fires() { printf '%s' "$1" | jq -e '.decision == "block" or (.systemMessage // "" | test("structural-claim"))' >/dev/null 2>&1; }
ids="lagsc001 lagsc002 lagsc003"
cleanup() { for s in $ids; do rm -f /tmp/claude-structural-claim-$s; done; }
cleanup

out=$(run lagsc001 "$BAD_REPLY" "$CLEAN_REPLY")
fires "$out" && ok "current reply makes an ungrounded authority claim, clean tail: fires" || bad "current bad, clean tail: fires ($out)"

out=$(run lagsc002 "$CLEAN_REPLY" "$BAD_REPLY")
[ -z "$out" ] && ok "current reply clean, claiming tail: silent" || bad "current clean, bad tail: silent ($out)"

tp="$T/lagsc003.jsonl"
{ jq -nc '{type:"user", message:{role:"user", content:"x"}}'
  jq -nc --arg t "$BAD_REPLY" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
out=$(jq -nc --arg tp "$tp" --arg cwd "$T" '{session_id:"lagsc003", transcript_path:$tp, cwd:$cwd}' | bash "$HOOK" 2>/dev/null)
fires "$out" && ok "no last_assistant_message: falls back to the transcript" || bad "fallback to transcript ($out)"

cleanup
echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
