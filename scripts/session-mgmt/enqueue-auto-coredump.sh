#!/usr/bin/env bash
# Queues a real (LLM-synthesized) /core-dump for this session to run later.
#
# The shell checkpoint (PreCompact/SessionEnd) captures structure but not the
# *reasoning* of a session — that needs an LLM reading the transcript. Running
# that inline would block the hot path and cost money every compaction, so this
# instead drops the session's UUID into retro-dump's queue; the out-of-band
# `retro-dump.sh --queue` processor turns it into a /core-dump mini, cost-capped.
#
# OPT-IN. Does nothing unless ~/.claude/.auto-coredump-enabled exists, so it
# never spends tokens behind the user's back. Also requires the session to have
# done real work (>= AUTO_COREDUMP_MIN_TOOLS tool calls) so trivial sessions
# don't get queued.
#
# Runtime contract: PreCompact/SessionEnd hook. Reads the payload on stdin
# (needs .session_id = the resumable transcript UUID). Always exits 0.

set -uo pipefail

GATE="$HOME/.claude/.auto-coredump-enabled"
[[ -f "$GATE" ]] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null) || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[[ -z "$sid" ]] && exit 0

# Only queue sessions that did meaningful work.
tool_total=0
TOOL_FILE="/tmp/claude-tools-${PPID}"
[[ -f "$TOOL_FILE" ]] && tool_total=$(grep '^_total=' "$TOOL_FILE" 2>/dev/null | cut -d= -f2)
tool_total=${tool_total:-0}
MIN_TOOLS="${AUTO_COREDUMP_MIN_TOOLS:-15}"
(( tool_total < MIN_TOOLS )) && exit 0

QUEUE_DIR="$HOME/.claude/checkpoints/retro-queue"
mkdir -p "$QUEUE_DIR"
# touch is idempotent — re-queuing the same session before it's processed is a
# no-op, so PreCompact + SessionEnd both firing for one session is harmless.
touch "$QUEUE_DIR/${sid}.queued" 2>/dev/null || true

exit 0
