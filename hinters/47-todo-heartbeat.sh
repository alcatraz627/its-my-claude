#!/usr/bin/env bash
# UserPromptSubmit heartbeat — keep the live task list in step with the current
# focus, the moment it drifts.
#
# A new prompt is the natural point where focus shifts, so this fires there: if
# the task list has sat unchanged across a couple of working turns while real
# edits happened, it nudges the agent to reconcile (TaskCreate/TaskUpdate) — and
# that reconciliation auto-flows to the notes + memory via the Stop writeback.
# It self-silences the instant the list changes (the Stop hook resets the
# counter), so a well-maintained list never sees it.
#
# It reuses the drift state the Stop hook already computes
# (~/.claude/tasks/.sync-<sid>.json), picking the newest — hinters receive only
# the prompt text on stdin (hint-injector.sh), never the session id. Latency <100ms.

set -uo pipefail

[ -f "$HOME/.claude/sync-disabled" ] && exit 0
[ -f "$HOME/.claude/scripts/sync-todos/.hinter-off" ] && exit 0

# Hinters get no session id (hint-injector passes only the prompt), so we can't
# know which .sync-*.json is ours. Only act when EXACTLY ONE session has been
# active in the last few minutes — then it's unambiguously the current one. With
# two concurrent sessions we stay silent (fail-safe: no nudge beats wrong-session
# nudge). Cross-session limit is documented in migration 0017.
recent=$(find "$HOME/.claude/tasks" -maxdepth 1 -name '.sync-*.json' -mmin -5 2>/dev/null)
[ -n "$recent" ] || exit 0
[ "$(printf '%s\n' "$recent" | grep -c .)" = "1" ] || exit 0
state="$recent"

turns=$(jq -r '.turns_since_change // 0' "$state" 2>/dev/null || echo 0)
edits=$(jq -r '.edits_since_change // 0' "$state" 2>/dev/null || echo 0)

# Give-up cap. Two unheeded nudges per drift episode is the ceiling: past that,
# either the Stop-block layer owns it, or this harness has no Task tool at all
# and the agent literally cannot comply (it happened ~10x/session before this).
# The cap re-arms whenever the list actually changes, so well-tooled sessions
# keep the full heartbeat.
sid8=$(basename "$state" | sed -e 's/^\.sync-//' -e 's/\.json$//' | cut -c1-8)
FIRES="/tmp/claude-heartbeat-fires-${sid8}"

if [ "${turns:-0}" -lt 2 ] || [ "${edits:-0}" -lt 2 ]; then
  [ -f "$FIRES" ] && echo 0 > "$FIRES" 2>/dev/null
  exit 0
fi

count=$(cat "$FIRES" 2>/dev/null || echo 0)
case "$count" in *[!0-9]*|"") count=0 ;; esac
[ "$count" -ge 2 ] && exit 0
echo $((count + 1)) > "$FIRES" 2>/dev/null || true
final=""
[ $((count + 1)) -ge 2 ] && final=" (Going quiet on this now — if this harness has no Task tool, keep todos in the session workspace doc instead.)"

printf '{"ts":"%s","sid":"-","event":"nudge:heartbeat turns=%s fire=%s"}\n' \
  "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$turns" "$((count + 1))" >> "$HOME/.claude/logs/sync-todos.log" 2>/dev/null || true
printf '[task-sync] Task list unchanged for %s turns while work continued — if the focus has moved, reconcile it now (TaskCreate/TaskUpdate); it auto-syncs to your notes + memory. Keeping it current silences this.%s\n' "$turns" "$final"
