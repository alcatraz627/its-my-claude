#!/usr/bin/env bash
# checkpoint/list.sh — List recent checkpoints from the index.
#
# Usage:
#   list.sh                       # show last 10 entries, formatted for human read
#   list.sh --limit N             # show last N entries
#   list.sh --session-id ID       # only entries matching a session
#   list.sh --project PATH        # only entries under a project root prefix
#   list.sh --json                # emit raw JSONL (last N lines of index)
#   list.sh --within HOURS        # only entries newer than N hours
#
# Used by /catchup to render the picker.

set -uo pipefail

LIMIT=10 SESSION_FILTER="" PROJECT_FILTER="" JSON_OUT=0 WITHIN_H=0
INDEX="${HOME}/.claude/checkpoints/index.jsonl"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit)      LIMIT="$2"; shift ;;
    --session-id) SESSION_FILTER="$2"; shift ;;
    --project)    PROJECT_FILTER="$2"; shift ;;
    --within)     WITHIN_H="$2"; shift ;;
    --json)       JSON_OUT=1 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

[[ -f "$INDEX" ]] || { printf '(no checkpoint index yet — run /core-dump first)\n'; exit 0; }

python3 - "$INDEX" "$LIMIT" "$SESSION_FILTER" "$PROJECT_FILTER" "$JSON_OUT" "$WITHIN_H" <<'PY'
import json, sys, os, time
from datetime import datetime, timezone

path, limit, sess_f, proj_f, json_out, within_h = sys.argv[1:7]
limit = int(limit); within_h = float(within_h); json_out = bool(int(json_out))

rows = []
with open(path) as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try: row = json.loads(line)
        except: continue
        if sess_f and row.get("session_id") != sess_f: continue
        if proj_f and not (row.get("project_root", "").startswith(proj_f)): continue
        if within_h > 0:
            try:
                ts = datetime.strptime(row["ts"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
                age_h = (datetime.now(timezone.utc) - ts).total_seconds() / 3600
                if age_h > within_h: continue
            except Exception:
                continue
        rows.append(row)

rows = rows[-limit:]

if json_out:
    for r in rows: print(json.dumps(r))
    sys.exit(0)

if not rows:
    print("(no matching checkpoints)")
    sys.exit(0)

def fmt_age(ts):
    try:
        t = datetime.strptime(ts, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
    except: return "?"
    s = (datetime.now(timezone.utc) - t).total_seconds()
    if s < 90:        return f"{int(s)}s ago"
    if s < 5400:      return f"{int(s/60)}m ago"
    if s < 172800:    return f"{int(s/3600)}h ago"
    return f"{int(s/86400)}d ago"

def fmt_proj(p):
    p = p or "?"
    home = os.path.expanduser("~")
    if p.startswith(home): p = "~" + p[len(home):]
    return p[-32:]

print(f"  {'#':<3} {'NAME':<22} {'PROJECT':<34} {'AGE':<9}  SUMMARY")
for i, r in enumerate(rows, 1):
    name = (r.get("name") or r.get("session_id") or "?")[:22]
    proj = fmt_proj(r.get("project_root"))
    age = fmt_age(r.get("ts", ""))
    summary = (r.get("summary") or "")[:60]
    print(f"  {i:<3} {name:<22} {proj:<34} {age:<9}  {summary}")
PY
