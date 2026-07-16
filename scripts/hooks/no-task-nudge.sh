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
# not surfaced). PostToolUse additionalContext IS the channel that lands — but ONLY
# inside the documented {hookSpecificOutput:{hookEventName,additionalContext}}
# envelope. This hook emitted a BARE top-level {additionalContext} until 2026-07-13,
# which the harness does not read: it never reached a single agent, and there is no
# error or --debug signal when that happens. See assets/reports/20260713-hook-envelope/.
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

# After a /clear this hook cannot see the task list at all, so it must not talk.
#
# /clear rotates the session id we are handed but does not restart the Claude
# process, and the Task store stays keyed to the PRE-clear id. Nothing here can
# recover that id: the store's .lock is empty, there is no process-to-store index,
# and picking the newest task dir would read a sibling session's list — the exact
# cross-session collision removed from the atone fleet in 3432587. So the lookup
# below returns "no tasks" for a session that may have a full list, which is how
# this hook came to tell a session with 20 open tasks that its list was empty.
#
# A blind check has nothing to say. Staying silent costs a post-/clear session our
# advisory; the harness's own todo reminder still fires there, and it reads the
# list correctly. Sentinel written by the source==clear SessionStart injector,
# scripts/session-mgmt/post-clear-counter-reset.sh.
[[ -f "/tmp/claude-clear-reset-${sid:0:8}" ]] && exit 0

# Substantial editing? Reuse tool-counter's per-process tallies (E=Edit, W=Write).
# If that file isn't there yet, there's been no meaningful work — nothing to nudge.
CF="/tmp/claude-tools-${PPID}"
[[ -f "$CF" ]] || exit 0
e=$(grep '^E=' "$CF" 2>/dev/null | cut -d= -f2); e=${e:-0}
w=$(grep '^W=' "$CF" 2>/dev/null | cut -d= -f2); w=${w:-0}
edits=$(( e + w ))
MIN_EDITS="${NOTASK_MIN_EDITS:-10}"
(( edits < MIN_EDITS )) && exit 0

# Zero tasks for this session? One <N>.json per task under the session's task dir.
# The store names that dir session-<first-8-of-sid>; it used to be the bare session
# id, and this hook was still looking for the bare id long after the store moved on.
# The count therefore came back 0 for every session, so the "they already have a
# list" exit below never fired and the nudge went to diligent sessions too. Check
# the current shape first, then the legacy one (a handful of pre-2026-07 dirs).
TASK_DIR="$HOME/.claude/tasks/session-${sid:0:8}"
[[ -d "$TASK_DIR" ]] || TASK_DIR="$HOME/.claude/tasks/$sid"

# Ask ".highwatermark" — how many tasks this session EVER had — before counting
# files. The store reaps a task's json once it completes, so a session that made a
# list and finished it ends with zero *.json and only .highwatermark left. Counting
# files alone would nag precisely the session that did everything right.
hw=0
[[ -f "$TASK_DIR/.highwatermark" ]] && hw=$(tr -dc '0-9' < "$TASK_DIR/.highwatermark" 2>/dev/null)
(( ${hw:-0} > 0 )) && exit 0

task_count=0
[[ -d "$TASK_DIR" ]] && task_count=$(ls "$TASK_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
(( task_count > 0 )) && exit 0

touch "$SENT" 2>/dev/null || true
jq -nc --arg m "[todo-discipline] ${edits} edits so far but your Task list is empty. Live todos belong in the Task tool (TaskCreate/TaskUpdate) — that's the source of truth, what the TUI shows, and what sync-todos mirrors to notes/memory. If this is multi-step work, create tasks now; a plan in a doc file with an empty Task list leaves the TUI blind. (Advisory; fires once per session.)" \
  '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook no-task-nudge --action nudge --heeded unknown >/dev/null 2>&1 || true

exit 0
