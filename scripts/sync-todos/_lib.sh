#!/usr/bin/env bash
# Shared helpers for sync-todos Phase 1.

set -uo pipefail

SYNC_DIR="$HOME/.claude"
SYNC_LOCK="$SYNC_DIR/sync.lock"
SYNC_WAL="$SYNC_DIR/sync-wal.jsonl"
SYNC_DISABLED_MARKER="$SYNC_DIR/sync-disabled"
SESSION_ID_FILE="$SYNC_DIR/.current-session-id"

# Read session id from stdin JSON, env, or fallback file.
sync_session_id() {
  local sid=""
  if [ -n "${1:-}" ]; then
    sid=$(echo "$1" | jq -r '.session_id // ""' 2>/dev/null)
  fi
  [ -z "$sid" ] && sid="${CLAUDE_SESSION_ID:-}"
  [ -z "$sid" ] && [ -f "$SESSION_ID_FILE" ] && sid=$(cat "$SESSION_ID_FILE" 2>/dev/null)
  printf '%s' "$sid"
}

# Resolve workspace _active.md path for a given project CWD.
# Mirrors the edge-case in scripts/session-notes/create.sh: PROJECT=~/.claude
# uses session-notes/ at the same level, not nested under .claude/.
sync_workspace_path() {
  local cwd="$1"
  [ -z "$cwd" ] && return 1
  if [ "$cwd" = "$HOME/.claude" ] || [[ "$cwd" == */.claude ]]; then
    printf '%s/session-notes/_active.md' "$cwd"
  else
    printf '%s/.claude/session-notes/_active.md' "$cwd"
  fi
}

# Pending-todos file path for a session.
sync_pending_path() {
  local sid="$1"
  local clean=$(printf '%s' "$sid" | tr -c 'A-Za-z0-9_-' '_')
  printf '/tmp/claude-todo-pending-%s.json' "$clean"
}

# Content hash of a workspace section (or whole file). Quiet on missing.
sync_content_hash() {
  local f="$1"
  [ -f "$f" ] || { printf 'absent'; return; }
  shasum -a 256 "$f" 2>/dev/null | awk '{print $1}'
}

# Acquire the global sync lock (blocks up to 5s). Sets SYNC_LOCK_HELD on success.
sync_acquire_lock() {
  local waited=0
  while [ -e "$SYNC_LOCK" ] && [ "$waited" -lt 50 ]; do
    sleep 0.1
    waited=$((waited + 1))
  done
  [ -e "$SYNC_LOCK" ] && return 1
  echo "$$" > "$SYNC_LOCK"
  SYNC_LOCK_HELD=1
}

sync_release_lock() {
  if [ "${SYNC_LOCK_HELD:-0}" = "1" ]; then
    rm -f "$SYNC_LOCK"
    SYNC_LOCK_HELD=0
  fi
}

# Returns 0 (true) if user has disabled sync via /sync disable.
sync_is_disabled() {
  [ -f "$SYNC_DISABLED_MARKER" ]
}
