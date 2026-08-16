#!/usr/bin/env bash
# Tests for ctx-claim-stop.sh (task #33 / D7).
#
# The gate is conditional on a measurement, so every row states the instrument
# reading it runs under. A suite that only ever tested one reading would pass
# while the threshold comparison was inverted.

set -uo pipefail
cd "$(dirname "$0")" || exit 1

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok   $1"; }
bad() { fail=$((fail+1)); echo "  FAIL $1"; }

# run <remaining-pct|none> <text> [sid] -> WARN | SILENT
run() {
  local rem="$1" txt="$2" sid="${3:-ctxc$RANDOM}" t tp cf out
  t=$(mktemp -d); tp="$t/transcript.jsonl"; cf="$t/ctx"
  jq -cn --arg x "$txt" '{type:"assistant",message:{content:[{type:"text",text:$x}]}}' > "$tp"
  [ "$rem" = none ] || printf '%s' "$rem" > "$cf"
  out=$(jq -cn --arg s "$sid" --arg p "$tp" '{session_id:$s,transcript_path:$p}' \
        | CTX_FILE_OVERRIDE="$cf" bash ctx-claim-stop.sh 2>/dev/null)
  rm -rf "$t"
  printf '%s' "$out" | grep -q systemMessage && echo WARN || echo SILENT
}

expect() { local got; got=$(run "$1" "$3"); [ "$got" = "$2" ] && ok "$4" || bad "$4 (want $2, got $got)"; }

echo "== plenty of room, so the claim is false =="
# remaining 66 -> 34% used, well under the 70 band
expect 66 WARN 'This turn is long enough that starting it here risks a compact mid-edit.' \
  'fires on a compact-risk claim at 34% used'
expect 66 WARN 'We are running low on context, so I will stop here.' \
  'fires on running low on context'
expect 66 WARN 'Context is getting tight; I suggest we wrap up.' \
  'fires on context is getting tight'

echo "== the claim is TRUE, so the gate must stay out of the way =="
# remaining 20 -> 80% used, genuinely in the danger zone
expect 20 SILENT 'We are running low on context, so I will checkpoint now.' \
  'silent at 80% used (the claim is accurate)'
expect 29 SILENT 'Context is getting tight; recommend /core-dump then /clear.' \
  'silent at 71% used (just inside the first band)'

echo "== no reading, no standing =="
expect none SILENT 'We are running low on context, so I will stop here.' \
  'silent when the instrument cannot be read'

echo "== ordinary English about context must not fire =="
expect 66 SILENT 'In the context of the migration, that guard is the wrong tier.' \
  'in the context of'
expect 66 SILENT 'The context window on this tier is 1M tokens.' \
  'context window as a topic'
expect 66 SILENT 'I have enough context to decide, so I will proceed.' \
  'enough context to decide'
expect 66 SILENT 'All nine suites are green and nothing is committed yet.' \
  'no context talk at all'

echo "== meta-discussion exemption (a session maintaining the machinery) =="
expect 66 SILENT 'The ctx-pressure hook posts at 70/80/90, so running low on context is measurable.' \
  'naming ctx-pressure exempts the message'

echo "== fenced code is quoted material =="
expect 66 SILENT 'Here is the matcher:
```
rg "running low on context" transcript.jsonl
```
That is the trigger phrase.' \
  'claim phrase inside a fence does not fire'

echo "== loop safety =="
SID="ctxloop1"
a=$(run 66 'We are running low on context, so I will stop here.' "$SID")
b=$(run 66 'We are running low on context, so I will stop here.' "$SID")
[ "$a" = WARN ] && [ "$b" = SILENT ] \
  && ok "warns once, then steps aside on the identical message" \
  || bad "loop safety broken (first=$a second=$b)"
rm -f "/tmp/claude-ctxclaim-${SID}" 2>/dev/null || true

echo "== the mute is honoured =="
MUTE="$HOME/.claude/.no-ctx-claim-gate"; had=0; [ -f "$MUTE" ] && had=1
touch "$MUTE"
g=$(run 66 'We are running low on context, so I will stop here.')
[ "$had" = 1 ] || rm -f "$MUTE"
[ "$g" = SILENT ] && ok "silent while ~/.claude/.no-ctx-claim-gate exists" \
                  || bad "mute file did not stop the hook"

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
