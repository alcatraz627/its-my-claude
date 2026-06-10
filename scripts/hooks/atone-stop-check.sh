#!/usr/bin/env bash
# atone-stop-check.sh — Stop hook handler.
#
# Fires after the assistant response completes (before user's next prompt).
# Checks the per-session .pending-atone marker (written by 30-atone-nudge.sh
# when a correction signal was detected on the prior user prompt).
#
# Logic:
#   - If events.jsonl gained a new entry timestamped AFTER the marker.ts →
#     clear the marker (loop closed cleanly — agent invoked /atone).
#   - Otherwise increment turns_unaddressed in the marker (it ages).
#
# The escalation behavior lives in 30-atone-nudge.sh (which reads the marker
# on next UserPromptSubmit and emits progressively stronger nudges). This
# script ONLY updates the marker — it doesn't print anything to the user.
#
# Stop hook exit codes don't affect anything visible; we always exit 0.

set -uo pipefail

INPUT=$(cat 2>/dev/null || echo "{}")
command -v jq >/dev/null 2>&1 || exit 0

# Resolve session marker
SESSION_KEY="${CLAUDE_SESSION_ID:-$(date +%Y-%m-%d)}"
STATE_DIR="$HOME/.claude/atone/.session-state"
MARKER="$STATE_DIR/$SESSION_KEY.pending-atone"

[ -f "$MARKER" ] || exit 0  # nothing pending → nothing to do

# Explicit /atone markers (explicit:true) are owned by the BLOCKING gate
# (scripts/hooks/atone-stop-gate.sh, a direct settings.json Stop entry whose
# stdout can carry a decision:block). This hook runs inside the orchestrator,
# whose task stdout is /dev/null'd, so it can only nudge — never enforce. Leave
# explicit markers to the gate so the two don't both age/clear the same file.
if [ "$(jq -r '.explicit // false' "$MARKER" 2>/dev/null)" = "true" ]; then
  exit 0
fi

# Read the marker
MARKER_TS=$(jq -r '.ts // empty' "$MARKER" 2>/dev/null)
MARKER_TURNS=$(jq -r '.turns_unaddressed // 0' "$MARKER" 2>/dev/null)
[ -z "$MARKER_TS" ] && exit 0  # malformed marker — silently bail

# Check events.jsonl for any event timestamped after the marker
EVENTS="$HOME/.claude/atone/events.jsonl"
if [ -f "$EVENTS" ]; then
  # `>=` not `>` — marker.ts and event.ts both floor to second precision,
  # so a same-second match means the event was written AFTER the marker
  # (marker is created at UserPromptSubmit; events come from the agent's
  # response, which is necessarily later in wall-clock terms).
  RECENT_EVENT=$(jq -r --arg ts "$MARKER_TS" '
    select(.ts >= $ts) | .id
  ' "$EVENTS" 2>/dev/null | head -1)

  if [ -n "$RECENT_EVENT" ]; then
    # Loop closed cleanly — clear the marker
    rm -f "$MARKER" 2>/dev/null || true

    # Optional: log a `fired-and-useful` feedback (the nudge worked)
    # Skip if AFFIRM_NO_FEEDBACK env is set.
    if [ "${ATONE_NO_FEEDBACK:-0}" != "1" ]; then
      ( bash "$HOME/.claude/scripts/atone.sh" feedback \
          --kind fired-and-useful \
          --slug nudge-marker-resolved \
          --event-id "$RECENT_EVENT" \
          --notes "atone-stop-check: nudge marker cleared by event $RECENT_EVENT" \
          >/dev/null 2>&1 & ) &
    fi

    exit 0
  fi
fi

# Marker is stale — agent didn't /atone this turn. Increment counter.
NEW_TURNS=$((MARKER_TURNS + 1))

# Decay: if turns_unaddressed >= 3, auto-clear with a `missed` feedback event
# so the system stops nagging on the same correction indefinitely.
if [ "$NEW_TURNS" -ge 3 ]; then
  # Log the miss
  if [ "${ATONE_NO_FEEDBACK:-0}" != "1" ]; then
    SNIPPET=$(jq -r '.correction_snippet // ""' "$MARKER" 2>/dev/null | head -c 200)
    ( bash "$HOME/.claude/scripts/atone.sh" feedback \
        --kind missed \
        --slug unaddressed-correction \
        --notes "atone-stop-check: marker auto-cleared after 3 turns unaddressed. snippet=${SNIPPET}" \
        >/dev/null 2>&1 & ) &
  fi
  rm -f "$MARKER" 2>/dev/null || true
  exit 0
fi

# Otherwise: update the marker with incremented counter
TMP="$MARKER.tmp"
jq --argjson n "$NEW_TURNS" '.turns_unaddressed = $n' "$MARKER" > "$TMP" 2>/dev/null && mv "$TMP" "$MARKER"

exit 0
