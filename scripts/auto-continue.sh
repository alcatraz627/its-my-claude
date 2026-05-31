#!/usr/bin/env bash
# auto-continue.sh — opt a session into error-recovery auto-continue.
#
# Pairs with the Stop hook scripts/hooks/auto-continue-stop.sh. Enabling writes a
# per-session flag; the hook then re-drives THIS session (and only this one) when
# a turn dies on a transient API error, after a cooldown, up to <budget> times.
#
#   auto-continue.sh on [max_retries=3] [cooldown_seconds=30]
#   auto-continue.sh off
#   auto-continue.sh status
#
# Session identity comes from $CLAUDE_CODE_SESSION_ID (the running session's UUID).

set -uo pipefail
DIR="$HOME/.claude/auto-continue"; mkdir -p "$DIR"
sid="${CLAUDE_CODE_SESSION_ID:-${CLAUDE_SESSION_ID:-}}"
[ -n "$sid" ] || { echo "no \$CLAUDE_CODE_SESSION_ID in env — run this inside a Claude Code session"; exit 1; }
flag="$DIR/${sid:0:8}.json"

case "${1:-status}" in
  on)
    maxr="${2:-3}"; cooldown="${3:-30}"
    jq -n --argjson m "$maxr" --argjson c "$cooldown" --arg s "$sid" \
      '{session:$s, max_retries:$m, cooldown:$c, streak:0}' > "$flag"
    echo "✓ auto-continue ON for ${sid:0:8} — error-recovery, max_retries=$maxr/error-run, cooldown=${cooldown}s"
    echo "  re-drives only after a transient API error; clean turn-ends still stop;"
    echo "  streak resets on any clean turn, so a real outage gives up after $maxr tries."
    echo "  log: $DIR/${sid:0:8}.log   ·   disable: auto-continue.sh off"
    ;;
  off)
    rm -f "$flag"; echo "✓ auto-continue OFF for ${sid:0:8}"
    ;;
  status)
    if [ -f "$flag" ]; then echo "ON  ${sid:0:8}:"; jq . "$flag"; else echo "OFF ${sid:0:8} (not opted in)"; fi
    ;;
  *) echo "usage: auto-continue.sh on [budget] [cooldown] | off | status"; exit 2 ;;
esac
