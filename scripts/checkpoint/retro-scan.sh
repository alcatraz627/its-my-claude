#!/usr/bin/env bash
# scripts/checkpoint/retro-scan.sh — Discover candidate sessions for retroactive
# /core-dump and either print or enqueue them.
#
# A candidate is a transcript .jsonl that:
#   - has > MIN_TURNS user messages (not a trivial session)
#   - is < MAX_AGE_DAYS old (don't chase ancient history)
#   - has NO matching entry in checkpoints/index.jsonl (by session_uuid)
#   - is NOT for a session currently active (~/.claude/sessions/<pid>.json status)
#   - is NOT already in the retro queue
#
# Output modes:
#   --print (default)  list candidates to stdout (JSONL)
#   --enqueue          write candidates to ~/.claude/checkpoints/retro-queue/<uuid>.queued
#                      so flush.sh can process them later
#
# Args:
#   --min-turns N        default 5
#   --max-age-days N     default 7
#   --limit N            default 20 candidates per scan

set -uo pipefail

MIN_TURNS=5
MAX_AGE_DAYS=7
LIMIT=20
MODE="print"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --min-turns)    MIN_TURNS="$2"; shift ;;
    --max-age-days) MAX_AGE_DAYS="$2"; shift ;;
    --limit)        LIMIT="$2"; shift ;;
    --enqueue)      MODE="enqueue" ;;
    --print)        MODE="print" ;;
  esac
  shift
done

PROJECTS_DIR="${HOME}/.claude/projects"
INDEX="${HOME}/.claude/checkpoints/index.jsonl"
SESSIONS_DIR="${HOME}/.claude/sessions"
QUEUE_DIR="${HOME}/.claude/checkpoints/retro-queue"
mkdir -p "$QUEUE_DIR"

python3 - "$PROJECTS_DIR" "$INDEX" "$SESSIONS_DIR" "$QUEUE_DIR" "$MIN_TURNS" "$MAX_AGE_DAYS" "$LIMIT" "$MODE" <<'PY'
import json, os, sys, glob, time
from datetime import datetime, timezone
from pathlib import Path

projects_dir, index_path, sessions_dir, queue_dir, min_turns, max_age, limit, mode = sys.argv[1:9]
min_turns = int(min_turns); max_age = int(max_age); limit = int(limit)

# 1. Set of uuids already in index (matched on session_uuid)
indexed = set()
if os.path.exists(index_path):
    with open(index_path) as f:
        for ln in f:
            ln = ln.strip()
            if not ln: continue
            try: r = json.loads(ln)
            except: continue
            u = r.get("session_uuid")
            if u: indexed.add(u)

# 2. Set of active session uuids (status != stale)
active = set()
if os.path.isdir(sessions_dir):
    for f in glob.glob(os.path.join(sessions_dir, "*.json")):
        try:
            with open(f) as fp:
                s = json.load(fp)
            if s.get("status") in ("idle", "running", "active"):
                u = s.get("sessionId")
                if u: active.add(u)
        except: pass

# 3. Already queued uuids
queued = set()
if os.path.isdir(queue_dir):
    for q in glob.glob(os.path.join(queue_dir, "*.queued")):
        queued.add(os.path.basename(q).replace(".queued", ""))

# 4. Walk transcripts
candidates = []
now = datetime.now(timezone.utc)
for proj_dir in sorted(Path(projects_dir).iterdir() if Path(projects_dir).exists() else []):
    if not proj_dir.is_dir(): continue
    for tx in proj_dir.glob("*.jsonl"):
        uuid = tx.stem
        if uuid in indexed: continue
        if uuid in active:  continue
        if uuid in queued:  continue
        try:
            mtime = datetime.fromtimestamp(tx.stat().st_mtime, tz=timezone.utc)
        except: continue
        age_days = (now - mtime).total_seconds() / 86400
        if age_days > max_age: continue
        # Count turns (user messages) — read the file's line count as a cheap proxy;
        # a more accurate count would parse {"type":"user"} entries.
        try:
            with open(tx) as fp:
                line_count = sum(1 for _ in fp)
        except: continue
        if line_count < min_turns * 2:  # rough: ~2 lines per turn (user + assistant)
            continue
        candidates.append({
            "session_uuid": uuid,
            "transcript":   str(tx),
            "project_root_encoded": proj_dir.name,
            "mtime":        mtime.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "age_days":     round(age_days, 1),
            "line_count":   line_count,
        })

# Newest first; cap
candidates.sort(key=lambda c: c["mtime"], reverse=True)
candidates = candidates[:limit]

if mode == "enqueue":
    for c in candidates:
        qf = os.path.join(queue_dir, f"{c['session_uuid']}.queued")
        with open(qf, "w") as fp:
            json.dump(c, fp)
    print(f"enqueued {len(candidates)} candidates → {queue_dir}/")
else:
    for c in candidates:
        print(json.dumps(c))
    print(f"# {len(candidates)} candidates (mode=print)", file=sys.stderr)
PY
