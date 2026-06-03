#!/usr/bin/env bash
# Stop hook: keep the workspace notes in step with the live Task list, and — only
# when the list has clearly gone stale — make the agent stop and reconcile it.
#
# Two jobs, in order:
#   1. Mechanical mirror (always, silent): project the live Task list into the
#      project's _active.md + memory pointer via writeback.sh. This half is not
#      advisory — it just happens.
#   2. Liveness nudge (rare, loud): if the session has more than a couple of
#      tasks AND the list hasn't moved for a stretch of turns during which real
#      work (edits / commits) happened, refuse to end the turn once and ask the
#      agent to reconcile — mark done, add new, reprioritise. A second stop is
#      always allowed (the stop_hook_active escape), so this can never trap a
#      turn in a loop; a leftover soft reminder is dropped for the next prompt.
#
# Trivial sessions (<=2 tasks) are never blocked. The session id comes from the
# event stdin only — never the global ~/.claude/.current-session-id slot, which
# the most recent session clobbers.
#
# Output: nothing (normal stop) unless it decides to block, in which case a
# single {"decision":"block","reason":...} JSON line goes to stdout. Must be a
# DIRECT settings.json Stop hook — the orchestrator discards Stop stdout.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

# One compact line per run so a no-op is visible instead of silent — this is a
# direct (non-orchestrated) hook, so nothing else logs its outcome.
SYNC_LOG="$HOME/.claude/logs/sync-todos.log"
slog() {
  mkdir -p "$HOME/.claude/logs" 2>/dev/null
  printf '{"ts":"%s","sid":"%s","event":"%s"}\n' \
    "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "${SID:-?}" "$1" >> "$SYNC_LOG" 2>/dev/null || true
}

# Thresholds (env-overridable for tests).
MIN_TASKS="${SYNC_DRIFT_MIN_TASKS:-2}"      # block only when task count is > this
TURNS="${SYNC_DRIFT_TURNS:-8}"              # ...and the list is unchanged this many turns
EDITS="${SYNC_DRIFT_EDITS:-5}"             # ...and at least this many edits happened meanwhile

input=$(cat 2>/dev/null || echo "")
[ -z "$input" ] && exit 0
sync_is_disabled && exit 0

SID=$(printf '%s' "$input" | jq -r '.session_id // ""' 2>/dev/null)
[ -z "$SID" ] && exit 0
CWD=$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null)
STOP_ACTIVE=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)
TX=$(printf '%s' "$input" | jq -r '.transcript_path // ""' 2>/dev/null)

TASK_DIR="$HOME/.claude/tasks/$SID"
STATE="$HOME/.claude/tasks/.sync-${SID}.json"
CLEAN=$(printf '%s' "$SID" | tr -c 'A-Za-z0-9_-' '_')

# Reconstruct the current task list ONCE — from the durable transcript when
# available, else the volatile task dir — and share it with both the mirror and
# the drift check, so the O(file-size) replay runs a single time per turn.
if [ -n "$TX" ] && [ -f "$TX" ]; then
  TASKS_JSON=$(python3 "$SCRIPT_DIR/replay_tasks.py" "$TX" 2>/dev/null || echo '[]')
elif [ -d "$TASK_DIR" ]; then
  TASKS_JSON=$(python3 - "$TASK_DIR" <<'PY' 2>/dev/null || echo '[]'
import sys, os, json, glob
out = []
for fn in glob.glob(os.path.join(sys.argv[1], "*.json")):
    try:
        o = json.load(open(fn))
    except Exception:
        continue
    if o.get("id") and o.get("subject"):
        out.append({"id": str(o["id"]), "subject": o["subject"], "status": o.get("status", "pending")})
print(json.dumps(out))
PY
)
else
  TASKS_JSON="[]"
fi

# An empty list from a clearly-non-empty transcript means the replay/parse broke,
# not that there's genuinely no work — flag it instead of silently mirroring [].
if [ "$TASKS_JSON" = "[]" ] && [ -n "$TX" ] && [ -f "$TX" ] \
   && [ "$(wc -c < "$TX" 2>/dev/null || echo 0)" -gt 5000 ]; then
  slog "warn:empty-replay-on-nonempty-transcript"
fi

# --- Job 1: mechanical mirror (always, silent) — reuses the list above ------
SHARED="/tmp/claude-tasks-${CLEAN}.json"
printf '%s' "$TASKS_JSON" > "$SHARED" 2>/dev/null
printf '%s' "$input" | SYNC_TASKS_FILE="$SHARED" bash "$SCRIPT_DIR/writeback.sh" >/dev/null 2>&1 || true
rm -f "$SHARED" 2>/dev/null

# --- Job 2: drift detection ------------------------------------------------

