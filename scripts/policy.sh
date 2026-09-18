#!/usr/bin/env bash
# policy.sh — one reader for every usage window, with the owner's thresholds.
#
# Prints TIER<TAB>detail and exits 0 (OK or UNKNOWN), 1 (WARN), 2 (STRONG).
# A tier is advisory: the caller still runs; the line asks it to weigh value.
# Owner ruling 2026-09-18 (idream-tracks-0918, D5 note), verbatim thresholds:
#   fable    warn > 80% of the general weekly window; terse warn + nudge to
#            not use it or ask the user above 90%
#   codex    warn above 80% of the codex weekly window (the cron gate keeps its
#            own 75-used stand-down; that is not this script's job)
#   general  the pinchy one: STRONG above 90%; WARN above 80% is the existing
#            weekly-usage hinter. Snoozable per session only.
# Sources: ~/.claude/widgets/.limits.json (statusline) and the codex cache that
# codex-usage-gate.py maintains. A missing or stale source is UNKNOWN, never OK.
#
#   policy.sh fable|codex|general [--json]
# Test overrides: POLICY_LIMITS, POLICY_CODEX, POLICY_MAX_AGE_S (default 1800).
set -uo pipefail
LANE="${1:-}"; shift || true
JSON=0; [ "${1:-}" = "--json" ] && JSON=1
LIMITS="${POLICY_LIMITS:-$HOME/.claude/widgets/.limits.json}"
CODEX="${POLICY_CODEX:-$HOME/.claude/adapters/codex/state/limits.json}"
MAX_AGE="${POLICY_MAX_AGE_S:-1800}"
case "$LANE" in fable|codex|general) ;; *) echo "usage: policy.sh fable|codex|general [--json]" >&2; exit 64;; esac
command -v jq >/dev/null 2>&1 || { printf 'UNKNOWN\tjq unavailable\n'; exit 0; }

say() { # tier detail
  if [ "$JSON" = 1 ]; then jq -cn --arg l "$LANE" --arg t "$1" --arg d "$2" '{lane:$l, tier:$t, detail:$d}'
  else printf '%s\t%s\n' "$1" "$2"; fi
  case "$1" in WARN) exit 1;; STRONG) exit 2;; *) exit 0;; esac
}
fresh() { # file -> 0 if younger than MAX_AGE
  [ -f "$1" ] || return 1
  local age=$(( $(date +%s) - $(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0) ))
  [ "$age" -le "$MAX_AGE" ]
}
reset_in() { # epoch -> "resets in 2d 4h"
  local s=$(( ${1:-0} - $(date +%s) )); [ "$s" -le 0 ] && { echo "reset due"; return; }
  printf 'resets in %dd %dh' $(( s / 86400 )) $(( (s % 86400) / 3600 ))
}

case "$LANE" in
  fable|general)
    fresh "$LIMITS" || say UNKNOWN "no fresh general limits at $LIMITS (statusline not rendering?)"
    wk=$(jq -r '(.week.pct | tonumber? | floor) // empty' "$LIMITS" 2>/dev/null)
    [[ "$wk" =~ ^[0-9]+$ ]] || say UNKNOWN "no numeric week pct in $LIMITS"
    rs=$(reset_in "$(jq -r '.resets_at_weekly // 0' "$LIMITS" 2>/dev/null)")
    if [ "$LANE" = fable ]; then
      if [ "$wk" -gt 90 ]; then say STRONG "general week at ${wk}% ($rs): prefer not to seat fable; if you think it is worth it, ask the owner in one line"
      elif [ "$wk" -gt 80 ]; then say WARN "general week at ${wk}% ($rs): say in the Model Plan what fable buys here that opus does not"
      else say OK "general week at ${wk}%"; fi
    else
      if [ "$wk" -gt 90 ]; then say STRONG "general week at ${wk}% ($rs): before any big action name its cost and get a go; snoozable per session only"
      elif [ "$wk" -gt 80 ]; then say WARN "general week at ${wk}% ($rs): estimate big actions in one line before running them"
      else say OK "general week at ${wk}%"; fi
    fi;;
  codex)
    fresh "$CODEX" || say UNKNOWN "no fresh codex limits at $CODEX (run codex-usage-gate.py --fresh)"
    used=$(jq -r '.rateLimits.secondary.usedPercent // empty' "$CODEX" 2>/dev/null)
    [[ "$used" =~ ^[0-9]+$ ]] || say UNKNOWN "no weekly usedPercent in $CODEX"
    rs=$(reset_in "$(jq -r '.rateLimits.secondary.resetsAt // 0' "$CODEX" 2>/dev/null)")
    if [ "$used" -gt 80 ]; then say WARN "codex week at ${used}% ($rs): weigh whether this review is worth the quota; a spent quota is fine if it helped"
    else say OK "codex week at ${used}%"; fi;;
esac
