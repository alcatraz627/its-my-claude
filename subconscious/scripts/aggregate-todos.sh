#!/usr/bin/env bash
# subconscious/scripts/aggregate-todos.sh
#
# Walk all ingest-queue/*.json files, extract their `pending` arrays, and emit
# a single deduped JSONL stream of pending todos with provenance — newest first.
#
# Output: ~/.claude/subconscious/dreams/pending-todos.jsonl
# Each line: {"todo": "...", "session_id": "...", "project_root": "...", "ts": "...",
#             "checkpoint_path": "...", "seen_count": N}
#
# Dedup: by lowercased, whitespace-collapsed todo text. The newest occurrence wins
# (its ts/session_id are kept); seen_count tracks total occurrences across sessions.
#
# Usage:
#   aggregate-todos.sh                    # rebuild pending-todos.jsonl
#   aggregate-todos.sh --stdout           # emit to stdout without writing the file
#   aggregate-todos.sh --pretty           # human-readable table to stdout

set -uo pipefail

QUEUE_DIR="${HOME}/.claude/subconscious/dreams/ingest-queue"
OUT="${HOME}/.claude/subconscious/dreams/pending-todos.jsonl"
MODE="file"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stdout) MODE="stdout" ;;
    --pretty) MODE="pretty" ;;
  esac
  shift
done

python3 - "$QUEUE_DIR" "$OUT" "$MODE" <<'PY'
import json, os, sys, re
from glob import glob

queue_dir, out_path, mode = sys.argv[1:4]

if not os.path.isdir(queue_dir):
    if mode != "pretty": pass
    print("(no ingest queue yet)" if mode == "pretty" else "", end="")
    sys.exit(0)

# Walk all *.json files
entries = []
for f in sorted(glob(os.path.join(queue_dir, "*.json"))):
    try:
        with open(f) as fp:
            entries.append(json.load(fp))
    except Exception:
        continue

# Order newest-first by ts
entries.sort(key=lambda e: e.get("ts", ""), reverse=True)

# Dedup by normalized text
def norm(s):
    return re.sub(r"\s+", " ", s.lower()).strip()

todos = {}  # norm_key → record
for e in entries:
    for t in e.get("pending", []):
        if not t.strip(): continue
        # Strip leading markdown markers (**bold** etc) for clearer display
        text = re.sub(r"^\*+\s*|\*+\s*$", "", t).strip()
        k = norm(text)
        if not k: continue
        if k not in todos:
            todos[k] = {
                "todo":            text,
                "session_id":      e.get("session_id"),
                "project_root":    e.get("project_root"),
                "ts":              e.get("ts"),
                "checkpoint_path": e.get("checkpoint_path"),
                "seen_count":      1,
            }
        else:
            todos[k]["seen_count"] += 1

# Sort: high-seen-count first, then newest
sorted_todos = sorted(todos.values(), key=lambda r: (-r["seen_count"], r.get("ts", "")), reverse=False)
sorted_todos = sorted(todos.values(), key=lambda r: (-r["seen_count"], -ord(r.get("ts", " ")[0]) if r.get("ts") else 0))

if mode == "pretty":
    if not sorted_todos:
        print("(no pending todos in the dream ingest)")
        sys.exit(0)
    print(f"  {'#':<3} {'TODO':<60} {'SEEN':<5} {'AGE':<10} PROJECT")
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc)
    for i, r in enumerate(sorted_todos[:30], 1):
        text = r["todo"][:60]
        seen = f"×{r['seen_count']}"
        ts = r.get("ts", "")
        try:
            t = datetime.strptime(ts, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
            age_s = (now - t).total_seconds()
            if age_s < 86400:   age = f"{int(age_s/3600)}h ago"
            else:               age = f"{int(age_s/86400)}d ago"
        except: age = "?"
        proj = (r.get("project_root") or "")
        if proj.startswith(os.path.expanduser("~")):
            proj = "~" + proj[len(os.path.expanduser("~")):]
        proj = proj[-30:]
        print(f"  {i:<3} {text:<60} {seen:<5} {age:<10} {proj}")
elif mode == "stdout":
    for r in sorted_todos:
        print(json.dumps(r))
else:
    with open(out_path, "w") as fp:
        for r in sorted_todos:
            fp.write(json.dumps(r) + "\n")
    print(f"wrote: {out_path} ({len(sorted_todos)} unique todos from {len(entries)} ingests)")
PY
