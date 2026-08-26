#!/usr/bin/env bash
# harness-usage.sh — did the 2026-08-26 harness get used? One report, four counters,
# each from an instrument, none from memory. Scheduled 3 days after the build and at
# the next two weekly reviews (owner, 2026-08-27). Writes a dated report and prints it.
#   lanes  : revive / ipc-wake verdict lines in warden/beat.log since the arm date
#   done   : session-state files written; finished refusals in revive.jsonl
#   rules  : atone recurrences since the arm date for the slugs the new rules target
#   skills : skill census delta for routers, parked, and the new modes/personas
set -uo pipefail
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
SINCE="${1:-2026-08-26}"; OUT="$HOME/.claude/assets/reports/harness-usage/$(date +%F).md"; mkdir -p "$(dirname "$OUT")"
W="$HOME/.claude/warden"; C="$HOME/.claude/assets/reports/20260826-agent-failure-consolidation/corpus"
{
echo "# Harness usage since $SINCE, measured $(date '+%F %H:%M')"; echo
echo "## Lanes (warden/beat.log)"
for v in WOKEN REVIVING idle-legitimate REFUSED gated capped stale finished blocked; do printf '%-16s %s\n' "$v" "$(rg -c "^$SINCE|^2026-0[89]" "$W/beat.log" >/dev/null 2>&1; awk -v s="$SINCE" -v v="$v" '$1>=s && ($0 ~ "revive " || $0 ~ "ipc-wake ") && $0 ~ v {n++} END{print n+0}' "$W/beat.log")"; done
echo; echo "## Done (session-state)"
printf 'state files: %s  finished: %s  blocked: %s\n' "$(ls "$HOME/.claude/session-state"/*.json 2>/dev/null | wc -l | tr -d ' ')" "$(cat "$HOME/.claude/session-state"/*.json 2>/dev/null | jq -r .state | rg -c finished || echo 0)" "$(cat "$HOME/.claude/session-state"/*.json 2>/dev/null | jq -r .state | rg -c blocked || echo 0)"
echo; echo "## Rules (atone recurrences since $SINCE for the targeted slugs)"
for s in dense-briefing-instead-of-a-direct-answer halted-for-a-goahead-already-granted declared-ready-without-runtime-exercise shipping-css-ui-changes-without-visual-verification literal-request-over-intent structural-claim-without-reading-code; do printf '%-52s %s\n' "$s" "$(bash "$HOME/.claude/scripts/atone.sh" list 2>/dev/null | awk -v s="$SINCE" -v k="$s" '$1>=s && $0 ~ k {n++} END{print n+0}')"; done
echo; echo "## Skills (census over the whole corpus; compare with the 2026-08-26 baseline in $C/census.json)"
python3 "$C/skill-census3.py" >/dev/null 2>&1 && for k in router pick-skill plan ui validate intake persona create-skill callouts probe; do printf '%-14s now %-5s baseline %s\n' "$k" "$(jq -r --arg k "$k" '.skills[$k].total // 0' "$C/census.json")" "$(jq -r --arg k "$k" '.skills[$k].total // 0' "$C/census.baseline-20260826.json" 2>/dev/null || echo '?')"; done
echo; echo "## The number (re-run by hand after a real absence): python3 $C/probe-absence2.py 1  (baseline 83% dead, 29 windows)"
} | tee "$OUT"
echo; echo "written: $OUT"
