#!/usr/bin/env bash
# Summarise how the todo-sync system has actually been behaving, from the run
# log it writes. This is the artifact a periodic review reads to decide whether
# the sync is helping, over-burdening, or silently failing.
#
# Usage: telemetry.sh [--since YYYY-MM-DD]   (default: all history)

set -uo pipefail

LOG="$HOME/.claude/logs/sync-todos.log"
WAL="$HOME/.claude/sync-wal.jsonl"
SINCE=""
[ "${1:-}" = "--since" ] && SINCE="${2:-}"

if [ ! -s "$LOG" ]; then
  echo "todo-sync telemetry: no data yet ($LOG empty/absent)."
  echo "→ The Stop hook writes one line per turn once a session uses the Task tool."
  exit 0
fi

# Window the log if --since given (lexical compare on the ISO ts works).
WORK=$(mktemp)
trap 'rm -f "$WORK"' EXIT
if [ -n "$SINCE" ]; then
  jq -c --arg s "$SINCE" 'select((.ts // "") >= $s)' "$LOG" 2>/dev/null > "$WORK"
else
  cp "$LOG" "$WORK"
fi

count() { rg -c "$1" "$WORK" 2>/dev/null || echo 0; }
first_ts=$(head -1 "$WORK" | jq -r '.ts // "?"' 2>/dev/null)
last_ts=$(tail -1 "$WORK" | jq -r '.ts // "?"' 2>/dev/null)
lines=$(wc -l < "$WORK" | tr -d ' ')

runs=$(count '"event":"run ')
stale_runs=$(count '"event":"run [^"]*stale=1')
blocks=$(count '"event":"drift-block')
escapes=$(count '"event":"drift-escape')
mirror_total=$(count '"event":"mirror ')
mirror_changed=$(count '"event":"mirror changed=true')
nudge_drift=$(count '"event":"nudge:drift')
nudge_hb=$(count '"event":"nudge:heartbeat')
warn_empty=$(count 'empty-replay')
lock_skip=$(count 'lock-contention-skip')
sessions=$(jq -r '.sid' "$WORK" 2>/dev/null | grep -vx '-' | sort -u | grep -c . || echo 0)

pct() { [ "${2:-0}" -gt 0 ] 2>/dev/null && awk "BEGIN{printf \"%.0f%%\", $1*100/$2}" || echo "n/a"; }

echo "════════════════════════════════════════════════════════"
echo "  todo-sync telemetry  ${SINCE:+(since $SINCE)}"
echo "  $first_ts  →  $last_ts   ($lines events, $sessions session(s))"
echo "════════════════════════════════════════════════════════"
echo
echo "  ACTIVITY"
echo "    Stop runs (turns synced):     $runs"
echo "    mirror wrote a change:        $mirror_changed / $mirror_total  ($(pct "$mirror_changed" "$mirror_total"))"
echo
echo "  FRESHNESS / PRESSURE  (is the agent keeping the list current?)"
echo "    runs where list was stale:    $stale_runs / $runs  ($(pct "$stale_runs" "$runs"))"
echo "    drift BLOCKS (intrusive):     $blocks"
echo "    drift escapes (one-shot):     $escapes"
echo
echo "  NUDGES  (soft, per-prompt)"
echo "    heartbeat nudges:             $nudge_hb"
echo "    drift follow-up nudges:       $nudge_drift"
echo
echo "  HEALTH  (should be ~0)"
echo "    empty-replay warnings:        $warn_empty"
echo "    lock-contention skips:        $lock_skip"
echo
echo "  READ THE RAW EVENTS:  rg <event> $LOG"
echo "  e.g.  rg '\"event\":\"drift-block' $LOG"
