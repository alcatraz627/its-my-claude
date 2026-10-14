#!/usr/bin/env bash
# Tests for emdash-stop.sh: one em-dash in prose blocks once, code and quotes may
# carry it, an identical re-emit never re-fires, and a clean reply records the heed.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/emdash-stop.sh"
T=$(mktemp -d)
export WARN_LOG_STORE="$T/warn.jsonl"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
if [ -f "$HOME/.claude/.no-emdash-gate" ]; then echo "mute file present, test would pass vacuously"; exit 2; fi

D='—'
run() { # run <sid> <reply> [transcript-text]
  local tp=""
  if [ -n "${3:-}" ]; then
    tp="$T/$1.jsonl"
    jq -nc --arg t "$3" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}' > "$tp"
  fi
  jq -nc --arg s "$1" --arg m "$2" --arg tp "$tp" \
    '{session_id:$s, transcript_path:$tp, stop_hook_active:false, last_assistant_message:$m}' | bash "$HOOK" 2>/dev/null
}
blocks() { printf '%s' "$1" | jq -e '.decision == "block"' >/dev/null 2>&1; }
ids="emd00001 emd00002 emd00003 emd00004 emd00005 emd00006 emd00007 emd00008 emd00009 emd00010 emd00011 emd00012"
cleanup() { for s in $ids; do rm -f "/tmp/claude-emdash-${s:0:8}"; done; }
cleanup

out=$(run emd00001 "The fix is small $D one line in the hook.")
blocks "$out" && ok "a single em-dash in a short reply blocks" || bad "a single em-dash in a short reply blocks"

out=$(run emd00002 "The fix is small, one line in the hook, and it is tested.")
[ -z "$out" ] && ok "a clean reply passes" || bad "a clean reply passes: $out"

out=$(run emd00003 "The regex is \`a${D}b\` and nothing else.")
[ -z "$out" ] && ok "em-dash inside inline code passes" || bad "em-dash inside inline code passes"

out=$(run emd00004 "Output was:
\`\`\`
build $D ok
\`\`\`
Fine.")
[ -z "$out" ] && ok "em-dash inside a fenced block passes" || bad "em-dash inside a fenced block passes"

out=$(run emd00005 "The owner wrote:
> keep it short $D no filler
and that is the rule.")
[ -z "$out" ] && ok "em-dash inside a blockquote passes" || bad "em-dash inside a blockquote passes"

out=$(run emd00006 "One $D and another $D here.")
echo "$out" | jq -e '.reason | test("2 em-dash")' >/dev/null 2>&1 && ok "the reason counts every em-dash" || bad "the reason counts every em-dash"

# Loop safety.
run emd00007 "Small $D change." >/dev/null
out=$(run emd00007 "Small $D change.")
blocks "$out" && bad "identical re-emit must not block again" || ok "identical re-emit does not block again"

run emd00008 "First $D try." >/dev/null
out=$(run emd00008 "Second $D try, reworded.")
blocks "$out" && ok "a reworded reply that still has one blocks again" || bad "a reworded reply that still has one blocks again"

run emd00009 "Try $D one." >/dev/null
run emd00009 "Try $D two." >/dev/null
run emd00009 "Try $D three." >/dev/null
out=$(run emd00009 "Try $D four.")
blocks "$out" && bad "the fourth consecutive block must step aside" || ok "three blocks in a row end the loop"

run emd00010 "Bad $D reply." >/dev/null
run emd00010 "Good, reply." >/dev/null
[ ! -f /tmp/claude-emdash-emd00010 ] && jq -e 'select(.kind=="heed" and .heeded=="true" and .hook_id=="emdash")' "$WARN_LOG_STORE" >/dev/null 2>&1 \
  && ok "a clean reply after a block records heeded true and clears the marker" || bad "a clean reply after a block records heeded true and clears the marker"

# The transcript tail lags one reply behind; the Stop input is what is judged.
out=$(run emd00011 "Current $D reply." "Previous clean reply.")
blocks "$out" && ok "judges the Stop input, not the stale transcript tail" || bad "judges the Stop input, not the stale transcript tail"
out=$(run emd00012 "Current clean reply." "Previous $D reply.")
[ -z "$out" ] && ok "a stale transcript tail with an em-dash does not block a clean reply" || bad "a stale transcript tail with an em-dash does not block a clean reply"

cleanup
echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
