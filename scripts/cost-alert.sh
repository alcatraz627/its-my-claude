#!/usr/bin/env bash
# Stop hook: alert when cost velocity is dangerously high
# Outputs warning to stderr only — no context injection
set -uo pipefail

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null) || true
sid_short="${session_id:0:8}"
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null) || true

[[ -z "$cost_usd" || "$cost_usd" == "null" || "$cost_usd" == "0" ]] && exit 0

# Ring buffer file (last 10 cost values)
COST_RING="/tmp/claude-cost-ring-${sid_short}"

# Append current cost (keep last 10)
if [[ -f "$COST_RING" ]]; then
  tail -9 "$COST_RING" > "${COST_RING}.tmp" 2>/dev/null
  echo "$cost_usd" >> "${COST_RING}.tmp"
  mv "${COST_RING}.tmp" "$COST_RING" 2>/dev/null || true
else
  echo "$cost_usd" > "$COST_RING"
  exit 0  # Need at least 2 data points
fi

# Read ring buffer
costs=()
while IFS= read -r val; do
  [[ -n "$val" ]] && costs+=("$val")
done < "$COST_RING"

count=${#costs[@]}
(( count < 5 )) && exit 0  # Need 5+ turns for meaningful velocity

# Cooldown: don't alert more than once per 10 turns
ALERT_COOLDOWN="/tmp/claude-cost-alert-cooldown-${sid_short}"
if [[ -f "$ALERT_COOLDOWN" ]]; then
  last_alert_turn=$(cat "$ALERT_COOLDOWN" 2>/dev/null | tr -d '[:space:]')
  TURN_FILE="/tmp/claude-turns-${sid_short}"
  current_turn=0
  [[ -f "$TURN_FILE" ]] && current_turn=$(cat "$TURN_FILE" 2>/dev/null | tr -d '[:space:]') || true
  (( current_turn - ${last_alert_turn:-0} < 10 )) && exit 0
fi

# Compute velocity: cost change over last 3 entries
old_cost="${costs[$((count - 4))]}"
new_cost="${costs[$((count - 1))]}"
# Use awk for float arithmetic
velocity=$(awk "BEGIN {v=($new_cost - $old_cost) / 3; printf \"%.2f\", v}" 2>/dev/null)
projected=$(awk "BEGIN {printf \"%.2f\", $velocity * 30}" 2>/dev/null)

# Alert threshold: >$0.30/turn velocity
is_high=$(awk "BEGIN {print ($velocity > 0.30) ? 1 : 0}" 2>/dev/null)

if [[ "$is_high" == "1" ]]; then
  # Record cooldown
  TURN_FILE="/tmp/claude-turns-${sid_short}"
  current_turn=0
  [[ -f "$TURN_FILE" ]] && current_turn=$(cat "$TURN_FILE" 2>/dev/null | tr -d '[:space:]') || true
  echo "$current_turn" > "$ALERT_COOLDOWN" 2>/dev/null || true

  # Output warning to stderr
  ylw="\033[33m" rst="\033[0m" dim="\033[2m" bld="\033[1m"
  {
    printf "${ylw}${bld} Cost velocity: \$%s/turn${rst} ${dim}— projected \$%s for 30 more turns${rst}\n" "$velocity" "$projected"
  } >&2
fi
