#!/usr/bin/env bash
# Tests review-lane.py's telemetry and lane order without calling any model:
# a primed probe cache stands in for the outside lanes.
#   bash ~/.claude/scripts/review-lane/test-review-lane.sh
set -uo pipefail
RL="$HOME/.claude/scripts/review-lane/review-lane.py"
T=$(mktemp -d); REAL_HOME="$HOME"; export HOME="$T"
pass=0; fail=0
eq() { if [ "$2" = "$3" ]; then pass=$((pass+1)); printf 'ok   %s\n' "$1"; else fail=$((fail+1)); printf 'FAIL %s\n     want %s, got %s\n' "$1" "$3" "$2"; fi; }
has() { case "$2" in *"$3"*) pass=$((pass+1)); printf 'ok   %s\n' "$1" ;; *) fail=$((fail+1)); printf 'FAIL %s\n     missing %s in %s\n' "$1" "$3" "$2" ;; esac; }

cp /tmp/review-lane-probe.json "$T/probe.keep" 2>/dev/null
now=$(date +%s)
printf '{"codex":{"ok":true,"detail":"m","at":%s},"gemini-4-argon":{"ok":true,"detail":"g","at":%s}}' "$now" "$now" > /tmp/review-lane-probe.json
has "codex leads when it is up" "$(python3 "$RL" pick)" "lane: codex"
printf '{"codex":{"ok":false,"detail":"capped","at":%s},"gemini-4-argon":{"ok":true,"detail":"g","at":%s}}' "$now" "$now" > /tmp/review-lane-probe.json
out=$(python3 "$RL" pick)
has "a down codex falls through to gemini" "$out" "lane: gemini-4-argon"
has "and says why codex was skipped" "$out" "skipped: codex (capped)"
printf '{"codex":{"ok":false,"detail":"x","at":%s},"gemini-4-argon":{"ok":false,"detail":"y","at":%s}}' "$now" "$now" > /tmp/review-lane-probe.json
has "both outside lanes down falls to sonnet" "$(python3 "$RL" pick)" "lane: sonnet"
has "ab offers two lanes" "$(python3 "$RL" ab)" "B: opus"

python3 "$RL" record --lane sonnet --change repo#1 --found 4 --confirmed 3 --false-positive 1 >/dev/null
python3 "$RL" record --lane sonnet --change repo#2 --found 6 --confirmed 3 --false-positive 3 >/dev/null
has "report sums a lane's reviews and precision" "$(python3 "$RL" report)" "sonnet                 2     10          6       4        60%"
python3 "$RL" record --lane nobody --change x --found 1 --confirmed 1 --false-positive 0 >/dev/null 2>&1
eq "an unknown lane is refused" "$?" "2"

if [ -f "$T/probe.keep" ]; then cp "$T/probe.keep" /tmp/review-lane-probe.json; else trash /tmp/review-lane-probe.json >/dev/null 2>&1; fi
export HOME="$REAL_HOME"; trash "$T" >/dev/null 2>&1
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
