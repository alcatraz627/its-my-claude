#!/usr/bin/env bash
# lock-file.sh <action> <filepath> [skill-name]
#
# Write-priority file-lock for Claude Code skill agents.
#
#   READS  are NEVER blocked — `read` always exits 0 immediately.
#   WRITES block other writes. If the file is already write-locked,
#          the script sleeps WAIT_SECONDS and retries up to MAX_RETRIES times.
#          On exhaustion it prints the lock owner and continuation instructions.
#
# Actions:
#   acquire <filepath> [skill-name]  — acquire write lock (retries on contention)
#   read    <filepath> [skill-name]  — declare read intent; always succeeds
#   release <filepath> [skill-name]  — release write lock
#   check   <filepath>               — print write lock status
#   cleanup                          — remove ALL stale locks (no filepath needed)
#
# Exit codes:
#   acquire → 0 acquired | 1 failed after all retries | 2 bad usage
#   read    → always 0
#   release → 0 released | 1 not found or wrong owner | 2 bad usage
#   check   → 0 free | 1 locked | 2 bad usage
#   cleanup → always 0 (reports what was cleared)

set -euo pipefail

ACTION="${1:-}"
FILE_PATH="${2:-}"
SKILL_NAME="${3:-unknown}"

LOCKS_DIR="$(dirname "$0")/locks"
STALE_SECONDS=300  # Locks older than 5 min are treated as stale and auto-cleared
WAIT_SECONDS=120   # Seconds to wait between write-lock retry attempts
MAX_RETRIES=5      # Number of retry attempts before giving up

if [[ -z "$ACTION" ]]; then
  echo "Usage: lock-file.sh <acquire|read|release|check|cleanup> <filepath> [skill-name]" >&2
  exit 2
fi

# cleanup doesn't need a filepath; all other actions do
if [[ "$ACTION" != "cleanup" && -z "$FILE_PATH" ]]; then
  echo "Usage: lock-file.sh <acquire|read|release|check> <filepath> [skill-name]" >&2
  exit 2
fi

# Sanitize the file path into a safe lock-directory name
SAFE_NAME="${FILE_PATH//\//_}"
SAFE_NAME="${SAFE_NAME//\./_}"
SAFE_NAME="${SAFE_NAME// /_}"
LOCK_DIR="$LOCKS_DIR/${SAFE_NAME}.lock"

mkdir -p "$LOCKS_DIR"

_read_lock_info() {
  if [[ -f "$LOCK_DIR/info" ]]; then
    cat "$LOCK_DIR/info"
  else
    echo "(unknown)"
  fi
}

_is_stale() {
  local lock_time now age
  lock_time="$(cat "$LOCK_DIR/timestamp" 2>/dev/null || echo 0)"
  now="$(date +%s)"
  age=$(( now - lock_time ))
  [[ $age -gt $STALE_SECONDS ]]
}

# Removes the lock dir if it exists and is stale. Returns 0 if cleared, 1 otherwise.
_clear_if_stale() {
  if [[ -d "$LOCK_DIR" ]] && _is_stale; then
    local owner
    owner="$(_read_lock_info)"
    echo "STALE_LOCK: '$FILE_PATH' was locked by [$owner] — removing stale lock." >&2
    rm -rf "$LOCK_DIR"
    return 0
  fi
  return 1
}

