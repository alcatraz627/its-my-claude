#!/usr/bin/env bash
# turn-end-cleanup.sh — Stop hook. Clears the in-progress turn-state file for
# this session so a graceful exit is NOT reported as "incomplete turn" by the
# stale-session detector on next launch.
#
# Hook input (stdin): {session_id, ...}
#
# Only removes the sid-specific state file. The counter is left intact (used for
# session-total turn count stats). The detect-stale-session.sh hook only checks
# the presence of the .json file, not the counter.

set -uo pipefail

STATE_DIR="$HOME/.claude/.turn-state"
[ -d "$STATE_DIR" ] || exit 0

INPUT=$(cat 2>/dev/null || echo "{}")
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || echo "")
[ -z "$SESSION_ID" ] && exit 0

SAFE_SID=$(printf '%s' "$SESSION_ID" | tr -c 'a-zA-Z0-9_-' '_' | head -c 120)
[ -z "$SAFE_SID" ] && exit 0

rm -f "$STATE_DIR/$SAFE_SID.json" 2>/dev/null || true
# Also drop the heartbeat counter — it's session-scoped and loses meaning
# across session boundaries. Turn counter is preserved for stats.
rm -f "$STATE_DIR/heartbeat-$SAFE_SID" 2>/dev/null || true
exit 0
