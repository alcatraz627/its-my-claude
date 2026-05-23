#!/usr/bin/env bash
# warn-log.sh — telemetry for WARN-emitting hooks.
#
# A WARN hook calls this when it fires so the claude-audit domain can see
# fire-rate (and, best-effort, whether the agent heeded it). Keyed by hook_id —
# the SAME id used in feedback.jsonl + the hook registry — so the extractor can
# join them.
#
# Usage (from inside a hook): warn-log.sh --hook <id> [--heeded true|false|unknown]
# Appends one JSON line to ~/.claude/hooks/warn-events.jsonl (append-only).

set -uo pipefail

LOG="$HOME/.claude/hooks/warn-events.jsonl"
hook_id="" heeded="unknown"
while [ $# -gt 0 ]; do
  case "$1" in
    --hook)   hook_id="$2"; shift 2 ;;
    --heeded) heeded="$2"; shift 2 ;;
    *) shift ;;
  esac
done
[ -n "$hook_id" ] || exit 0   # silent no-op on misuse; never break the calling hook

sid="${CLAUDE_SESSION_ID:-}"
[ -z "$sid" ] && [ -f "$HOME/.claude/.current-session-id" ] && sid=$(cat "$HOME/.claude/.current-session-id" 2>/dev/null)
ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

mkdir -p "$(dirname "$LOG")"
jq -nc --arg ts "$ts" --arg h "$hook_id" --arg sid "$sid" --arg heeded "$heeded" \
  '{ts:$ts, hook_id:$h, sid:$sid, fired:1, heeded:$heeded}' \
  >> "$LOG" 2>/dev/null || true
exit 0
