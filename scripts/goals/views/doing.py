#!/usr/bin/env python3
"""doing: what is moving right now, and who holds it.

Per goal: running rows with their lane and the session that filed them, rows
handed to seats (delegated), rows held in review. Sessions the goal knows are
listed with whether the ipc broker sees them live, so a "running" row in a dead
session reads as the tombstone it is.
"""
import json, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _common import G, R, SID, parse, goals_for, scope_text, emit_json


def live_sessions():
    stub = os.environ.get("TASKS_PEERS_JSON")
    try:
        raw = open(stub).read() if stub else subprocess.run(["claude-ipc", "peers"], capture_output=True, text=True, timeout=3).stdout
        return {str(p.get("sessionId", ""))[:8]: p.get("alias", "") for p in json.loads(raw).get("peers", []) if p.get("status") != "offline"}
    except Exception: return None


def main():
    a = parse(__doc__)
    goals = goals_for(a)
    st = {g["id"]: R.states_of(g) for g in goals}
    live = live_sessions()
    moving = []
    for g in goals:
        for t in g["tasks"]:
            s = st[g["id"]][t["id"]]
            if s in ("active", "delegated", "review"):
                s8 = (t.get("session") or "")[:8]
                alive = None if live is None else (s8 in live)
                moving.append({"goal": g["id"], "outcome": g["outcome"], "id": t["id"], "subject": t["subject"], "state": s,
                               "lane": t.get("lane"), "tier": t.get("tier"), "session": s8, "session_live": alive,
                               "delegated_to": t.get("delegated_to"), "age": R.age(t["updated"])})
    if a.json:
        emit_json({"scope": scope_text(a, goals), "moving": moving}); return
    if not moving:
        print(f"nothing is moving  ·  {scope_text(a, goals)}"); return
    n_run = sum(1 for m in moving if m["state"] == "active")
    print(f"DOING  {n_run} running, {sum(1 for m in moving if m['state'] == 'delegated')} delegated, {sum(1 for m in moving if m['state'] == 'review')} in review  ·  {scope_text(a, goals)}")
    cur = None
    for m in sorted(moving, key=lambda m: (m["goal"], {"active": 0, "delegated": 1, "review": 2}[m["state"]], int(m["id"]))):
        if m["goal"] != cur:
            cur = m["goal"]; g = next(x for x in goals if x["id"] == cur)
            print(f"\n{R.goal_emoji(g)}  {R.ellip(m['outcome'], R.BOX_W - 12)}   ·   {cur[:6]}")
        who = m["delegated_to"] or m["lane"] or "no lane"
        sess = m["session"] or "?"
        tomb = "" if m["session_live"] is None else ("" if m["session_live"] else "  ⚠ its session is not live: a tombstone")
        print(f"   {R.BALL[m['state']]} {R.TWIN[m['state']]} #{m['id']:<4} {R.ellip(m['subject'], 56):<56}  ◆ {who:<10} ◇ {m['tier'] or '—':<6} session {sess}  {m['age']}{tomb}")
    if live is None:
        print("\n  (no ipc broker answered, so session liveness is not shown)")


if __name__ == "__main__":
    main()
