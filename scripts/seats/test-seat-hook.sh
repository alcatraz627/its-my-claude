#!/usr/bin/env bash
# Exercises seat header, the Agent hook's telemetry and warning, and the sweep
# that lands background seats, in a throwaway seats directory.
#   bash ~/.claude/scripts/seats/test-seat-hook.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SEATS_DIR="$(mktemp -d)"; SEATS_DOMAIN="$(mktemp -d)"; export SEATS_DIR SEATS_DOMAIN
OUT="$SEATS_DIR/out.md"
pass=0; fail=0
eq() { if [ "$2" = "$3" ]; then pass=$((pass+1)); printf 'ok   %s\n' "$1"; else fail=$((fail+1)); printf 'FAIL %s\n     want %s, got %s\n' "$1" "$3" "$2"; fi; }
has() { case "$2" in *"$3"*) pass=$((pass+1)); printf 'ok   %s\n' "$1" ;; *) fail=$((fail+1)); printf 'FAIL %s\n     missing %s in %s\n' "$1" "$3" "$2" ;; esac; }
hook() { python3 "$HERE/seat-hook.py"; }
field() { python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get(sys.argv[2]))' "$SEATS_DIR/$1.json" "$2"; }

hdr=$(python3 "$HERE/seat" header --role researcher --model sonnet --output "$OUT" --goal "test the sweep")
has "header prints a seat header line" "$hdr" "[seat s-"
sid=$(printf '%s' "$hdr" | sed -E 's/^\[seat (s-[0-9]{8}-[0-9]{6}-[0-9a-f]{4})\].*/\1/')
eq "header records the seat" "$(field "$sid" state)" "composed"
python3 "$HERE/seat" header --role researcher --model sonnet --output relative.md --goal x >/dev/null 2>&1
eq "header refuses a relative output path" "$?" "2"

prompt="$hdr
Do the thing. Write $OUT before returning. Do NOT spawn sub-agents. When your scoped work is done, stop. One command per Bash call."
pre=$(python3 -c 'import json,sys;print(json.dumps({"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"prompt":sys.argv[1],"model":"sonnet","run_in_background":True}}))' "$prompt")
out=$(printf '%s' "$pre" | hook)
eq "a seated dispatch gets no warning" "$out" ""
eq "the seat is marked dispatched" "$(field "$sid" state)" "dispatched"
eq "the seat is marked background" "$(field "$sid" background)" "True"

post=$(python3 -c 'import json,sys;print(json.dumps({"hook_event_name":"PostToolUse","tool_name":"Agent","tool_input":{"prompt":sys.argv[1],"run_in_background":True}}))' "$prompt")
printf '%s' "$post" | hook
eq "a background seat is not landed when its call returns" "$(field "$sid" state)" "dispatched"

python3 "$HERE/seat" sweep >/dev/null
eq "sweep leaves a seat with no output yet alone" "$(field "$sid" state)" "dispatched"
echo "result" > "$OUT"
eq "sweep lands it once the output exists" "$(python3 "$HERE/seat" sweep)" "landed $sid: ok (landed by sweep: output exists)"
eq "the landed outcome is ok" "$(field "$sid" outcome)" "ok"

hdr2=$(python3 "$HERE/seat" header --role reviewer --model sonnet --output "$SEATS_DIR/out2.md" --goal "harness backgrounded it")
sid2=$(printf '%s' "$hdr2" | sed -E 's/^\[seat (s-[0-9]{8}-[0-9]{6}-[0-9a-f]{4})\].*/\1/')
p2="$hdr2
review it"
python3 -c 'import json,sys;print(json.dumps({"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"prompt":sys.argv[1],"model":"sonnet"}}))' "$p2" | hook >/dev/null
python3 -c 'import json,sys;print(json.dumps({"hook_event_name":"PostToolUse","tool_name":"Agent","tool_input":{"prompt":sys.argv[1]},"tool_response":"Async agent launched successfully. The agent is working in the background."}))' "$p2" | hook
eq "a seat the harness backgrounded is not landed at launch" "$(field "$sid2" state)" "dispatched"
eq "and is marked background for the sweep" "$(field "$sid2" background)" "True"
hdr3=$(python3 "$HERE/seat" header --role reviewer --model sonnet --output "$SEATS_DIR/out3.md" --goal "foreground")
sid3=$(printf '%s' "$hdr3" | sed -E 's/^\[seat (s-[0-9]{8}-[0-9]{6}-[0-9a-f]{4})\].*/\1/')
p3="$hdr3
review it"
python3 -c 'import json,sys;print(json.dumps({"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"prompt":sys.argv[1],"model":"sonnet"}}))' "$p3" | hook >/dev/null
python3 -c 'import json,sys;print(json.dumps({"hook_event_name":"PostToolUse","tool_name":"Agent","tool_input":{"prompt":sys.argv[1]},"tool_response":"done, here are my findings"}))' "$p3" | hook
eq "a foreground return still lands at once" "$(field "$sid3" state)" "landed"

bare=$(python3 -c 'import json;print(json.dumps({"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"prompt":"x"*5000}}))')
has "an unseated dispatch is warned, however long" "$(printf '%s' "$bare" | hook)" "seat header --role"
eq "every dispatch is logged" "$(wc -l < "$SEATS_DIR/dispatch.jsonl" | tr -d ' ')" "4"
has "the log records clauses" "$(head -n 1 "$SEATS_DIR/dispatch.jsonl")" '"nesting": true'
has "weekly shows the seated share" "$(python3 "$HERE/seat" weekly)" "Agent dispatches, last 7 days: 4, seated 3 (75%)"

trash "$SEATS_DIR" "$SEATS_DOMAIN" >/dev/null 2>&1
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
