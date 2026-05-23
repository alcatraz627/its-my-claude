#!/usr/bin/env bash
# hook-feedback.sh — the agent vent channel for ~/.claude hooks.
#
# When a hook blocks or nudges you and you think it's wrong/obstructive (or
# genuinely useful), record one line here INSTEAD of routing around the guard.
# Feeds the claude-audit i-dream domain → which hooks earn their friction.
#
# Usage:
#   hook-feedback.sh --hook <id> --kind <kind> --note "..." [--cmd "..."]
# kinds: false-positive | obstructive | confusing | slowed-me-down | too-aggressive | useful
#
# Appends one JSON line to ~/.claude/hooks/feedback.jsonl (append-only).

set -uo pipefail

LOG="$HOME/.claude/hooks/feedback.jsonl"
VALID_KINDS="false-positive obstructive confusing slowed-me-down too-aggressive useful"

hook_id="" kind="" note="" cmd=""
while [ $# -gt 0 ]; do
  case "$1" in
    --hook) hook_id="$2"; shift 2 ;;
    --kind) kind="$2"; shift 2 ;;
    --note) note="$2"; shift 2 ;;
    --cmd)  cmd="$2"; shift 2 ;;
    *) shift ;;
  esac
done

[ -n "$hook_id" ] && [ -n "$kind" ] || {
  printf 'usage: %s --hook <id> --kind <%s> --note "..." [--cmd "..."]\n' "$0" "${VALID_KINDS// /|}" >&2
  exit 2
}
case " $VALID_KINDS " in
  *" $kind "*) : ;;
  *) printf 'invalid --kind %s (valid: %s)\n' "$kind" "$VALID_KINDS" >&2; exit 2 ;;
esac

sid="${CLAUDE_SESSION_ID:-}"
[ -z "$sid" ] && [ -f "$HOME/.claude/.current-session-id" ] && sid=$(cat "$HOME/.claude/.current-session-id" 2>/dev/null)
ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
id="fb-$(date -u +%Y%m%d-%H%M%S)-$$-$(printf '%04x%04x' "$RANDOM" "$RANDOM")"

mkdir -p "$(dirname "$LOG")"
jq -nc \
  --arg id "$id" --arg ts "$ts" --arg sid "$sid" \
  --arg hook_id "$hook_id" --arg kind "$kind" \
  --arg note "$note" --arg cmd "$cmd" \
  '{id:$id, ts:$ts, sid:$sid, hook_id:$hook_id, kind:$kind, note:$note, command_or_context:$cmd}' \
  >> "$LOG" 2>/dev/null

printf 'logged hook-feedback %s [%s] %s\n' "$id" "$kind" "$hook_id"
