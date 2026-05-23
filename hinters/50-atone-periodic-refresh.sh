#!/usr/bin/env bash
# 50-atone-periodic-refresh.sh — fires every N turns (default 12).
#
# Injects a small map of the most-relevant triggers from triggers.json,
# rotating through high-weight items so nothing stays stale.
#
# Acts as a mid-session bookmark, not a briefing. Links to deeper context.
#
# Skip conditions:
#   - ~/.claude/atone/.refresh-off exists (mute)
#   - turn count not divisible by N
#   - no triggers.json yet (consolidate hasn't run)

set -uo pipefail

[ -f "$HOME/.claude/atone/.refresh-off" ] && exit 0

TRIGGERS="$HOME/.claude/atone/derived/triggers.json"
[ -f "$TRIGGERS" ] || exit 0

CONFIG="$HOME/.claude/atone/config.json"
N=12; TOP_ATONE=3; TOP_AFFIRM=1
if [ -f "$CONFIG" ] && command -v jq >/dev/null 2>&1; then
  N=$(jq -r '.periodic_refresh_n // 12' "$CONFIG" 2>/dev/null)
  TOP_ATONE=$(jq -r '.periodic_refresh_top_atone // 3' "$CONFIG" 2>/dev/null)
  TOP_AFFIRM=$(jq -r '.periodic_refresh_top_affirm // 1' "$CONFIG" 2>/dev/null)
fi

# Per-session turn counter
SESSION_KEY="${CLAUDE_SESSION_ID:-$(date +%Y-%m-%d)}"
STATE_DIR="$HOME/.claude/atone/.session-state"
mkdir -p "$STATE_DIR" 2>/dev/null || true
COUNTER_FILE="$STATE_DIR/$SESSION_KEY.refresh-turn"
TURN=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
echo "$TURN" > "$COUNTER_FILE"

# Fire only on N, 2N, 3N, ...
[ $((TURN % N)) -eq 0 ] || exit 0

command -v jq >/dev/null 2>&1 || exit 0

# Pick top-N atone + top-M affirm by weight (high > medium)
WEIGHT_RANK='if .weight=="high" then 3 elif .weight=="medium" then 2 else 1 end'

echo "[atone-refresh turn $TURN] Mid-session check (mute: touch ~/.claude/atone/.refresh-off):"
jq -r --argjson n "$TOP_ATONE" --arg wrank "$WEIGHT_RANK" '
  [.[] | select(.from_source == "atone")]
  | sort_by([(.weight | (if . == "high" then 3 elif . == "medium" then 2 else 1 end)), .confidence_score])
  | reverse | .[:$n]
  | .[] | "  ⚠️  [\(.severity_band), \(.weight)] \(.from_slug) — \(.instruction)"
' "$TRIGGERS" 2>/dev/null

jq -r --argjson n "$TOP_AFFIRM" '
  [.[] | select(.from_source == "affirm")]
  | sort_by([(.weight | (if . == "high" then 3 elif . == "medium" then 2 else 1 end)), .confidence_score])
  | reverse | .[:$n]
  | .[] | "  ✓   [\(.weight)] \(.from_slug) — \(.instruction)"
' "$TRIGGERS" 2>/dev/null

echo "  bash ~/.claude/scripts/atone.sh triggers <kw>     fetch by topic keyword"
echo "  bash ~/.claude/scripts/atone.sh show <id>          full event + RCA"
