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
vent_events = []
for v in vents:
    h = v.get("hook_id")
    kind = v.get("kind", "")
    if not v.get("id") or not h:
        continue
    heeded_raw = last_heeded.get(h, "unknown")
    heeded = {"true": True, "false": False}.get(heeded_raw, None)
    vent_events.append({
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
    })
    written += 1

# A2 auto-vents (felt-metabolism, 2026-07-22): the vent join above only
# speaks when a human gripes. Telemetry itself is the continuous behavioral
# signal, so emit one aggregate "telemetry-pulse" event per hook per ISO week
# (last 12 weeks). Ids are deterministic (pulse-<hook>-<week>) and each
# pulse's ts is its week's MONDAY 00:00Z — fixed, so a pulse can never
# out-sort a real vent from its own week (see the cursor note below).
pulse = {}
for t in tel:
    h = t.get("hook_id")
    ts = parse_ts(t.get("ts", ""))
    if not h or not ts or (now - ts).days > 84:
        continue
    iso = ts.isocalendar()
    week = f"{iso[0]}-W{iso[1]:02d}"
    monday = (ts - datetime.timedelta(days=iso[2] - 1)).date().isoformat() + "T00:00:00Z"
    rec = pulse.setdefault((h, week), {"fires": 0, "heeded_true": 0,
                                       "heeded_false": 0, "monday": monday})
    rec["fires"] += 1
    if str(t.get("heeded")) == "true":
        rec["heeded_true"] += 1
    elif str(t.get("heeded")) == "false":
        rec["heeded_false"] += 1

pulses = 0
pulse_events = []
for (h, week), rec in sorted(pulse.items()):
    pulse_events.append({
        "id": f"pulse-{h}-{week}",
        "ts": rec["monday"],
        "slug": h,
        "kind": "telemetry-pulse",
        "impact": "low",
        "hook_id": h,
        "note": (f"auto-pulse {week}: {rec['fires']} fires, "
                 f"heeded {rec['heeded_true']}/{rec['heeded_true'] + rec['heeded_false']} of tracked"),
        "command_or_context": "",
        "heeded": None,
        "fire_count_14d": fire_14d.get(h, 0),
        "fires_week": rec["fires"],
    })
    pulses += 1

# The downstream delta cursor is POSITION-based (i-dream external_domain.rs
# finds the cursor id in file order and takes everything after it, then
# anchors on the stream's LAST id). Appending pulses after vents anchored the
# cursor on a trailing pulse and shadowed every future vent (validation
# finding 1, 2026-07-22). The stream is therefore written ts-sorted in one
# pass, and pulse ts is a fixed past boundary (week Monday) — so the newest
# element is always a real vent, or a pulse no same-week vent can sort
# behind. Known bounded cost: a week-in-progress pulse that updates after
# the cursor passes its position re-delivers only via the next week's pulse.
all_events = vent_events + pulse_events
all_events.sort(key=lambda e: e.get("ts") or "")
with open(out, "w") as f:
    for ev in all_events:
        f.write(json.dumps(ev) + "\n")

print(f"extract-events: {written} vents + {pulses} pulses -> {out} (vents={len(vents)}, telemetry={len(tel)})")
PY
