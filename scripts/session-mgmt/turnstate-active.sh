#!/usr/bin/env bash
# turnstate-active.sh — is a session GENUINELY mid-turn right now?
#
# A turn-state sentinel (~/.claude/.turn-state/<sid>.json) is written at turn
# start and removed by the Stop hook at turn end. Every abnormal exit skips Stop
# and orphans the sentinel, so bare existence ("[ -f sentinel ]") reads a session
# that died mid-turn as busy forever. That is the defect that wedged the warden
# for 10 days on one orphan.
#
# The fix is freshness, not existence. A real live turn touched its sentinel
# within the last few minutes; an orphan's mtime is hours or days old. This is
# the single shared answer to "mid-turn?" so the warden beat, ward-revive, and
# any future watcher stop each inventing their own staleness rule (lifecycle
# audit Case B).
#
# Usage:  turnstate-active.sh <session-id> [--ttl-min N]
#   exit 0  the session is genuinely mid-turn (sentinel fresh within TTL)
#   exit 1  not mid-turn (no sentinel, or the sentinel is stale debris)
# Default TTL 30m: a turn rarely runs longer, and the warden invoke cap is 20m.

set -uo pipefail

SID="${1:-}"
TTL_MIN=30
shift 2>/dev/null || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ttl-min) TTL_MIN="${2:-30}"; shift ;;
  esac
  shift
done

[ -n "$SID" ] || exit 1
SENTINEL="${WARDEN_TURNSTATE_DIR:-$HOME/.claude/.turn-state}/${SID}.json"
[ -f "$SENTINEL" ] || exit 1

# Fresh within the TTL window → genuinely mid-turn. `find -mmin -N` is true when
# the file was modified less than N minutes ago.
if [ -n "$(find "$SENTINEL" -mmin "-${TTL_MIN}" 2>/dev/null)" ]; then
  exit 0
fi
exit 1
