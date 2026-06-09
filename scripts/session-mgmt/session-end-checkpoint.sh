#!/usr/bin/env bash
# Leaves a resumable checkpoint when a session ends without a /core-dump.
#
# Many sessions just exit or /clear without the agent running /core-dump, so the
# only durable trace is whatever landed in WAL/workspace mid-flight. This hook
# closes that gap: on SessionEnd it produces the same shell-only structural
# snapshot the PreCompact hook does, so a later /catchup (or retro-dump) always
# has an artifact to resume from.
#
# Runtime contract: reads the SessionEnd payload on stdin
# ({session_id, cwd, reason, ...}), re-shapes it into the {trigger, cwd,
# session_id} shape pre-compact-checkpoint.sh consumes, and delegates — reusing
# all of that script's gathering logic instead of duplicating it. The checkpoint
# writer's 30-min smart-skip guard prevents this from shadowing a fresh
# /core-dump. Always exits 0; a checkpoint failure must never block shutdown.

set -uo pipefail

input=$(cat 2>/dev/null) || input='{}'
command -v jq >/dev/null 2>&1 || exit 0

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
reason=$(printf '%s' "$input" | jq -r '.reason // "session-end"')

# `clear` and normal exits are exactly when an unsaved session would lose state.
# `prompt_input_exit` (ctrl-c at an empty prompt) is a no-work bail — skip it to
# avoid churning a checkpoint for a session that did nothing.
[[ "$reason" == "prompt_input_exit" ]] && exit 0

jq -nc --arg cwd "$cwd" --arg sid "$session_id" \
    '{trigger:"session-end", cwd:$cwd, session_id:$sid}' \
  | PRECOMPACT_KIND_OVERRIDE="session-end" \
    bash "$HOME/.claude/scripts/session-mgmt/pre-compact-checkpoint.sh" >/dev/null 2>&1 || true

exit 0
