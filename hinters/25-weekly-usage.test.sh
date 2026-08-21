#!/usr/bin/env bash
# 25-weekly-usage.test.sh — fires once per 45m when the weekly window is >80%,
# re-fires on the first prompt after a /clear, and below the threshold leaves
# no state, no log row, and no output at all.
set -uo pipefail
H=/Users/alcatraz627/.claude/hinters/25-weekly-usage.sh; pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }
export CLAUDE_HINT_SID=t25weekly; ST=/tmp/claude-weeklyhint-t25weekl
SEN=/tmp/claude-clear-reset-t25weekl
T=$(mktemp -d); trash "$ST" "$SEN" 2>/dev/null || true
echo '{"week":{"pct":85},"5h":{"pct":20}}' > "$T/hot.json"
echo '{"week":{"pct":72},"5h":{"pct":95}}' > "$T/cool.json"   # 5h has NO bearing
LOG="$HOME/.claude/logs/weekly-usage-hint.jsonl"; lines_before=$(wc -l < "$LOG" 2>/dev/null || echo 0)
run(){ printf '%s' "$2" | WEEKLY_HINT_LIMITS="$1" bash "$H"; }

[ -x "$H" ] && ok "hinter carries the x bit" || ko "not executable"
run "$T/hot.json" "first real prompt" | rg -q "weekly-usage" && ok "over 80: first prompt fires" || ko "first prompt silent"
[ -z "$(run "$T/hot.json" "second prompt")" ] && ok "45m window suppresses the second" || ko "cadence broken"
sleep 1; touch "$SEN"   # sentinel must be strictly newer than the cooldown file
run "$T/hot.json" "first prompt after /clear" | rg -q "weekly-usage" && ok "post-/clear first prompt re-fires (so the fresh context knows)" || ko "post-clear stayed suppressed"
[ -z "$(run "$T/hot.json" "next prompt after that")" ] && ok "clear-reset is one-shot, cadence resumes" || ko "sentinel keeps re-firing"
trash "$ST" "$SEN" 2>/dev/null || true
[ -z "$(run "$T/hot.json" "Wake check. Two steps, in this order.")" ] && ok "wake cron payload: quiet" || ko "wake payload fired"
[ -z "$(run "$T/hot.json" "Warden 3h check-in (docs-skill duty). Review...")" ] && ok "warden check-in payload: quiet" || ko "check-in payload fired"
[ -z "$(run "$T/hot.json" "<system-reminder>x")" ] && ok "machine turn: quiet" || ko "machine turn fired"
trash "$ST" 2>/dev/null || true
[ -z "$(run "$T/cool.json" "a real prompt")" ] && ok "under 80 (even with 5h at 95): silent" || ko "under-threshold fired"
[ ! -f "$ST" ] && ok "under 80: no state file written (model not bothered, no slot spent)" || ko "state written below threshold"
touch "$HOME/.claude/.no-weekly-usage-hint"
[ -z "$(run "$T/hot.json" "a real prompt")" ] && ok "mute honoured" || ko "mute ignored"
trash "$HOME/.claude/.no-weekly-usage-hint"
touch -t 202601010000 "$T/hot.json"
trash "$ST" 2>/dev/null || true
[ -z "$(run "$T/hot.json" "a real prompt")" ] && ok "stale limits file: silent (no reading is not a hot reading)" || ko "stale file fired"
lines_after=$(wc -l < "$LOG" 2>/dev/null || echo 0)
[ $(( lines_after - lines_before )) -eq 2 ] && ok "exactly the 2 real fires reached the telemetry log" || ko "log rows: expected +2, got +$(( lines_after - lines_before ))"
trash "$ST" "$SEN" "$T" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
