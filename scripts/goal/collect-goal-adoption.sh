#!/usr/bin/env bash
# collect-goal-adoption.sh — the observation window for the goal re-arm fix.
#
# Shipped 2026-08-18: goal.sh (harness + gcc goal), the 37-goal-standing hinter,
# and core-dump/catchup edits that record and re-arm the goal. This appends one dated
# block per run to the observation log, from files only (no LLM, no ipc sends):
#   * every gcc goal file, with who set it and when
#   * every checkpoint written since the ship whose Live commitments carry the new
#     "harness ARMED|not armed" state, and whether it has a Re-arm block
#   * peer replies waiting for gcc-work-78 that mention goal / re-arm
# Read-only except for the log. Run by hand or by the scheduled one-shots.
set -uo pipefail
LOG="$HOME/.claude/assets/reports/20260818-goal-rearm-observation/log.md"
SINCE="${1:-2026-08-18T13:00}"   # ISO local; the ship time
{
echo; echo "## run $(date '+%Y-%m-%d %H:%M %z')"; echo
echo "### gcc goals on disk"; bash "$HOME/.claude/scripts/goal/goal.sh" survey | sed 's/^/- /'; [ -z "$(ls "$HOME/.claude/goals"/*.json 2>/dev/null)" ] && echo "- none"
echo; echo "### checkpoints since $SINCE carrying the new goal state"
jq -r --arg s "$SINCE" 'select(.ts >= $s) | "\(.ts) \(.name) \(.checkpoint_path)"' "$HOME/.claude/checkpoints/index.jsonl" 2>/dev/null | while read -r ts name path; do
  [ -f "$path" ] || continue
  g=$(rg -o -m1 "goal: [^·]{0,80}·[^\n]{0,60}" "$path" 2>/dev/null | head -1)
  h=$(rg -c "harness (ARMED|not armed)" "$path" 2>/dev/null); r=$(rg -c "^## Re-arm in the TUI" "$path" 2>/dev/null)
  echo "- $ts $name · harness-state:${h:-0} re-arm-block:${r:-0} · $g"
done
echo; echo "### peer mail mentioning goal/re-arm (gcc-work-78 inbox)"
claude-ipc inbox gcc-work-78 2>/dev/null | jq -r '.messages[] | select(.body|test("goal|re-arm|rearm";"i")) | "- \(.fromAlias) [\(.id)]: \(.body[0:160])"' 2>/dev/null
echo; echo "### live sessions (heartbeat) and whether each has a gcc goal"
claude-ipc peers 2>/dev/null | jq -r '.peers[] | select(.status!="offline" and (.sinceSeenS < 14400)) | "\(.alias)\t\(.sessionId)\t\(.cwd)\t\(.sinceSeenS/60|floor)"' 2>/dev/null | while IFS=$'\t' read -r a sid cwd m; do
  g="none"; [ -f "$HOME/.claude/goals/$sid.json" ] && g="set ($(jq -r .by "$HOME/.claude/goals/$sid.json"))"
  echo "- $a ($cwd, seen ${m}m ago) · gcc goal: $g"; done
} >> "$LOG"
echo "appended to $LOG"
