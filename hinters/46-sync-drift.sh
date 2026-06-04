#!/usr/bin/env bash
# UserPromptSubmit hinter — soft follow-up for task-list drift.
#
# When the Stop hook detected a stale task list but couldn't block (the one-shot
# escape, so a turn is never trapped), it leaves a marker. This surfaces that
# marker on the next prompt as a gentle reminder, then clears it. The loud
# channel is the Stop block itself; this is only the quiet second tap.
#
# Hinters receive only the prompt text on stdin (not the event json / session
# id — see hint-injector.sh), so we pick the newest recent marker rather than
# key on a session id we can't trust here. Latency budget <100ms.

set -uo pipefail

[ -f "$HOME/.claude/sync-disabled" ] && exit 0
[ -f "$HOME/.claude/scripts/sync-todos/.hinter-off" ] && exit 0

# Same single-session safety as the heartbeat (47): hinters get no session id,
# so only surface a marker when EXACTLY ONE is recent — otherwise we might replay
# another session's nudge. Sweep abandoned markers regardless.
# NB: trailing slash on /tmp/ is required — /tmp is a symlink to /private/tmp on
# macOS and BSD find won't descend a symlink start point without it.
find /tmp/ -maxdepth 1 -name 'claude-todo-drift-*.json' -mmin +30 -delete 2>/dev/null
recent=$(find /tmp/ -maxdepth 1 -name 'claude-todo-drift-*.json' -mmin -5 2>/dev/null)
[ -n "$recent" ] || exit 0
[ "$(printf '%s\n' "$recent" | grep -c .)" = "1" ] || exit 0
marker="$recent"

reason=$(jq -r '.reason // ""' "$marker" 2>/dev/null)
rm -f "$marker" 2>/dev/null
[ -n "$reason" ] || exit 0

printf '{"ts":"%s","sid":"-","event":"nudge:drift"}\n' \
  "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$HOME/.claude/logs/sync-todos.log" 2>/dev/null || true
printf '[task-sync] %s\n' "$reason"
