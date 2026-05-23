#!/usr/bin/env bash
# sessions-domain — extract events from ~/.claude/projects/<project>/*.jsonl
# (Claude Code session transcripts) into events.jsonl.
#
# One event per SESSION (per file), NOT per message. The 104+ session files
# each have ~30-500 lines — per-message would blow the corpus to 10k+ events.
# Per-session events carry summary metadata (message counts, first user msg
# preview, timespan) — enough for the dream pass to find patterns across
# sessions without drowning in transcript bodies.
#
# Idempotent + first-run gated to 30-day window. Invoked manually or as
# [consolidation].script per manifest.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
EVENTS="$ROOT/events.jsonl"
SEEN="$ROOT/_seen.json"
FIRST_RUN_WINDOW_DAYS=30
MAX_FIRST_RUN_EVENTS=30  # cap first-run output (104 sessions in 30d otherwise)

[ -f "$EVENTS" ] || touch "$EVENTS"
[ -f "$SEEN" ] || echo '{}' > "$SEEN"

python3 - "$EVENTS" "$SEEN" "$FIRST_RUN_WINDOW_DAYS" "$MAX_FIRST_RUN_EVENTS" <<'PY'
import sys, os, json, time, datetime, glob

events_path, seen_path, window_days_str, max_first_run_str = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
window_days = int(window_days_str)
max_first_run = int(max_first_run_str)
home = os.path.expanduser("~")

with open(seen_path) as f:
    seen = json.load(f)
first_run = len(seen) == 0
window_cutoff = time.time() - window_days * 86400 if first_run else 0

new_events = []
touched = 0
for path in glob.glob(f"{home}/.claude/projects/*/*.jsonl"):
    try:
        st = os.stat(path)
    except OSError:
        continue
    mtime = st.st_mtime
    prev_mtime = seen.get(path)
    if prev_mtime is not None and mtime <= prev_mtime:
        continue
    seen[path] = mtime
    touched += 1
    if first_run and mtime < window_cutoff:
        continue

    # Parse the jsonl: collect summary stats without holding the whole
    # body in memory.
    msg_count = 0
    user_msg_count = 0
    asst_msg_count = 0
    first_user_msg = None
    first_ts = None
    last_ts = None
    session_id = None
    try:
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    d = json.loads(line)
                except json.JSONDecodeError:
                    continue
                msg_count += 1
                t = d.get("type")
                ts = d.get("timestamp")
                if session_id is None:
                    session_id = d.get("sessionId")
                if ts:
                    if first_ts is None:
                        first_ts = ts
                    last_ts = ts
                if t == "user":
                    user_msg_count += 1
                    if first_user_msg is None:
                        content = d.get("content") or d.get("message", {}).get("content") if isinstance(d.get("message"), dict) else d.get("content")
                        if isinstance(content, str):
                            first_user_msg = content[:300]
                        elif isinstance(content, list) and content:
                            # Anthropic SDK message-block shape
                            for block in content:
                                if isinstance(block, dict) and block.get("type") == "text":
                                    first_user_msg = block.get("text", "")[:300]
                                    break
                elif t == "assistant":
                    asst_msg_count += 1
    except OSError:
        continue

    # Derive project slug + uuid.
    parts = path.split("/projects/", 1)
    project_slug = parts[1].split("/")[0] if len(parts) > 1 else "unknown"
    file_name = os.path.basename(path)
    uuid = os.path.splitext(file_name)[0]
    short_uuid = uuid[:8]

    # ts = first message ts if available, else file mtime.
    ts_iso = first_ts or datetime.datetime.fromtimestamp(
        mtime, datetime.timezone.utc
    ).isoformat().replace("+00:00", "Z")

    event_id = f"sess-{short_uuid}-{int(mtime)}"
    event = {
        "id": event_id,
        "ts": ts_iso,
        "kind": "session_summary",
        "project": project_slug,
        "uuid": uuid,
        "path": path,
        "message_count": msg_count,
        "user_msg_count": user_msg_count,
        "assistant_msg_count": asst_msg_count,
        "first_user_msg_preview": first_user_msg,
        "last_ts": last_ts,
        "session_id_in_file": session_id,
    }
    new_events.append(event)

# First-run cap.
if first_run and len(new_events) > max_first_run:
    new_events.sort(key=lambda e: e["ts"], reverse=True)
    new_events = new_events[:max_first_run]

with open(events_path, "a", encoding="utf-8") as f:
    for ev in new_events:
        f.write(json.dumps(ev) + "\n")

tmp = seen_path + ".tmp"
with open(tmp, "w") as f:
    json.dump(seen, f, indent=2, sort_keys=True)
os.replace(tmp, seen_path)

print(f"sessions-domain extract: {touched} files touched, {len(new_events)} events emitted "
      f"(first_run={first_run}, window={window_days}d)")
PY