# Fingerprint (id:status:subject, sorted) + count. Hash changes whenever the
# list moves, which is what "the agent kept it fresh" means.
TASK_COUNT=$(printf '%s' "$TASKS_JSON" | jq 'length' 2>/dev/null || echo 0)
TASK_HASH=$(printf '%s' "$TASKS_JSON" | jq -r '[.[]|"\(.id):\(.status):\(.subject)"]|sort|join("\n")' 2>/dev/null | shasum -a 256 2>/dev/null | cut -c1-16)
[ -z "${TASK_HASH:-}" ] && TASK_HASH="none"

# Edits since the last stop: count Edit/Write/NotebookEdit tool calls and git
# commits in the slice of transcript written since we last looked.
NEW_EDITS=0
TX_SIZE=0
if [ -n "$TX" ] && [ -f "$TX" ]; then
  TX_SIZE=$(wc -c < "$TX" 2>/dev/null | tr -d ' ' || echo 0)
  PREV_SIZE=$(jq -r '.last_tx_size // 0' "$STATE" 2>/dev/null || echo 0)
  if [ "$TX_SIZE" -gt "$PREV_SIZE" ] 2>/dev/null; then
    SLICE=$(tail -c +"$((PREV_SIZE + 1))" "$TX" 2>/dev/null)
    # Count real file-edit tool calls only. (Dropped a literal "git commit"
    # match — it also hit the string in prose / quoted commands, inflating the
    # count; actual edits already imply the work that matters here.)
    NEW_EDITS=$(printf '%s' "$SLICE" | rg -c '"name":"(Edit|Write|NotebookEdit|MultiEdit)"' 2>/dev/null || echo 0)
  fi
fi

PREV_HASH=$(jq -r '.last_task_hash // ""' "$STATE" 2>/dev/null || echo "")
TURNS_SINCE=$(jq -r '.turns_since_change // 0' "$STATE" 2>/dev/null || echo 0)
EDITS_SINCE=$(jq -r '.edits_since_change // 0' "$STATE" 2>/dev/null || echo 0)

if [ "$TASK_HASH" != "$PREV_HASH" ]; then
  # The list moved → it's fresh. Reset the staleness window.
  TURNS_SINCE=0; EDITS_SINCE=0
else
  TURNS_SINCE=$((TURNS_SINCE + 1))
  EDITS_SINCE=$((EDITS_SINCE + NEW_EDITS))
fi

write_state() {
  jq -cn --arg h "$TASK_HASH" --argjson t "$1" --argjson e "$2" --argjson s "${TX_SIZE:-0}" \
    '{last_task_hash:$h, turns_since_change:$t, edits_since_change:$e, last_tx_size:$s}' \
    > "$STATE.tmp" 2>/dev/null && mv -f "$STATE.tmp" "$STATE" 2>/dev/null || true
}

STALE=0
if [ "$TASK_COUNT" -gt "$MIN_TASKS" ] && [ "$TURNS_SINCE" -ge "$TURNS" ] && [ "$EDITS_SINCE" -ge "$EDITS" ]; then
  STALE=1
fi

slog "run count=$TASK_COUNT turns=$TURNS_SINCE edits=$EDITS_SINCE stale=$STALE active=$STOP_ACTIVE"

if [ "$STALE" != 1 ]; then
  write_state "$TURNS_SINCE" "$EDITS_SINCE"
  exit 0
fi

# Stale. Build a short reconcile instruction with a live snapshot.
SUMMARY=$(printf '%s' "$TASKS_JSON" | jq -r '
  ([.[] | select(.status=="in_progress")]) as $ip
  | "\($ip|length) in-progress, \([.[]|select(.status=="pending")]|length) pending, \([.[]|select(.status=="completed")]|length) done"
    + (if ($ip|length) > 0 then " | active: " + ([$ip[].subject] | .[0:3] | join("; ")) else "" end)
' 2>/dev/null || echo "")

REASON="Your task list hasn't changed in ${TURNS_SINCE} turns but ~${EDITS_SINCE} edits happened — it's drifted from what you're actually doing. Before stopping, reconcile it with TaskUpdate/TaskCreate: mark finished work completed, add anything new you took on, and set the right task in_progress. Current: ${SUMMARY}. (This check only fires above a few tasks; update the list and it won't fire again.)"

if [ "$STOP_ACTIVE" = "true" ]; then
  # Already blocked once this stop-cycle — don't block again (escape the loop).
  # Leave a soft reminder for the next prompt instead, and reset the window so
  # we don't immediately re-trip.
  CLEAN=$(printf '%s' "$SID" | tr -c 'A-Za-z0-9_-' '_')
  jq -cn --arg r "$REASON" '{reason:$r}' > "/tmp/claude-todo-drift-${CLEAN}.json" 2>/dev/null || true
  write_state 0 0
  exit 0
fi

# First stale stop → block once and ask for reconciliation. Reset the window so
# the next nudge is another full stretch away, not every turn.
write_state 0 0
jq -cn --arg r "$REASON" '{decision:"block", reason:$r}' 2>/dev/null || true
exit 0
