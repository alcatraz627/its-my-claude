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
#   list.sh --cwd DIR             # three blocks: DIR's indexed entries first, then
#                                 # _*.claude.md files on disk in DIR the index never
#                                 # saw (picked by path), then other projects. Row
#                                 # numbers stay global newest-first so they line up
#                                 # with resolve.sh --pick N.
#
# Used by /catchup to render the picker. The on-disk block exists because a
# project's own seven checkpoints sat unlisted while six other projects' entries
# filled the picker (versable-builder, 2026-09-08, ledger 25).

set -uo pipefail

LIMIT=10 SESSION_FILTER="" PROJECT_FILTER="" JSON_OUT=0 WITHIN_H=0 CWD=""
INDEX="${HOME}/.claude/checkpoints/index.jsonl"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit)      LIMIT="$2"; shift ;;
    --session-id) SESSION_FILTER="$2"; shift ;;
    --project)    PROJECT_FILTER="$2"; shift ;;
    --within)     WITHIN_H="$2"; shift ;;
    --cwd)        CWD="$2"; shift ;;
    --json)       JSON_OUT=1 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

if [[ ! -f "$INDEX" ]]; then
  # No index yet. With --cwd there may still be files on disk worth naming.
  if [[ -n "$CWD" ]]; then
    found=0
    for p in "$CWD"/_*.claude.md; do
      [[ -f "$p" ]] || continue
      case "$(basename "$p")" in _checkpoint.claude.md|_precompact-checkpoint.claude.md) continue ;; esac
      (( found == 0 )) && printf '  on disk here, not indexed (pick by path):\n'
      found=1
      printf '  --  %s  → /catchup %s\n' "$(basename "$p")" "$p"
    done
    (( found == 1 )) && exit 0
  fi
  printf '(no checkpoint index yet — run /core-dump first)\n'; exit 0
fi

python3 - "$INDEX" "$LIMIT" "$SESSION_FILTER" "$PROJECT_FILTER" "$JSON_OUT" "$WITHIN_H" "$CWD" <<'PY'
import json, sys, os, time, glob
from datetime import datetime, timezone

path, limit, sess_f, proj_f, json_out, within_h, cwd = sys.argv[1:8]
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

if json_out:
    for r in rows[-limit:]: print(json.dumps(r))
    sys.exit(0)

def fmt_age(ts):
    try:
        t = datetime.strptime(ts, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
    except: return "?"
    return fmt_secs((datetime.now(timezone.utc) - t).total_seconds())

def fmt_secs(s):
    if s < 90:        return f"{int(s)}s ago"
    if s < 5400:      return f"{int(s/60)}m ago"
    if s < 172800:    return f"{int(s/3600)}h ago"
    return f"{int(s/86400)}d ago"

def fmt_proj(p):
    p = p or "?"
    home = os.path.expanduser("~")
    if p.startswith(home): p = "~" + p[len(home):]
    return p[-32:]

def line(i, r):
    name = (r.get("name") or r.get("session_id") or "?")[:22]
    proj = fmt_proj(r.get("project_root"))
    age = fmt_age(r.get("ts", ""))
    summary = (r.get("summary") or "")[:60]
    return f"  {i:<3} {name:<22} {proj:<34} {age:<9}  {summary}"

header = f"  {'#':<3} {'NAME':<22} {'PROJECT':<34} {'AGE':<9}  SUMMARY"

# Number newest-first (#1 = most recent) so a picker row N lines up with
# `resolve.sh --pick N`, which counts from the most recent entry. Following the
# /catchup picker verbatim used to load the opposite checkpoint. The --json
# branch above stays chronological for machine consumers.
if not cwd:
    rows = rows[-limit:]
    if not rows:
        print("(no matching checkpoints)"); sys.exit(0)
    print(header)
    for i, r in enumerate(reversed(rows), 1):
        print(line(i, r))
    sys.exit(0)

# --cwd: global numbering over the same window resolve.sh --pick reads (last 100),
# shown in three blocks. The number is the contract; the grouping is the help.
numbered = list(enumerate(reversed(rows[-100:]), 1))
def real(p):
    try: return os.path.realpath(p)
    except Exception: return p
indexed_paths = {real(r.get("checkpoint_path", "")) for _, r in numbered if r.get("checkpoint_path")}
here   = [(i, r) for i, r in numbered if r.get("project_root") == cwd][:limit]
others = [(i, r) for i, r in numbered if r.get("project_root") != cwd][:limit]

skip = {"_checkpoint.claude.md", "_precompact-checkpoint.claude.md"}
disk = []
for p in glob.glob(os.path.join(cwd, "_*.claude.md")):
    if os.path.basename(p) in skip: continue
    if real(p) in indexed_paths: continue
    try: disk.append((os.path.getmtime(p), p))
    except OSError: continue
disk.sort(reverse=True)

if not here and not disk and not others:
    print("(no matching checkpoints)"); sys.exit(0)

if here:
    print(f"  this project ({fmt_proj(cwd)}):")
    print(header)
    for i, r in here: print(line(i, r))
else:
    print(f"  this project ({fmt_proj(cwd)}): nothing indexed")
if disk:
    print("  on disk here, not indexed (pick by path):")
    now = time.time()
    for m, p in disk[:limit]:
        print(f"  --  {os.path.basename(p):<34} {fmt_secs(now - m):<9}  → /catchup {p}")
if others:
    print("  other projects:")
    print(header)
    for i, r in others: print(line(i, r))
PY
