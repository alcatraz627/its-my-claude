#!/usr/bin/env bash
# Catches the "worked all session, never used the Task tool" failure mode.
#
# Migration 0017 made the Task tool the todo source of truth, but an agent that
# manages todos in a project file (docs/TODO.md, plan.md) leaves the live list —
# and therefore the TUI and every downstream mirror — empty. This PostToolUse
# hook notices that: once per session, when real editing work has piled up but
# the Task list is still empty, it nudges the agent toward the Task tool.
#
# Advisory only — emits additionalContext (which reaches the agent mid-session),
# never blocks. The user chose non-blocking deliberately; a Stop-time block was
# rejected, and a Stop-time advisory would be swallowed (Stop non-block output is
# not surfaced). PostToolUse additionalContext is the channel that actually lands.
#
# Runtime contract: reads the PostToolUse payload on stdin (needs .session_id).
# Fires at most once per session (sentinel in /tmp). Always exits 0.

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[[ -z "$sid" ]] && exit 0

SENT="/tmp/claude-notask-nudged-${sid:0:8}"
[[ -f "$SENT" ]] && exit 0

# Substantial editing? Reuse tool-counter's per-process tallies (E=Edit, W=Write).
# If that file isn't there yet, there's been no meaningful work — nothing to nudge.
CF="/tmp/claude-tools-${PPID}"
[[ -f "$CF" ]] || exit 0
e=$(grep '^E=' "$CF" 2>/dev/null | cut -d= -f2); e=${e:-0}
w=$(grep '^W=' "$CF" 2>/dev/null | cut -d= -f2); w=${w:-0}
edits=$(( e + w ))
MIN_EDITS="${NOTASK_MIN_EDITS:-10}"
(( edits < MIN_EDITS )) && exit 0

# Zero tasks for this session? One <N>.json per task under ~/.claude/tasks/<sid>/.
TASK_DIR="$HOME/.claude/tasks/$sid"
task_count=0
[[ -d "$TASK_DIR" ]] && task_count=$(ls "$TASK_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
(( task_count > 0 )) && exit 0

touch "$SENT" 2>/dev/null || true
jq -nc --arg m "[todo-discipline] ${edits} edits so far but your Task list is empty. Live todos belong in the Task tool (TaskCreate/TaskUpdate) — that's the source of truth, what the TUI shows, and what sync-todos mirrors to notes/memory. If this is multi-step work, create tasks now; a plan in a doc file with an empty Task list leaves the TUI blind. (Advisory; fires once per session.)" \
  '{additionalContext:$m}'

exit 0
