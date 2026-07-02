#!/usr/bin/env bash
# warn-log.sh — telemetry for WARN-emitting hooks (an event-ledger writer).
#
# A WARN hook calls this when it fires so hook fire-rate becomes continuously
# observable — instead of needing a forensic transcript replay to discover a hook
# has gone noisy. Each call appends ONE ledger-format line to the warn-events
# stream, keyed by hook_id (the SAME id used in the hook registry + feedback.jsonl),
# so a reader can join a fire back to the specific hook that raised it.
#
# The line carries two load-bearing envelope fields on top of the telemetry:
#   - id   — makes the line visible to ledger.sh (its reader drops id-less lines).
#   - kind:"warn" — the classifier the hook-warn-burn detector keys on.
#
# Contract (unchanged, and itself load-bearing — a WARN hook must never be broken
# by its own telemetry):
#   - CLI:        warn-log.sh --hook <id> [--heeded true|false|unknown]
#   - never-fail: any internal error is swallowed; it ALWAYS exits 0.
#   - silent no-op when called without --hook.
#
# Test override: WARN_LOG_STORE relocates the store so tests never touch the live
# path. Spec: ~/.claude/skills/shared/ledger-format.md
set -uo pipefail

LOG="${WARN_LOG_STORE:-$HOME/.claude/hooks/warn-events.jsonl}"
LOCK="$(dirname "$LOG")/.warn-events.lock"

hook_id="" heeded="unknown"
while [ $# -gt 0 ]; do
  case "$1" in
    --hook)   hook_id="${2:-}"; shift 2 ;;
    --heeded) heeded="${2:-unknown}"; shift 2 ;;
    *) shift ;;
  esac
done
[ -n "$hook_id" ] || exit 0   # silent no-op on misuse; never break the calling hook

# The sanctioned ledger writer (id-gen + timestamp + flock append). If it can't be
# sourced, fall back to byte-compatible inline equivalents so telemetry still works
# and the calling hook is never broken by a missing shared lib.
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../ledger/ledger-common.sh" 2>/dev/null || true
if ! declare -f ledger_id >/dev/null 2>&1; then
  ledger_id()     { printf '%s-%s-%02x\n' "$1" "$(date -u '+%Y%m%d-%H%M%S')" $((RANDOM % 256)); }
  ledger_ts()     { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
  ledger_append() { ( flock -x 9 2>/dev/null || true; printf '%s\n' "$3" >> "$1"; ) 9>>"$2"; }
fi
: "${LEDGER_STRIP_EMPTY:=with_entries(select(.value != \"\" and .value != null))}"

sid="${CLAUDE_SESSION_ID:-}"
[ -z "$sid" ] && [ -f "$HOME/.claude/.current-session-id" ] && sid=$(cat "$HOME/.claude/.current-session-id" 2>/dev/null)

{
  id=$(ledger_id warn)
  ts=$(ledger_ts)
  mkdir -p "$(dirname "$LOG")"
  line=$(jq -cn --arg id "$id" --arg ts "$ts" --arg h "$hook_id" --arg sid "$sid" --arg heeded "$heeded" \
    "{id:\$id, ts:\$ts, kind:\"warn\", hook_id:\$h, sid:\$sid, fired:1, heeded:\$heeded} | $LEDGER_STRIP_EMPTY")
  ledger_append "$LOG" "$LOCK" "$line"
} 2>/dev/null || true
exit 0
