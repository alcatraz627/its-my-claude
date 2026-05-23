#!/usr/bin/env bash
# checkpoint/list-transcripts.sh — Cross-reference transcripts with checkpoints.
#
# For a given project CWD (or all projects), find Claude Code session transcripts
# under ~/.claude/projects/<encoded>/ and join them with checkpoints/index.jsonl
# entries by session-id. The /revive skill uses this to render its picker.
#
# Usage:
#   list-transcripts.sh                       # all transcripts, JSON output
#   list-transcripts.sh --project PATH        # transcripts for one project
#   list-transcripts.sh --limit N             # cap results (default 20)
#   list-transcripts.sh --within DAYS         # only sessions newer than N days
#   list-transcripts.sh --pretty              # human-readable table

set -uo pipefail

PROJECT="" LIMIT=20 WITHIN_DAYS=30 PRETTY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT="$2"; shift ;;
    --limit)   LIMIT="$2"; shift ;;
    --within)  WITHIN_DAYS="$2"; shift ;;
    --pretty)  PRETTY=1 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

# Encode a path the way Claude Code does for projects/: replace / with -, prefix -.
encode_path() {
  local p="$1"
  printf '%s' "$p" | sed 's|/|-|g'
}

PROJECTS_DIR="${HOME}/.claude/projects"
INDEX="${HOME}/.claude/checkpoints/index.jsonl"

python3 - "$PROJECTS_DIR" "$INDEX" "$PROJECT" "$LIMIT" "$WITHIN_DAYS" "$PRETTY" <<'PY'
import json, os, sys
from datetime import datetime, timezone
from pathlib import Path

projects_dir, index_path, proj_filter, limit, within_days, pretty = sys.argv[1:7]
limit = int(limit); within_days = int(within_days); pretty = bool(int(pretty))

def encode(path):
    # Claude Code encoding: BOTH '/' and '.' map to '-'.
    # E.g. /Users/alcatraz627/.claude → -Users-alcatraz627--claude
    return path.replace("/", "-").replace(".", "-")

def decode(encoded):
    # Best-effort reverse; ambiguous because '-' could be from either '/' or '.'.
    # Reconstruct a readable display by mapping '--' → '/.', remaining '-' → '/'.
    if encoded.startswith("-"):
        return "/" + encoded[1:].replace("--", "/.").replace("-", "/")
    return encoded.replace("--", "/.").replace("-", "/")

# Build checkpoint index: session_uuid → list of entries (primary join key)
# Also session_id → entries as a fallback when uuid wasn't captured.
ckpts_by_uuid = {}
ckpts_by_sid = {}
if os.path.exists(index_path):
    with open(index_path) as f:
        for ln in f:
            ln = ln.strip()
            if not ln: continue
            try: r = json.loads(ln)
            except: continue
            uuid = r.get("session_uuid")
            sid  = r.get("session_id")
            if uuid:
                ckpts_by_uuid.setdefault(uuid, []).append(r)
            if sid:
                ckpts_by_sid.setdefault(sid, []).append(r)

# Walk transcripts
rows = []
now = datetime.now(timezone.utc)
proj_encoded_filter = encode(proj_filter) if proj_filter else None

for proj_dir in sorted(Path(projects_dir).iterdir() if Path(projects_dir).exists() else []):
    if not proj_dir.is_dir(): continue
    if proj_encoded_filter and proj_dir.name != proj_encoded_filter: continue
    proj_decoded = decode(proj_dir.name)
    for tx in proj_dir.glob("*.jsonl"):
        sid = tx.stem  # UUID
        try:
            mtime = datetime.fromtimestamp(tx.stat().st_mtime, tz=timezone.utc)
        except: continue
        age_days = (now - mtime).total_seconds() / 86400
        if age_days > within_days: continue
        size_kb = tx.stat().st_size // 1024
        ckpt = None
        # Primary join: by UUID (full-string match)
        if sid in ckpts_by_uuid:
            ckpt = sorted(ckpts_by_uuid[sid], key=lambda r: r.get("ts", ""))[-1]
        # Fallback: by session_id prefix-match (covers checkpoints written
        # before --session-uuid was captured)
        elif sid[:8] in ckpts_by_sid:
            ckpt = sorted(ckpts_by_sid[sid[:8]], key=lambda r: r.get("ts", ""))[-1]
        rows.append({
            "session_id":  sid,
            "transcript":  str(tx),
            "project":     proj_decoded,
            "mtime":       mtime.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "age_days":    round(age_days, 1),
            "size_kb":     size_kb,
            "checkpoint":  ckpt,  # full ckpt JSON or None
        })

# Sort by recency
rows.sort(key=lambda r: r["mtime"], reverse=True)
rows = rows[:limit]

if pretty:
    if not rows:
        print("(no transcripts found)")
        sys.exit(0)
    print(f"  {'#':<3} {'NAME':<24} {'PROJECT':<36} {'AGE':<8} {'SIZE':<8} HAS-CKPT")
    for i, r in enumerate(rows, 1):
        name = (r["checkpoint"]["name"] if r["checkpoint"] else f"({r['session_id'][:8]})")[:24]
        proj = r["project"]
        if len(proj) > 36: proj = "…" + proj[-35:]
        age = f"{r['age_days']}d" if r['age_days'] >= 1 else "today"
        size = f"{r['size_kb']}KB" if r['size_kb'] < 1024 else f"{r['size_kb']//1024}MB"
        has = "✓" if r["checkpoint"] else "·"
        print(f"  {i:<3} {name:<24} {proj:<36} {age:<8} {size:<8} {has}")
        if r["checkpoint"] and r["checkpoint"].get("summary"):
            print(f"      └─ {r['checkpoint']['summary'][:70]}")
else:
    for r in rows:
        print(json.dumps(r))
PY
