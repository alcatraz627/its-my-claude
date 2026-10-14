#!/usr/bin/env bash
# Tests for filename-dot-stop.sh. The case that matters most is the lag one: the
# transcript on disk trails the reply that just ended the turn, so the hook has to
# judge last_assistant_message from the Stop input and never the transcript tail.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/filename-dot-stop.sh"
T=$(mktemp -d)
export WARN_LOG_STORE="$T/warn.jsonl"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
if [ -f "$HOME/.claude/.no-filename-dot-gate" ]; then echo "mute file present, test would pass vacuously"; exit 2; fi

# A transcript whose newest assistant record has the given text (the stale one).
transcript() { # transcript <name> <text>
  jq -nc --arg t "$2" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}' > "$T/$1.jsonl"
  printf '%s' "$T/$1.jsonl"
}
# run <sid> <last_assistant_message-or-empty> <transcript-path-or-empty> → hook stdout
run() {
  jq -nc --arg s "$1" --arg m "$2" --arg tp "$3" \
    '{session_id:$s, transcript_path:$tp, stop_hook_active:false} + (if $m == "" then {} else {last_assistant_message:$m} end)' \
    | bash "$HOOK" 2>/dev/null
}
blocks()  { printf '%s' "$1" | jq -e '.decision == "block"' >/dev/null 2>&1; }
cleanup() { for s in "$@"; do rm -f "/tmp/claude-filename-dot-${s:0:8}"; done; }
cleanup fdt00001 fdt00002 fdt00003 fdt00004 fdt00005 fdt00006 fdt00007 fdt00008 fdt00009 fdt00010

BAD='The brief is at `docs/foo.md`. Hand it off.'
GOOD='The brief is at `docs/foo.md`, ready to hand off.'

# Fires on a bad reply.
out=$(run fdt00001 "$BAD" "$(transcript t1 'nothing here')")
blocks "$out" && ok "backticked path then period blocks" || bad "backticked path then period blocks"

out=$(run fdt00002 'See docs/foo.md. Then go.' "")
blocks "$out" && ok "bare path then period blocks" || bad "bare path then period blocks"

out=$(run fdt00003 'The failure is at `src/app.ts:42`.' "")
blocks "$out" && ok "path with :line then period blocks" || bad "path with :line then period blocks"

# Stays silent on good replies and on mentions.
out=$(run fdt00004 "$GOOD" "$(transcript t4 "$BAD")")
[ -z "$out" ] && ok "clean reply passes even when the stale transcript tail is bad" || bad "clean reply passes even when the stale transcript tail is bad: $out"

out=$(run fdt00005 'Run this:
```
cat docs/foo.md.
```
Done, nothing else.' "")
[ -z "$out" ] && ok "path inside a fenced block passes" || bad "path inside a fenced block passes"

out=$(run fdt00006 'Node.js is fine here, and so is e.g. a plain sentence.' "")
[ -z "$out" ] && ok "prose with dots but no path passes" || bad "prose with dots but no path passes"

# The lag regression: the offending reply is the current one, the transcript still
# shows the previous (clean) reply. Reading the transcript misses it.
out=$(run fdt00007 "$BAD" "$(transcript t7 "$GOOD")")
blocks "$out" && ok "offending reply is caught although the transcript tail is the previous clean reply" || bad "offending reply is caught although the transcript tail is the previous clean reply"

# No last_assistant_message at all: falls back to the transcript.
out=$(run fdt00008 "" "$(transcript t8 "$BAD")")
blocks "$out" && ok "fallback: transcript used when the input carries no reply" || bad "fallback: transcript used when the input carries no reply"

# Loop safety: the identical reply is blocked once, never twice.
run fdt00009 "$BAD" "" >/dev/null
out=$(run fdt00009 "$BAD" "")
blocks "$out" && bad "identical re-emit must not block again" || ok "identical re-emit does not block again"

# A fixed reply after a block records the heed and clears the marker.
run fdt00010 "$BAD" "" >/dev/null
run fdt00010 "$GOOD" "" >/dev/null
[ ! -f /tmp/claude-filename-dot-fdt00010 ] && jq -e 'select(.kind=="heed" and .heeded=="true")' "$WARN_LOG_STORE" >/dev/null 2>&1 \
  && ok "fixed reply records heed true and clears the marker" || bad "fixed reply records heed true and clears the marker"

cleanup fdt00001 fdt00002 fdt00003 fdt00004 fdt00005 fdt00006 fdt00007 fdt00008 fdt00009 fdt00010
echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
