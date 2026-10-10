#!/usr/bin/env python3
"""drift: what is stale, false, or off-goal, so the owner never reads a wrong row as a live one.

Findings, each with the ids to act on:
  goals idle 14 days (drifting) or 30 (park due), and parked goals
  gates untouched over a day, and gates set before the owner's last decision-page ruling
  goals whose rows are all done while acceptance is unproven (built, not accepted)
  agent session rows under no goal, for the sessions this scope's goals know about
  milestones named too thin, running rows in a lane no live session claims
  handoff notes nobody has read
Nothing here is a row to do; every line names the goal and the command that clears it.
"""
import calendar, json, os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _common import G, R, SID, parse, goals_for, scope_text, emit_json

STALE_GATE_S = 24 * 3600
HOUSE_LANES = {"main", "owner", "gcc", "hands", "brains"}


def _iso(s):
    try: return calendar.timegm(time.strptime(s or "", "%Y-%m-%dT%H:%M:%SZ"))
    except ValueError: return None


def last_ruling():
    p = os.environ.get("TASKS_RULINGS_JSONL") or os.path.expanduser("~/.claude/assets/decision-pages/answers.jsonl")
    best = None
    try:
        for line in open(p):
            try: r = json.loads(line)
            except ValueError: continue
            t = _iso(r.get("ts"))
            if t and (best is None or t > best[0]): best = (t, r.get("slug", "?"))
    except OSError: return None
    return best


def live_aliases():
    """Lanes a live session claims, from the ipc broker; None when there is no instrument."""
    stub = os.environ.get("TASKS_PEERS_JSON")
    try:
        raw = open(stub).read() if stub else subprocess.run(["claude-ipc", "peers"], capture_output=True, text=True, timeout=3).stdout
        return {str(p.get("alias", "")).lower() for p in json.loads(raw).get("peers", []) if p.get("status") != "offline"}
    except Exception: return None


def unfiled_session_rows(goals):
    """Open rows in the agent stores of sessions these goals know, not adopted by any goal."""
    tasks_root = os.path.join(os.path.expanduser("~"), ".claude", "tasks")
    adopted = {t.get("adopted_from") for g in goals for t in g["tasks"] if t.get("adopted_from")}
    out = []
    sids = {s[:8] for g in goals for s in g["sessions"]}
    for s8 in sorted(sids):
        d = os.path.join(tasks_root, f"session-{s8}")
        if not os.path.isdir(d): continue
        n = 0
        for f in os.listdir(d):
            if not f.endswith(".json") or not f[0].isdigit(): continue
            try: j = json.load(open(os.path.join(d, f)))
            except Exception: continue
            if j.get("status") != "completed" and f"session-{s8}#{j.get('id')}" not in adopted: n += 1
        if n: out.append((s8, n))
    return out


def main():
    a = parse(__doc__)
    goals = goals_for(a)
    now = time.time()
    st = {g["id"]: R.states_of(g) for g in goals}
    f = []   # (severity, line, json)
    for g in goals:
        d, v = G.drift(g)
        if v in ("drifting", "park-due", "parked"):
            f.append((1, f"  ⏳ {v:<9} {g['id'][:6]}  idle {int(d)}d  “{R.ellip(g['outcome'], 50)}”   ·   gs revive|park|drop {g['id'][:6]}", {"kind": v, "goal": g["id"], "idle_days": int(d)}))
        if g["status"] == "live" and g["tasks"] and not R.open_rows(g, st[g["id"]]) and any(x["status"] != "proven" for x in g["accept"]):
            f.append((0, f"  🟡 built, not accepted  {g['id'][:6]}  “{R.ellip(g['outcome'], 44)}”   ·   gs prove {g['id'][:6]} <aN> --by …", {"kind": "built-not-accepted", "goal": g["id"]}))
        for t in g["tasks"]:
            if st[g["id"]][t["id"]] == "owner-gate":
                ts = _iso(t["updated"]) or now
                if now - ts > STALE_GATE_S:
                    f.append((0, f"  🔴 gate untouched {R.age(t['updated'])}  #{t['id']}·{g['id'][:6]}  {R.ellip(t['subject'], 44)}   ·   re-check, then gs ungate or close", {"kind": "stale-gate", "goal": g["id"], "id": t["id"]}))
        for m in g["milestones"]:
            if len([c for c in m["name"] if c.isalpha()]) < 3:
                f.append((2, f"  ⚠ milestone name too thin  {m['id']}·{g['id'][:6]} “{m['name']}”", {"kind": "thin-milestone", "goal": g["id"], "id": m["id"]}))
        un = G.unconsumed_notes(g)
        if un:
            f.append((2, f"  📝 {len(un)} handoff note(s) unread  {g['id'][:6]}   ·   gs notes {g['id'][:6]}", {"kind": "unread-notes", "goal": g["id"], "n": len(un)}))
    ruling = last_ruling()
    if ruling:
        pre = [(g, t) for g in goals for t in g["tasks"] if st[g["id"]][t["id"]] == "owner-gate" and (_iso(t["updated"]) or now) < ruling[0]]
        if pre:
            f.append((0, f"  🔴 {len(pre)} gate(s) set before your last ruling ({ruling[1]}); re-derive before treating as open: " + " ".join(f"#{t['id']}·{g['id'][:6]}" for g, t in pre[:6]), {"kind": "gate-predates-ruling", "ids": [f"{g['id']}#{t['id']}" for g, t in pre]}))
    running = [(g, t) for g in goals for t in g["tasks"] if st[g["id"]][t["id"]] == "active"]
    aliases = live_aliases() if running else None
    if aliases is not None:
        orphan = [(g, t) for g, t in running if t.get("lane") and t["lane"].lower() not in HOUSE_LANES and not any(t["lane"].lower() in al for al in aliases)]
        if orphan:
            f.append((1, "  🔵 running in a lane no live session claims: " + " · ".join(f"{t['lane']} #{t['id']}·{g['id'][:6]}" for g, t in orphan[:5]) + "   ·   gs ready or gs delegate", {"kind": "orphan-lane", "ids": [f"{g['id']}#{t['id']}" for g, t in orphan]}))
    for s8, n in unfiled_session_rows(goals):
        f.append((2, f"  ⚪ {n} open agent row(s) in session-{s8} under no goal   ·   gs adopt <goal> <mN> --session {s8}, or leave them: they are the agent's", {"kind": "unfiled-session-rows", "session": s8, "n": n}))
    f.sort(key=lambda x: x[0])
    if a.json:
        emit_json({"scope": scope_text(a, goals), "findings": [x[2] for x in f]}); return
    if not f:
        print(f"nothing drifting  ·  {scope_text(a, goals)}"); return
    print(f"DRIFT  {len(f)} finding(s)  ·  {scope_text(a, goals)}")
    for _, line, _ in f: print(line)


if __name__ == "__main__":
    main()
