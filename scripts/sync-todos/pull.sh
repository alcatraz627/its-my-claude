#!/usr/bin/env bash
# Pull worker for sync-todos Phase 1.
# Reads workspace _active.md Todos section, writes /tmp/claude-todo-pending-<sid>.json,
# updates memory pointer to first unchecked item.
# Called from SessionStart orchestrator. Silent on success; one-line warn on failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

sync_is_disabled && exit 0

INPUT=$(cat 2>/dev/null || echo "{}")
SID=$(sync_session_id "$INPUT")
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)

[ -z "$SID" ] && exit 0
[ -z "$CWD" ] && exit 0

WORKSPACE=$(sync_workspace_path "$CWD")
[ -f "$WORKSPACE" ] || exit 0

PENDING=$(sync_pending_path "$SID")

if ! sync_acquire_lock; then
  echo "[sync-pull] lock busy, skipping" >&2
  exit 0
fi
trap sync_release_lock EXIT

OP_ID=$(bash "$SCRIPT_DIR/wal.sh" start pull "$SID")

# Extract unchecked items from a `## Todos` section. Supports `- [ ]` and `* [ ]`.
TODOS_JSON=$(python3 - "$WORKSPACE" <<'PY' 2>/dev/null || echo '[]'
import sys, re, json
with open(sys.argv[1]) as f:
  text = f.read()
m = re.search(r'(?ms)^\s*##\s+Todos\s*\n(.*?)(?=^\s*##\s|\Z)', text)
if not m:
  print('[]'); sys.exit(0)
items = []
for line in m.group(1).splitlines():
  mm = re.match(r'\s*[-*]\s*\[\s*\]\s+(.+?)\s*$', line)
  if mm:
    items.append(mm.group(1))
print(json.dumps(items))
PY
)

HASH=$(sync_content_hash "$WORKSPACE")

# Idempotency: if pending file already reflects this hash, skip writing.
if [ -f "$PENDING" ]; then
  PREV_HASH=$(jq -r '.workspace_hash // ""' "$PENDING" 2>/dev/null)
  if [ "$PREV_HASH" = "$HASH" ]; then
    bash "$SCRIPT_DIR/wal.sh" done "$OP_ID"
    exit 0
  fi
fi

# Atomic write: tmp → rename.
TMP="${PENDING}.tmp"
jq -nc \
  --arg sid "$SID" \
  --arg ws "$WORKSPACE" \
  --arg hash "$HASH" \
  --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  --argjson todos "$TODOS_JSON" \
  '{session_id:$sid, workspace:$ws, workspace_hash:$hash, written_at:$ts, unchecked_todos:$todos}' \
  > "$TMP" 2>/dev/null
mv -f "$TMP" "$PENDING" 2>/dev/null

# Memory pointer: first unchecked → ~/.claude/projects/<project>/memory/current-focus.md
FIRST=$(echo "$TODOS_JSON" | jq -r '.[0] // ""')
if [ -n "$FIRST" ]; then
  PROJECT_KEY=$(echo "$CWD" | sed 's|^/||;s|/|-|g')
  MEM_DIR="$HOME/.claude/projects/-$PROJECT_KEY/memory"
  if [ -d "$MEM_DIR" ]; then
    printf '%s\n' "$FIRST" > "$MEM_DIR/current-focus.md.tmp" 2>/dev/null
    mv -f "$MEM_DIR/current-focus.md.tmp" "$MEM_DIR/current-focus.md" 2>/dev/null || true
  fi
fi

bash "$SCRIPT_DIR/wal.sh" done "$OP_ID"
