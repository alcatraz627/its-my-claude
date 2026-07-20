#!/usr/bin/env bash
# vitals-timeline.sh — append one dated vitals reading to the timeline (WS3).
#
# Runs gcc-vitals.sh --json, stamps it with the reading time, and appends one line
# to vitals/timeline.jsonl. That file's git history IS the config's health trajectory
# over time — small, low-churn (one line per run), diff-able. This is the "store the
# data on git" answer: version the TREND, not the raw churn.
#
# Idempotent-per-day by default: re-running the same day replaces that day's line
# rather than piling up (a weekly cadence means at most ~52 lines/year). Pass --force
# to append unconditionally.
#
# NOT scheduled by this script. A recurring reading needs a cron/launchd job, which
# is a separate, user-gated step (rules/scheduling-discipline.md: every cron also gets
# a companion Calendar event + a migration entry). This script is what that job WOULD
# run; wiring the schedule is the human's call.
#
# Test override: VITALS_TIMELINE relocates the output.
set -uo pipefail

G="$HOME/.claude"
OUT="${VITALS_TIMELINE:-$G/vitals/timeline.jsonl}"
VITALS="${GCC_VITALS_BIN:-$G/scripts/gcc-vitals.sh}"
FORCE=0; [ "${1:-}" = "--force" ] && FORCE=1

mkdir -p "$(dirname "$OUT")"

# date is passed in (not read via an unavailable helper) — the reading's own clock.
day=$(date -u +%Y-%m-%d)
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

vitals_json=$(bash "$VITALS" --json 2>/dev/null) || { echo "vitals-timeline: gcc-vitals.sh failed" >&2; exit 1; }
printf '%s' "$vitals_json" | jq -e . >/dev/null 2>&1 || { echo "vitals-timeline: vitals produced invalid JSON" >&2; exit 1; }

line=$(jq -cn --arg day "$day" --arg ts "$ts" --argjson v "$vitals_json" '{day:$day, ts:$ts} + $v')

if [ "$FORCE" -eq 0 ] && [ -f "$OUT" ]; then
  # Replace today's existing line (idempotent per day), keep all others in order.
  tmp=$(mktemp "${TMPDIR:-/tmp}/vt-XXXXXX")
  jq -c --arg day "$day" 'select(.day != $day)' "$OUT" 2>/dev/null > "$tmp" || true
  printf '%s\n' "$line" >> "$tmp"
  mv -f "$tmp" "$OUT"
else
  printf '%s\n' "$line" >> "$OUT"
fi
echo "appended vitals reading for $day → $OUT"
