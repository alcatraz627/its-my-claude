#!/usr/bin/env bash
# post-clear-counter-reset.sh — SessionStart injector, side-effect only, source=="clear".
#
# What it fixes, in human terms: after a /clear the counters that drive the
# auto-checkpoint "tool count N", the ctx-pressure "% full", and the
# todo-discipline "N edits" nudges keep their PRE-clear values, so a brand-new
# session gets nagged as if it were 800 tools deep. Those counters are keyed by
# the Claude process id, and /clear does not restart the process — so the /tmp
# files persist.
#
# This injector cannot reset them directly: it runs under the SessionStart
# orchestrator, so its own $PPID is the orchestrator's, not the Claude process
# the counters are keyed to. Instead it drops a session-keyed sentinel; the
# reader hooks (tool-counter.sh, ctx-pressure-nudge.sh), which DO run with the
# right PPID, call hook_clear_reset() and drop their stale counter on the first
# tool call after the clear. See scripts/hooks/hook-common.sh:hook_clear_reset.
#
# Why the sync inject lane and not the async orchestrator: the sentinel must
# exist BEFORE the first PostToolUse, and only the synchronous lane guarantees
# that ordering. It is side-effect only (writes the sentinel, prints nothing).
#
# Runtime contract: reads the SessionStart payload on stdin, exits 0 always.
# Mute: touch ~/.claude/.no-clear-counter-reset (machine-wide).

set -uo pipefail
[ -f "$HOME/.claude/.no-clear-counter-reset" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null || echo '{}')
src=$(printf '%s' "$INPUT" | jq -r '.source // empty' 2>/dev/null)
[ "$src" = "clear" ] || exit 0

sid=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
sid8="${sid:0:8}"; [ -n "$sid8" ] || sid8="nosid"

# Touch the sentinel (create or bump mtime to now). Readers reset a counter whose
# mtime predates this. Prints nothing — pure side effect.
: > "/tmp/claude-clear-reset-${sid8}" 2>/dev/null || true
exit 0
