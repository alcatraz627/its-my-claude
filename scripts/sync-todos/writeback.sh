#!/usr/bin/env bash
# Mirror the live Task list into a project's workspace notes + memory pointer.
#
# This is the "within a session, the live Task list is the truth" half of the
# todo-sync: whatever the agent's task list currently says is projected, as a
# side effect, into <project>/.claude/session-notes/_active.md (a machine-owned
# block — see reconcile.py) and into the project's memory "current focus"
# pointer. It never blocks, never prompts, and never touches the human-authored
# parts of the notes file.
#
# Input  : the hook event JSON on stdin (needs .session_id and .cwd). The
#          session id is taken from stdin ONLY — the ~/.claude/.current-session-id
#          file is a single global slot that the most recent session clobbers,
#          so trusting it here would mirror the wrong session's tasks.
# Output : nothing on success (silent). One-line warning to stderr on trouble.
#
# Safe to call from a Stop hook or by hand. Idempotent: re-running with an
# unchanged task list rewrites nothing.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

sync_is_disabled && exit 0

INPUT=$(cat 2>/dev/null || echo "{}")
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
TX=$(printf '%s' "$INPUT" | jq -r '.transcript_path // ""' 2>/dev/null)
[ -z "$SID" ] && exit 0
[ -z "$CWD" ] && exit 0

TASK_DIR="$HOME/.claude/tasks/$SID"

WORKSPACE=$(sync_workspace_path "$CWD")
NOTES_DIR=$(dirname "$WORKSPACE")

# Current task list. A caller (the Stop hook) may hand us an already-replayed
# list via SYNC_TASKS_FILE so the transcript isn't parsed twice per turn.
# Otherwise prefer the durable transcript (complete, keeps completed tasks,
# survives resume); fall back to the volatile task dir only for manual calls.
if [ -n "${SYNC_TASKS_FILE:-}" ] && [ -f "$SYNC_TASKS_FILE" ]; then
  TASKS=$(cat "$SYNC_TASKS_FILE" 2>/dev/null || echo '[]')
elif [ -n "$TX" ] && [ -f "$TX" ]; then
  TASKS=$(python3 "$SCRIPT_DIR/replay_tasks.py" "$TX" 2>/dev/null || echo '[]')
elif [ -d "$TASK_DIR" ]; then
  TASKS=$(python3 - "$TASK_DIR" <<'PY' 2>/dev/null || echo '[]'
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
  exit 0
fi

TASKS=$(printf '%s' "$TASKS" | jq -c '.' 2>/dev/null || echo '[]')
TASK_COUNT=$(printf '%s' "$TASKS" | jq 'length' 2>/dev/null || echo 0)
# Current-focus pointer: first in_progress task, else first pending.
POINTER=$(printf '%s' "$TASKS" | jq -r '([.[] | select(.status=="in_progress")][0].subject) // ([.[] | select(.status=="pending")][0].subject) // ""' 2>/dev/null || echo '')

# Auto-init the workspace doc when the session has crossed the "more than a
# couple of things to track" bar — but only inside a real claude project (a dir
# that already has a .claude/, or ~/.claude itself). Never create a .claude tree
# in an arbitrary directory just because tasks exist.
if [ ! -f "$WORKSPACE" ]; then
  if [ "$TASK_COUNT" -gt 2 ] && { [ -d "$CWD/.claude" ] || [ "$CWD" = "$HOME/.claude" ] || [[ "$CWD" == */.claude ]]; }; then
    bash "$HOME/.claude/scripts/session-notes/create.sh" \
      --session-id "$SID" --project "$CWD" --name "$SID" >/dev/null 2>&1 || exit 0
  else
    exit 0
  fi
fi
[ -f "$WORKSPACE" ] || exit 0

# Per-file lock (mkdir is atomic) so two sessions writing the same project's
# notes can't interleave. We deliberately do NOT use the global ~/.claude
# sync.lock, which would serialise unrelated projects.
LOCK="$NOTES_DIR/.sync.lock"
# Reap a stale lock from a crashed writer: a sync takes well under a second, so a
# lock dir older than 2 min is abandoned. Without this, one leftover lock would
# no-op sync for this project forever, silently.
if [ -d "$LOCK" ] && [ -n "$(find "$LOCK" -maxdepth 0 -mmin +2 2>/dev/null)" ]; then
  rmdir "$LOCK" 2>/dev/null || true
fi
acquired=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if mkdir "$LOCK" 2>/dev/null; then acquired=1; break; fi
  sleep 0.1
done
if [ "$acquired" != 1 ]; then
  # Don't no-op silently — leave a breadcrumb (the user's recurring burn).
  mkdir -p "$HOME/.claude/logs" 2>/dev/null
  printf '{"ts":"%s","sid":"%s","event":"lock-contention-skip","proj":"%s"}\n' \
    "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$SID" "$CWD" >> "$HOME/.claude/logs/sync-todos.log" 2>/dev/null || true
  exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT

OP_ID=$(bash "$SCRIPT_DIR/wal.sh" start push "$SID" 2>/dev/null || echo "")

# Mirror, and log whether it actually changed the notes (effectiveness telemetry).
RECON=$(printf '%s' "$TASKS" | python3 "$SCRIPT_DIR/reconcile.py" "$WORKSPACE" 2>/dev/null || echo '{}')
mkdir -p "$HOME/.claude/logs" 2>/dev/null
printf '{"ts":"%s","sid":"%s","event":"mirror %s"}\n' \
  "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$SID" \
  "$(printf '%s' "$RECON" | jq -r '"changed=\(.changed) items=\(.items) reason=\(.reason)"' 2>/dev/null || echo 'parse-fail')" \
  >> "$HOME/.claude/logs/sync-todos.log" 2>/dev/null || true

# Memory "current focus" pointer (one-way derived; never authoritative).
if [ -n "$POINTER" ]; then
  # Claude Code encodes a project dir by replacing BOTH '/' and '.' with '-'
  # (so /Users/me/.claude → -Users-me--claude). Missing the dot silently points
  # at a non-existent memory dir for any dotted path (notably ~/.claude itself).
  PROJECT_KEY=$(printf '%s' "$CWD" | sed 's|^/||;s|[/.]|-|g')
  MEM_DIR="$HOME/.claude/projects/-$PROJECT_KEY/memory"
  if [ -d "$MEM_DIR" ]; then
    printf '%s\n' "$POINTER" > "$MEM_DIR/current-focus.md.tmp" 2>/dev/null \
      && mv -f "$MEM_DIR/current-focus.md.tmp" "$MEM_DIR/current-focus.md" 2>/dev/null || true
  fi
fi

[ -n "$OP_ID" ] && bash "$SCRIPT_DIR/wal.sh" done "$OP_ID" 2>/dev/null || true
exit 0
