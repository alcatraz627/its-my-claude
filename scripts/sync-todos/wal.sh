#!/usr/bin/env bash
# Append-only WAL for sync ops. Orphan starts (no matching done) surface to user
# via SessionStart hinter so partial failures are visible.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

CMD="${1:-}"

new_op_id() {
  printf 'sync-%s-%04x' "$(date -u +%s)" "$RANDOM"
}

case "$CMD" in
  start)
    OP_ID=$(new_op_id)
    OP="${2:-unknown}"
    SID="${3:-}"
    jq -nc \
      --arg id "$OP_ID" --arg op "$OP" --arg sid "$SID" \
      --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
      '{id:$id, op:$op, sid:$sid, started_at:$ts, phase:"start"}' \
      >> "$SYNC_WAL" 2>/dev/null
    printf '%s' "$OP_ID"
    ;;
  done)
    OP_ID="${2:-}"
    [ -z "$OP_ID" ] && { echo "wal.sh done: missing op_id" >&2; exit 2; }
    jq -nc \
      --arg id "$OP_ID" \
      --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
      '{id:$id, finished_at:$ts, phase:"done"}' \
      >> "$SYNC_WAL" 2>/dev/null
    ;;
  orphans)
    # Print op_ids that have a start but no matching done.
    [ -f "$SYNC_WAL" ] || exit 0
    python3 - <<'PY'
import json, os
wal = os.path.expanduser("~/.claude/sync-wal.jsonl")
starts, dones = {}, set()
try:
  with open(wal) as f:
    for line in f:
      try:
        e = json.loads(line)
      except Exception:
        continue
      if e.get("phase") == "start":
        starts[e["id"]] = e
      elif e.get("phase") == "done":
        dones.add(e["id"])
  for oid, e in starts.items():
    if oid not in dones:
      print(f"{oid}\t{e.get('op','?')}\t{e.get('started_at','?')}")
except FileNotFoundError:
  pass
PY
    ;;
  prune)
    # Compact: drop start+done pairs older than 7 days, keep orphans.
    [ -f "$SYNC_WAL" ] || exit 0
    python3 - <<'PY'
import json, os, time
wal = os.path.expanduser("~/.claude/sync-wal.jsonl")
cutoff = time.time() - 7*86400
keep = []
starts, dones = {}, {}
with open(wal) as f:
  for line in f:
    try: e = json.loads(line)
    except: continue
    if e.get("phase") == "start": starts[e["id"]] = e
    elif e.get("phase") == "done": dones[e["id"]] = e
import datetime as dt
def parse(s):
  try: return dt.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").timestamp()
  except: return 0
for oid, s in starts.items():
  d = dones.get(oid)
  if d and parse(s.get("started_at","")) < cutoff:
    continue
  keep.append(s)
  if d: keep.append(d)
with open(wal + ".tmp", "w") as f:
  for e in keep:
    f.write(json.dumps(e) + "\n")
os.replace(wal + ".tmp", wal)
print(f"pruned: kept {len(keep)} entries")
PY
    ;;
  *)
    cat <<EOF
usage: $0 start <op> <sid>   # append start, prints op_id
       $0 done <op_id>        # append matching done
       $0 orphans             # list op_ids with start but no done
       $0 prune               # drop completed ops older than 7d
EOF
    exit 2
    ;;
esac
