#!/bin/bash
# usage-gate.sh — may an autonomous institution spend tokens right now?
#
# Owner ruling 2026-08-21: the warden and the residue-review stand down when
# either usage window is nearly spent. An institution that eats the owner's
# task capacity is worse than none. This gate answers yes or no from the
# statusline's limits telemetry; the callers skip their model invocation on no.
#
#   exit 0  PASS    headroom in both windows, or an honest UNKNOWN (a broken
#                   statusline must not silently kill the institutions; the
#                   caller logs the detail line so UNKNOWN stays visible)
#   exit 1  GATED   5h or weekly window above the threshold; skip the invoke
#
# Prints one TAB-separated line: VERDICT<TAB>detail.
#
# Env:
#   USAGE_GATE_FILE       source file (default ~/.claude/widgets/.limits.json,
#                         written by every statusline render)
#   USAGE_GATE_PCT        threshold, default 90
#   USAGE_GATE_MAX_AGE_S  staleness bound on the file, default 1800
set -uo pipefail

LIMITS="${USAGE_GATE_FILE:-$HOME/.claude/widgets/.limits.json}"
THRESHOLD="${USAGE_GATE_PCT:-90}"
MAX_AGE="${USAGE_GATE_MAX_AGE_S:-1800}"

say() { printf '%s\t%s\n' "$1" "$2"; }

case "$THRESHOLD" in ''|*[!0-9]*) THRESHOLD=90 ;; esac
[ "${#THRESHOLD}" -gt 3 ] && THRESHOLD=90

command -v jq >/dev/null 2>&1 || { say PASS "UNKNOWN: jq unavailable"; exit 0; }
[ -f "$LIMITS" ] || { say PASS "UNKNOWN: no limits file at $LIMITS"; exit 0; }

age=$(( $(date +%s) - $(stat -f %m "$LIMITS" 2>/dev/null || echo 0) ))
[ "$age" -gt "$MAX_AGE" ] && { say PASS "UNKNOWN: limits file ${age}s stale (statusline not rendering?)"; exit 0; }

# Allow-list shape check per window, the limits-check.sh lesson: state what a
# reading looks like and reject the rest. An unreadable window is skipped, not
# treated as 0 — but an unreadable pair is an UNKNOWN pass, never a quiet 0/0.
read_pct() {
  local p
  p=$(jq -r --arg k "$1" '(.[$k].pct | tonumber? | floor) // empty' "$LIMITS" 2>/dev/null)
  [[ "$p" =~ ^[0-9]+$ ]] || return 1
  [ "${#p}" -gt 4 ] && return 1
  printf '%s' "$p"
}

h5=$(read_pct "5h") || h5=""
wk=$(read_pct "week") || wk=""
[ -z "$h5" ] && [ -z "$wk" ] && { say PASS "UNKNOWN: no numeric 5h/week pct in $LIMITS"; exit 0; }

detail="5h=${h5:-?}% wk=${wk:-?}%"
if { [ -n "$h5" ] && [ "$h5" -gt "$THRESHOLD" ]; } || { [ -n "$wk" ] && [ "$wk" -gt "$THRESHOLD" ]; }; then
  say GATED "$detail (threshold ${THRESHOLD}%)"
  exit 1
fi
say PASS "$detail"
exit 0
