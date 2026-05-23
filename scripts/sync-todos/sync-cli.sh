#!/usr/bin/env bash
# Operator commands for sync-todos. Invoked by user via /sync or directly.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

CMD="${1:-status}"

case "$CMD" in
  status)
    echo "── sync-todos status ──"
    if sync_is_disabled; then
      echo "  state:        DISABLED (run: $0 enable)"
    else
      echo "  state:        enabled"
    fi
    if [ -e "$SYNC_LOCK" ]; then
      echo "  lock:         held by pid $(cat "$SYNC_LOCK" 2>/dev/null)"
    else
      echo "  lock:         free"
    fi
    SID=$(sync_session_id "")
    [ -n "$SID" ] && echo "  session_id:   $SID" || echo "  session_id:   (unknown)"
    if [ -n "$SID" ]; then
      PENDING=$(sync_pending_path "$SID")
      if [ -f "$PENDING" ]; then
        COUNT=$(jq -r '.unchecked_todos | length' "$PENDING" 2>/dev/null)
        WRITTEN=$(jq -r '.written_at' "$PENDING" 2>/dev/null)
        echo "  pending file: $PENDING"
        echo "                $COUNT unchecked todos, written $WRITTEN"
      else
        echo "  pending file: (none)"
      fi
    fi
    echo "  WAL:          $SYNC_WAL"
    ORPHANS=$(bash "$SCRIPT_DIR/wal.sh" orphans 2>/dev/null)
    if [ -n "$ORPHANS" ]; then
      echo "  WAL orphans:"
      echo "$ORPHANS" | sed 's/^/    /'
    else
      echo "  WAL orphans:  (none)"
    fi
    ;;
  reset)
    echo "Resetting sync state..."
    rm -f "$SYNC_LOCK" 2>/dev/null && echo "  ✓ lock cleared"
    # Clear pending files for all sessions
    rm -f /tmp/claude-todo-pending-*.json 2>/dev/null && echo "  ✓ pending files cleared"
    # Truncate WAL (keep file, drop entries)
    : > "$SYNC_WAL" 2>/dev/null && echo "  ✓ WAL cleared"
    echo "Next SessionStart or prompt will re-pull from workspace."
    ;;
  disable)
    touch "$SYNC_DISABLED_MARKER"
    echo "✓ sync disabled (marker: $SYNC_DISABLED_MARKER)"
    echo "  Hooks will skip silently. Run: $0 enable to re-enable."
    ;;
  enable)
    rm -f "$SYNC_DISABLED_MARKER" && echo "✓ sync enabled"
    ;;
  *)
    cat <<EOF
usage: $0 <status|reset|disable|enable>

  status   show lock, pending file, WAL orphans
  reset    clear lock + pending files + WAL (force re-pull)
  disable  pause hooks (touch a marker file)
  enable   resume hooks
EOF
    exit 2
    ;;
esac