case "$ACTION" in

  # ── READ ────────────────────────────────────────────────────────────────────
  # Reads are never blocked by write locks. This action always succeeds.
  read)
    echo "READ_OK: '$FILE_PATH' — reads are never blocked."
    exit 0
    ;;

  # ── ACQUIRE (write lock with retry) ─────────────────────────────────────────
  acquire)
    attempt=0

    while [[ $attempt -le $MAX_RETRIES ]]; do
      # Auto-clear stale lock if present
      _clear_if_stale || true

      # Atomic mkdir — only one process can win this race
      if [[ ! -d "$LOCK_DIR" ]]; then
        if mkdir "$LOCK_DIR" 2>/dev/null; then
          echo "$SKILL_NAME | PID:$$ | $(date '+%Y-%m-%d %H:%M:%S')" > "$LOCK_DIR/info"
          date +%s > "$LOCK_DIR/timestamp"
          echo "ACQUIRED: write lock on '$FILE_PATH' by [$SKILL_NAME]"
          exit 0
        fi
        # Race: another process won mkdir simultaneously — fall through to retry
      fi

      # Active lock is held by another agent
      local_owner="$(_read_lock_info)"
      attempt=$(( attempt + 1 ))

      if [[ $attempt -gt $MAX_RETRIES ]]; then
        break
      fi

      echo "WAITING ($attempt/$MAX_RETRIES): '$FILE_PATH' is write-locked by [$local_owner]." >&2
      echo "  Retrying in ${WAIT_SECONDS}s ..." >&2
      sleep "$WAIT_SECONDS"
    done

    # ── All retries exhausted ─────────────────────────────────────────────────
    final_owner="$(_read_lock_info 2>/dev/null || echo "(unknown)")"
    total_wait=$(( MAX_RETRIES * WAIT_SECONDS ))

    echo "" >&2
    echo "FAILED: Could not acquire write lock on '$FILE_PATH'" >&2
    echo "        after $MAX_RETRIES attempt(s) (~${total_wait}s total wait)." >&2
    echo "" >&2
    echo "  Current lock owner: $final_owner" >&2
    echo "" >&2
    echo "  ── Continuation instructions ────────────────────────────────────" >&2
    echo "  The file may be in a partial or in-progress state." >&2
    echo "  To resume this task from another agent:" >&2
    echo "" >&2
    echo "  1. Check whether the lock is still active:" >&2
    echo "       bash .claude/skills/shared/lock-file.sh check \"$FILE_PATH\"" >&2
    echo "" >&2
    echo "  2. If the owning skill has finished, release its lock:" >&2
    echo "       bash .claude/skills/shared/lock-file.sh release \"$FILE_PATH\" \"$SKILL_NAME\"" >&2
    echo "" >&2
    echo "  3. Locks older than ${STALE_SECONDS}s are auto-cleared on the next acquire attempt." >&2
    echo "" >&2
    echo "  4. Re-acquire and resume:" >&2
    echo "       bash .claude/skills/shared/lock-file.sh acquire \"$FILE_PATH\" \"<your-skill>\"" >&2
    echo "" >&2
    echo "  5. Inspect '$FILE_PATH' for any partial output before overwriting." >&2
    echo "  ─────────────────────────────────────────────────────────────────" >&2
    exit 1
    ;;

  # ── RELEASE ─────────────────────────────────────────────────────────────────
  release)
    if [[ ! -d "$LOCK_DIR" ]]; then
      echo "NO_LOCK: no write lock found for '$FILE_PATH'" >&2
      exit 1
    fi

    current_owner="$(cat "$LOCK_DIR/info" 2>/dev/null | cut -d'|' -f1 | xargs)"
    if [[ "$current_owner" != "$SKILL_NAME" && "$SKILL_NAME" != "unknown" ]]; then
      echo "DENIED: lock on '$FILE_PATH' is owned by [$current_owner], not [$SKILL_NAME]" >&2
      exit 1
    fi

    rm -rf "$LOCK_DIR"
    echo "RELEASED: write lock on '$FILE_PATH' by [$SKILL_NAME]"
    exit 0
    ;;

  # ── CHECK ────────────────────────────────────────────────────────────────────
  check)
    if [[ ! -d "$LOCK_DIR" ]]; then
      echo "FREE: '$FILE_PATH' has no active write lock"
      exit 0
    fi

    if _is_stale; then
      stale_owner="$(_read_lock_info)"
      echo "FREE (stale): '$FILE_PATH' lock has expired — auto-clears on next acquire"
      echo "  Stale owner: $stale_owner"
      exit 0
    fi

    active_owner="$(_read_lock_info)"
    echo "LOCKED: '$FILE_PATH' has an active write lock"
    echo "  Owner: $active_owner"
    exit 1
    ;;

  # ── CLEANUP (sweep all stale locks) ──────────────────────────────────────────
  cleanup)
    cleared=0
    if [[ -d "$LOCKS_DIR" ]]; then
      for lock_dir in "$LOCKS_DIR"/*.lock; do
        [[ -d "$lock_dir" ]] || continue
        lock_time="$(cat "$lock_dir/timestamp" 2>/dev/null || echo 0)"
        now="$(date +%s)"
        age=$(( now - lock_time ))
        if [[ $age -gt $STALE_SECONDS ]]; then
          owner="$(cat "$lock_dir/info" 2>/dev/null || echo "(unknown)")"
          lock_name="$(basename "$lock_dir" .lock)"
          echo "CLEARED: stale lock '$lock_name' (age: ${age}s, owner: $owner)"
          rm -rf "$lock_dir"
          cleared=$(( cleared + 1 ))
        fi
      done
    fi
    if [[ $cleared -eq 0 ]]; then
      echo "CLEAN: no stale locks found"
    else
      echo "CLEANUP_DONE: cleared $cleared stale lock(s)"
    fi
    exit 0
    ;;

  *)
    echo "Unknown action '$ACTION'. Use: acquire | read | release | check | cleanup" >&2
    exit 2
    ;;
esac
