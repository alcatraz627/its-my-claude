"""The owner's reaction rate after a /tasks render, and whether the length nudge predicts it.

P6 (flag rate): of the owner's own prompts logged within 30 minutes of a render
(cron wakes and heartbeats excluded), how many carried a friction flag.
P8 (the join): each reaction row is joined to the counter-gate row of the reply
that preceded it in the same session, so a breach (long reply to a short ask)
can be set beside a flagged reaction. The owner's question, verbatim in
directions.md P8: "623 breaches in 1067 rows, never read"; this is the only way
to answer it with a number.

Usage: python3 reaction-join.py [--days 7]
"""
import datetime, json, os, sys

HOME = os.path.expanduser("~/.claude")
REACT = os.path.join(HOME, "logs", "tasks-render-reactions.jsonl")
GATE = os.path.join(HOME, "logs", "counter-gate.jsonl")
MACHINE = ("Wake check", "Heartbeat", "<task-notification", "[SYSTEM", "Caveat:")
days = 7
if "--days" in sys.argv: days = int(sys.argv[sys.argv.index("--days") + 1])
cut = datetime.datetime.now(datetime.timezone.utc).timestamp() - days * 86400

def load(p):
    out = []
    if not os.path.exists(p): return out
    for l in open(p, encoding="utf-8", errors="replace"):
        try: out.append(json.loads(l))
        except Exception: pass
    return out

def ts_of(r):
    t = r.get("ts")
    if isinstance(t, (int, float)): return float(t)
    try: return datetime.datetime.fromisoformat(str(t).replace("Z", "+00:00")).timestamp()
    except Exception: return None

reacts = [r for r in load(REACT) if (ts_of(r) or 0) >= cut]
owner = [r for r in reacts if not str(r.get("prompt_head", "")).lstrip().startswith(MACHINE)]
cron = len(reacts) - len(owner)
flagged = [r for r in owner if r.get("flags")]
print(f"reactions in the last {days} days: {len(reacts)} rows, {cron} cron wakes excluded, {len(owner)} owner prompts")
if owner:
    print(f"P6 flag rate: {len(flagged)} of {len(owner)} owner reactions carried a friction flag ({100 * len(flagged) // len(owner)}%)")
    for r in flagged:
        print(f"   {int(r.get('seconds_since_render', 0)):5d}s  {','.join(r['flags']):14}  {str(r.get('prompt_head', ''))[:70]!r}")
else:
    print("P6 flag rate: no owner reactions in the window")

gates = [g for g in load(GATE) if (ts_of(g) or 0) >= cut]
by_sid = {}
for g in gates: by_sid.setdefault(g.get("sid"), []).append((ts_of(g), g))
for v in by_sid.values(): v.sort(key=lambda x: x[0] or 0)
joined = []
for r in owner:
    rt = ts_of(r); rows = by_sid.get(r.get("sid8"), [])
    prev = None
    for gt, g in rows:
        if gt is not None and gt <= rt: prev = g
        else: break
    if prev is not None and rt - (ts_of(prev) or 0) <= 3600: joined.append((r, prev))
print(f"P8 join: {len(joined)} of {len(owner)} owner reactions have a counter-gate row for the reply before them (same session, within 1h)")
if joined:
    b_f = sum(1 for r, g in joined if g.get("breach") and r.get("flags"))
    b_n = sum(1 for r, g in joined if g.get("breach") and not r.get("flags"))
    n_f = sum(1 for r, g in joined if not g.get("breach") and r.get("flags"))
    n_n = sum(1 for r, g in joined if not g.get("breach") and not r.get("flags"))
    print(f"   reply breached the length budget: {b_f} flagged, {b_n} not   ·   inside budget: {n_f} flagged, {n_n} not")
    if b_f + b_n and n_f + n_n:
        print(f"   flag rate after a breach {100 * b_f // (b_f + b_n)}% vs inside budget {100 * n_f // (n_f + n_n)}%")
    for r, g in joined:
        print(f"   {g.get('rchars', 0):6d}c/{g.get('pwords', 0):3d}w breach={str(bool(g.get('breach'))):5} flags={','.join(r.get('flags') or []) or '-':12} {str(r.get('prompt_head', ''))[:50]!r}")
