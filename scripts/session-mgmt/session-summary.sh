#!/usr/bin/env bash
# Stop hook: show visual session summary (stderr only — no context injection)
set -uo pipefail

input=$(cat)

# Parse session data
session_id=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null) || true
sid_short="${session_id:0:8}"

# Only show after meaningful sessions (>5 turns, >2 min)
TURN_FILE="/tmp/claude-turns-${sid_short}"
turn_count=0
[[ -f "$TURN_FILE" ]] && turn_count=$(cat "$TURN_FILE" 2>/dev/null | tr -d '[:space:]') || true
turn_count=${turn_count:-0}
(( turn_count < 5 )) && exit 0

# Cooldown: don't show more than once per 5 minutes
COOLDOWN_FILE="/tmp/claude-summary-cooldown-${sid_short}"
if [[ -f "$COOLDOWN_FILE" ]]; then
  last_shown=$(cat "$COOLDOWN_FILE" 2>/dev/null | tr -d '[:space:]')
  now=$(date +%s)
  (( now - ${last_shown:-0} < 300 )) && exit 0
fi
date +%s > "$COOLDOWN_FILE" 2>/dev/null || true

# Read stats
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null) || true
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0' 2>/dev/null) || true
lines_add=$(echo "$input" | jq -r '.cost.total_lines_added // 0' 2>/dev/null) || true
lines_rm=$(echo "$input" | jq -r '.cost.total_lines_removed // 0' 2>/dev/null) || true
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // "" ' 2>/dev/null) || true

# Format duration
total_sec=0
[[ -n "$duration_ms" && "$duration_ms" != "null" && "$duration_ms" != "0" ]] && total_sec=$(( ${duration_ms%.*} / 1000 ))
if (( total_sec >= 3600 )); then
  dur_fmt="$(( total_sec / 3600 ))h$(( (total_sec % 3600) / 60 ))m"
elif (( total_sec >= 60 )); then
  dur_fmt="$(( total_sec / 60 ))m$(( total_sec % 60 ))s"
else
  dur_fmt="${total_sec}s"
fi

# Format cost
cost_fmt=$(printf "%.2f" "${cost_usd:-0}" 2>/dev/null || echo "0.00")

# Read tool counters
TOOL_FILE="/tmp/claude-tools-${PPID}"
tool_line=""
if [[ -f "$TOOL_FILE" ]]; then
  tool_line=$(grep -v '^_total=' "$TOOL_FILE" 2>/dev/null | sort -t= -k2 -rn | head -4 | awk -F= '{printf "%s:%s ", $1, $2}')
fi

# Context usage
ctx_str=""
if [[ -n "$remaining" && "$remaining" != "null" ]]; then
  used=$(echo "$remaining" | awk '{printf "%d", 100 - $1}')
  ctx_str="${used}% used"
fi

# Colors
dim="\033[2m"  rst="\033[0m"  grn="\033[32m"  red="\033[31m"
cyn="\033[36m" ylw="\033[33m" bld="\033[1m"

{
  echo ""
  printf "${dim}╭─ Session Summary ────────────────────────────╮${rst}\n"
  printf "${dim}│${rst} ${cyn}%s turns${rst} ${dim}│${rst} %s ${dim}│${rst} \$%s" "$turn_count" "$dur_fmt" "$cost_fmt"
  [[ -n "$ctx_str" ]] && printf " ${dim}│${rst} %s" "$ctx_str"
  printf "\n"
  if [[ "${lines_add:-0}" != "0" || "${lines_rm:-0}" != "0" ]]; then
    printf "${dim}│${rst} ${grn}+%s${rst} ${red}-%s${rst} lines" "${lines_add:-0}" "${lines_rm:-0}"
    printf "\n"
  fi
  if [[ -n "$tool_line" ]]; then
    printf "${dim}│${rst} ${dim}Tools: %s${rst}\n" "${tool_line% }"
  fi
  printf "${dim}╰──────────────────────────────────────────────╯${rst}\n"
} >&2
