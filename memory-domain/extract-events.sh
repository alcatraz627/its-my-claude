#!/usr/bin/env bash
# memory-domain — extract events from ~/.claude/projects/*/memory/*.md and
# ~/.claude/memory/global/*.md into events.jsonl.
#
# Idempotent: only emits events for files whose mtime advanced past
# _seen.json. First run is gated to files modified in the last 30 days
# to avoid drowning the first dream-pass in 116+ events at once.
#
# Invoked by i-dream's [consolidation].script field per manifest. Also
# manually runnable: `bash ~/.claude/memory-domain/extract-events.sh`

set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
EVENTS="$ROOT/events.jsonl"
SEEN="$ROOT/_seen.json"
FIRST_RUN_WINDOW_DAYS=30
MAX_FIRST_RUN_EVENTS=30  # cap so first dream-pass isn't drowned in 70+ events

# Touch the events.jsonl on first run.
[ -f "$EVENTS" ] || touch "$EVENTS"
[ -f "$SEEN" ] || echo '{}' > "$SEEN"

python3 - "$EVENTS" "$SEEN" "$FIRST_RUN_WINDOW_DAYS" "$MAX_FIRST_RUN_EVENTS" <<'PY'
import sys, os, json, hashlib, time, datetime, glob

events_path, seen_path, window_days_str, max_first_run_str = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
window_days = int(window_days_str)
max_first_run = int(max_first_run_str)
home = os.path.expanduser("~")

# Source roots: per-project memory dirs + global memory.
roots = []
roots.extend(glob.glob(f"{home}/.claude/projects/*/memory"))
if os.path.isdir(f"{home}/.claude/memory/global"):
    roots.append(f"{home}/.claude/memory/global")

# Load seen state.
with open(seen_path) as f:
    seen = json.load(f)

first_run = len(seen) == 0
window_cutoff = time.time() - window_days * 86400 if first_run else 0

new_events = []
touched = 0
for root in roots:
    for path in glob.glob(f"{root}/*.md"):
        try:
            st = os.stat(path)
        except OSError:
            continue
        mtime = st.st_mtime
        prev_mtime = seen.get(path)
        if prev_mtime is not None and mtime <= prev_mtime:
            continue  # unchanged since last seen
        seen[path] = mtime
        touched += 1
        if first_run and mtime < window_cutoff:
            continue  # mark as seen but don't emit (avoid first-run flood)

        # Parse frontmatter if present.
        try:
            with open(path, encoding="utf-8") as f:
                content = f.read()
        except OSError:
            continue
        name = description = type_ = None
        body = content
        if content.startswith("---\n"):
            end = content.find("\n---\n", 4)
            if end > 0:
                fm = content[4:end]
                body = content[end + 5:]
                for line in fm.splitlines():
                    if line.startswith("name:"):
                        name = line.split(":", 1)[1].strip().strip('"').strip("'")
                    elif line.startswith("description:"):
                        description = line.split(":", 1)[1].strip().strip('"').strip("'")
                    elif line.strip().startswith("type:"):
                        type_ = line.split(":", 1)[1].strip().strip('"').strip("'")

        # Derive project + scope from path.
        if "/projects/" in path:
            project_slug = path.split("/projects/")[1].split("/")[0]
            scope = "project"
        else:
            project_slug = "global"
            scope = "global"

        ts_iso = datetime.datetime.fromtimestamp(mtime, datetime.timezone.utc).isoformat().replace("+00:00", "Z")
        id_hash = hashlib.sha256(path.encode()).hexdigest()[:8]
        event_id = f"mem-{id_hash}-{int(mtime)}"

        event = {
            "id": event_id,
            "ts": ts_iso,
            "kind": "memory_entry",
            "project": project_slug,
            "scope": scope,
            "path": path,
            "name": name or os.path.splitext(os.path.basename(path))[0],
            "description": description,
            "type": type_,
            "body_preview": body.strip()[:300],
        }
        new_events.append(event)

# First-run cap: keep only the N most recent events (by ts) to avoid
# drowning the first dream-pass.
if first_run and len(new_events) > max_first_run:
    new_events.sort(key=lambda e: e["ts"], reverse=True)
    new_events = new_events[:max_first_run]

# Append new events.
with open(events_path, "a", encoding="utf-8") as f:
    for ev in new_events:
        f.write(json.dumps(ev) + "\n")

# Save seen.
tmp = seen_path + ".tmp"
with open(tmp, "w") as f:
    json.dump(seen, f, indent=2, sort_keys=True)
os.replace(tmp, seen_path)

print(f"memory-domain extract: {touched} files touched, {len(new_events)} events emitted "
      f"(first_run={first_run}, window={window_days}d)")
PY
