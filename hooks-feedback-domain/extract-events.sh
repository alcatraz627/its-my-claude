#!/usr/bin/env bash
# extract-events.sh — claude-audit domain consolidation (i-dream contract §1).
#
# LEFT-JOIN agent vents (~/.claude/hooks/feedback.jsonl) with telemetry
# (~/.claude/hooks/warn-events.jsonl) on hook_id, deriving `impact` from `kind`
# and enriching with `heeded` + `fire_count_14d`. Emits one event per vent to
# this domain's events.jsonl. Event id = the vent's id (stable across passes —
# the cursor invariant the contract requires).
#
# Run by i-dream before each read (manifest [consolidation].script), or manually.

set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 - "$DIR" <<'PY'
import json, os, sys, datetime

dom = sys.argv[1]
H = os.path.expanduser("~/.claude/hooks")
fb = os.path.join(H, "feedback.jsonl")
we = os.path.join(H, "warn-events.jsonl")
out = os.path.join(dom, "events.jsonl")

IMPACT = {
    "false-positive": "high", "obstructive": "high", "too-aggressive": "high",
    "confusing": "med", "slowed-me-down": "med",
    "useful": "low",
}

def load(path):
    rows = []
    if os.path.exists(path):
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    rows.append(json.loads(line))
                except Exception:
                    continue
    return rows

vents = load(fb)
tel = load(we)

# telemetry index by hook_id
now = datetime.datetime.now(datetime.timezone.utc)
def parse_ts(s):
    try:
        return datetime.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
    except Exception:
        return None

fire_14d = {}
last_heeded = {}
for t in tel:
    h = t.get("hook_id")
    if not h:
        continue
    ts = parse_ts(t.get("ts", ""))
    if ts and (now - ts).days <= 14:
        fire_14d[h] = fire_14d.get(h, 0) + 1
    # most-recent heeded value per hook
    last_heeded[h] = t.get("heeded", "unknown")

written = 0
with open(out, "w") as f:
    for v in vents:
        h = v.get("hook_id")
        kind = v.get("kind", "")
        if not v.get("id") or not h:
            continue
        heeded_raw = last_heeded.get(h, "unknown")
        heeded = {"true": True, "false": False}.get(heeded_raw, None)
        ev = {
            "id": v["id"],                       # STABLE cursor key = vent id
            "ts": v.get("ts", ""),
            "slug": h,                            # slug = hook_id (no domain prefix)
            "kind": kind,
            "impact": IMPACT.get(kind, "med"),
            "hook_id": h,
            "note": v.get("note", ""),
            "command_or_context": v.get("command_or_context", ""),
            "heeded": heeded,
            "fire_count_14d": fire_14d.get(h, 0),
        }
        f.write(json.dumps(ev) + "\n")
        written += 1

print(f"extract-events: {written} events -> {out} (vents={len(vents)}, telemetry={len(tel)})")
PY
