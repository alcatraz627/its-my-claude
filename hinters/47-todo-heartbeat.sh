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

# Fire once the list has lagged a couple of working turns. Much sooner than the
# Stop-block's hard threshold (8/5) — this is the frequent soft layer.
[ "${turns:-0}" -ge 2 ] && [ "${edits:-0}" -ge 2 ] || exit 0

printf '{"ts":"%s","sid":"-","event":"nudge:heartbeat turns=%s"}\n' \
  "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$turns" >> "$HOME/.claude/logs/sync-todos.log" 2>/dev/null || true
printf '[task-sync] Task list unchanged for %s turns while work continued — if the focus has moved, reconcile it now (TaskCreate/TaskUpdate); it auto-syncs to your notes + memory. Keeping it current silences this.\n' "$turns"
