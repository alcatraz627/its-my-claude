#!/usr/bin/env bash
# pinned-domain consolidator. Runs daily per manifest.
#
# Jobs:
#   1. Decrement decay.cycles_remaining for any pin older than 7 days
#      (one "cycle" = one weekly dream pass).
#   2. Archive pins with cycles_remaining <= 0 → _archived/<today>/.
#   3. Rebuild derived/active.md (un-decayed pins as one markdown view).
#   4. Rebuild derived/_tldr.txt (top-5 newest active pins).
#
# Idempotent — reads events.jsonl, writes only to derived/ and _archived/.
# events.jsonl itself is append-only and never modified here; archival is
# a state-write into individual pin objects (the original file remains
# the source of truth — we track decay-state in a sidecar).

set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
EVENTS="$ROOT/events.jsonl"
DERIVED="$ROOT/derived"
DECAY_STATE="$ROOT/_decay-state.json"
TODAY="$(date -u +%Y-%m-%d)"
ARCH_DIR="$ROOT/_archived/$TODAY"
mkdir -p "$DERIVED" "$ARCH_DIR"

[ -f "$EVENTS" ] || touch "$EVENTS"
[ -f "$DECAY_STATE" ] || echo '{}' > "$DECAY_STATE"

python3 - "$EVENTS" "$DECAY_STATE" "$DERIVED" "$ARCH_DIR" <<'PY'
import sys, os, json, datetime, time

events_path, decay_path, derived_dir, arch_dir = sys.argv[1:5]

# Load events.
events = []
with open(events_path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            continue

# Load decay state: maps pin id → cycles_remaining.
# Missing key = use pin's initial decay.cycles_remaining (default 2).
with open(decay_path) as f:
    decay_state = json.load(f)

now = time.time()
WEEK = 7 * 86400

active = []
to_archive = []

for ev in events:
    pid = ev.get("id")
    if not pid:
        continue
    # Pin's own ts → age in weeks since posting.
    try:
        ev_ts = datetime.datetime.fromisoformat(ev["ts"].replace("Z", "+00:00")).timestamp()
    except (KeyError, ValueError):
        continue
    age_weeks = max(0, int((now - ev_ts) / WEEK))

    initial = (ev.get("decay") or {}).get("cycles_remaining", 2)
    # cycles_remaining = initial - age_weeks. Floor at 0.
    if pid in decay_state:
        # User may have explicitly resolved → force to 0.
        remaining = decay_state[pid]
    else:
        remaining = max(0, initial - age_weeks)

    # Persist computed remaining for visibility (overrideable by `i-dream pin resolve`).
    decay_state[pid] = remaining

    if remaining <= 0:
        to_archive.append(ev)
    else:
        active.append(ev)

# Sort active newest-first by ts.
def ts_key(e):
    try:
        return datetime.datetime.fromisoformat(e["ts"].replace("Z", "+00:00")).timestamp()
    except Exception:
        return 0

active.sort(key=ts_key, reverse=True)

# Archive: append (don't delete from events.jsonl — that's append-only).
if to_archive:
    arch_path = os.path.join(arch_dir, "events-decayed.jsonl")
    with open(arch_path, "a") as f:
        for ev in to_archive:
            f.write(json.dumps(ev) + "\n")

# active.md — one markdown bullet per active pin, with key context.
active_md_path = os.path.join(derived_dir, "active.md")
with open(active_md_path + ".tmp", "w") as f:
    if not active:
        # Leave empty — l2_digest's Rust-side fallback shows an actionable
        # placeholder ("use /pin-for-dream or i-dream pin add"). Writing
        # any content here would shadow that.
        pass
    else:
        for ev in active:
            text = ev.get("text", "(no text)").strip()
            pid = ev["id"]
            framing = (ev.get("framing") or "investigate")
            files_str = ""
            ctx = ev.get("context") or {}
            files = ctx.get("files") or []
            if files:
                parts = []
                for fobj in files[:3]:
                    p = fobj.get("path") if isinstance(fobj, dict) else fobj
                    rng = fobj.get("line_range") if isinstance(fobj, dict) else None
                    if rng and len(rng) == 2:
                        parts.append(f"{p}:{rng[0]}-{rng[1]}")
                    else:
                        parts.append(str(p))
                files_str = " — files: " + ", ".join(parts)
            f.write(f"- **{text}** _(framing: {framing}){files_str}_  \n")
            f.write(f"  `{pid}`\n")
os.replace(active_md_path + ".tmp", active_md_path)

# _tldr.txt — one-liner per active pin (top-5 newest).
tldr_path = os.path.join(derived_dir, "_tldr.txt")
with open(tldr_path + ".tmp", "w") as f:
    for ev in active[:5]:
        text = ev.get("text", "(no text)").strip()
        # Trim to one line, 80 chars max.
        oneliner = text.replace("\n", " ")[:80]
        f.write(f"📌 {oneliner}\n")
os.replace(tldr_path + ".tmp", tldr_path)

# Save decay state.
tmp = decay_path + ".tmp"
with open(tmp, "w") as f:
    json.dump(decay_state, f, indent=2, sort_keys=True)
os.replace(tmp, decay_path)

print(f"pinned consolidate: {len(active)} active, {len(to_archive)} archived this run")
PY
