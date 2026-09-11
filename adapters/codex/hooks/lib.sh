#!/usr/bin/env bash
# lib.sh — what every codex-side gcc hook needs before it can do anything.
#
# Codex hooks receive the same JSON on stdin that Claude Code hooks do
# (session_id, cwd, hook_event_name, tool_name, tool_input...), so most gcc
# scripts run unchanged. What differs is the ENVIRONMENT: codex inherits the
# parent shell's CLAUDE_CODE_SESSION_ID (the Claude session that launched it),
# so any gcc tool keyed on that variable would act as the parent. This file
# re-keys the environment to the codex session before anything else runs.
#
# Source it, then call gcc_read_input once. Never exit non-zero from here.

CODEX_GCC_ROOT="${CODEX_GCC_ROOT:-$HOME/.claude/adapters/codex}"
GCC_OUTBOX_DIR="${CODEX_GCC_OUTBOX:-/tmp/codex-gcc/outbox}"
IPC_REPO="${CLAUDE_IPC_REPO:-$HOME/Code/Claude/claude-ipc}"

# Read the hook payload once. Exports INPUT, SID, CWD, EVENT.
gcc_read_input() {
  INPUT=$(cat 2>/dev/null || printf '{}')
  [ -n "$INPUT" ] || INPUT='{}'
  SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
  CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
  EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)
  [ -n "$CWD" ] || CWD="$PWD"
  export INPUT SID CWD EVENT
}

# The alias a codex session answers to on claude-ipc: cx-<dir>-<id8>.
# Deterministic from cwd + session id so every hook and the gcc CLI agree
# without coordination. The cx- prefix is what tells a peer "this is codex".
gcc_alias() {
  local sid="${1:-$SID}" cwd="${2:-$CWD}" base tag
  base=$(basename "$cwd" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
  tag=$(printf '%s' "$sid" | tr -cd 'A-Za-z0-9' | tr '[:upper:]' '[:lower:]' | cut -c1-8)
  if [ -n "$base" ] && [ -n "$tag" ]; then printf 'cx-%s-%s' "$base" "$tag"
  elif [ -n "$tag" ]; then printf 'cx-%s' "$tag"
  else printf 'cx-session'; fi
}

# Re-key the environment to THIS codex session. Idempotent. The parent Claude
# session's id is kept under another name for the dispatch ledger.
gcc_export_env() {
  [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] && [ "${CLAUDE_CODE_SESSION_ID:-}" != "$SID" ] && export CLAUDE_CODE_SESSION_ID_PARENT="${CLAUDE_CODE_SESSION_ID_PARENT:-$CLAUDE_CODE_SESSION_ID}"
  [ -n "$SID" ] && export CLAUDE_CODE_SESSION_ID="$SID" GCC_CODEX_SID="$SID"
  export CLAUDE_IPC_ALIAS="$(gcc_alias)" CLAUDE_PROJECT_DIR="$CWD" GCC_HOST=codex
  # The parent Claude session's messaging socket must not be reachable through
  # a codex hook; a codex seat is not that session.
  unset CLAUDE_CODE_MESSAGING_SOCKET CLAUDE_CODE_MESSAGING_TOKEN 2>/dev/null || true
}

# Path of a compiled claude-ipc hook binary, or empty if the fabric is absent.
gcc_ipc_bin() {
  local b="$IPC_REPO/dist/$1"
  [ -x "$b" ] && printf '%s' "$b"
}

# Pull the additionalContext out of any hook-output JSON (either schema).
gcc_ctx_of() {
  printf '%s' "$1" | jq -r '(.hookSpecificOutput.additionalContext // .additionalContext // empty)' 2>/dev/null
}

# Emit one SessionStart/UserPromptSubmit-shaped context object, if text given.
gcc_emit_ctx() {
  local event="$1" text="$2"
  [ -n "$text" ] || return 0
  jq -cn --arg e "$event" --arg t "$text" '{hookSpecificOutput:{hookEventName:$e, additionalContext:$t}}'
}
