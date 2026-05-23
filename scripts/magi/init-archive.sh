#!/usr/bin/env bash
# scripts/magi/init-archive.sh — Initialize the per-task archive directory.
#
# Per ~/.claude/assets/docs/20260518-magi-design.md § 10.
# Creates the standard tree + initial 00-task.md from the user prompt.
#
# Usage:
#   init-archive.sh --slug SLUG --prompt "user prompt" [--root PATH]
#   Prints the absolute archive root on success.

set -uo pipefail

SLUG=""
PROMPT=""
ROOT_BASE="$HOME/.claude/assets/magi"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --slug)   SLUG="$2"; shift ;;
    --prompt) PROMPT="$2"; shift ;;
    --root)   ROOT_BASE="$2"; shift ;;
  esac
  shift
done

[[ -n "$SLUG" && -n "$PROMPT" ]] || {
  printf 'usage: %s --slug SLUG --prompt "TEXT" [--root PATH]\n' "$0" >&2
  exit 2
}

# Sanitize slug
SAFE_SLUG=$(printf '%s' "$SLUG" | LC_ALL=C tr -c 'A-Za-z0-9-' '-' | sed 's/-\{2,\}/-/g;s/^-\|-$//g')
TS=$(date "+%Y%m%d-%H%M")
ROOT="$ROOT_BASE/${TS}-${SAFE_SLUG}"

mkdir -p "$ROOT"/{02-voter-prompts,03-voter-proposals,04-voting}

# 00-task.md
cat > "$ROOT/00-task.md" <<EOF
# MAGI task — $SLUG

**Session:** $(echo "${CLAUDE_CODE_SESSION_ID:-unknown}" | head -c 8)
**Started:** $(date -Iseconds)
**Archive:** $ROOT

---

## User prompt

$PROMPT
EOF

# meta.json scaffolding
python3 - "$ROOT" "$SLUG" "$PROMPT" <<'PY'
import json, sys, os
from datetime import datetime, timezone
root, slug, prompt = sys.argv[1:4]
meta = {
  "task_id": os.path.basename(root),
  "slug": slug,
  "user_prompt": prompt,
  "session_id": os.environ.get("CLAUDE_CODE_SESSION_ID", "unknown"),
  "started_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
  "finished_at": None,
  "duration_seconds": None,
  "params": {},
  "voters": [],
  "voting": {},
  "supervisor": {},
  "totals": {},
  "extras": {}
}
with open(os.path.join(root, "meta.json"), "w") as f:
  json.dump(meta, f, indent=2)
PY

printf '%s\n' "$ROOT"
