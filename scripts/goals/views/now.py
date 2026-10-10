#!/usr/bin/env python3
"""now: what is gated on the owner, across every goal in scope, with the do-line for each.

Nothing else. A gate without a do-line cannot exist (the store refuses it), so
every row here is something the owner can act on today.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _common import G, R, parse, goals_for, scope_text, emit_json


def main():
    a = parse(__doc__)
    goals = goals_for(a)
    st = {g["id"]: R.states_of(g) for g in goals}
    gates = [(g, t) for g in goals for t in R.gates_of(g, st[g["id"]])]
    if a.json:
        emit_json({"scope": scope_text(a, goals), "gates": [
            {"goal": g["id"], "outcome": g["outcome"], "id": t["id"], "subject": t["subject"],
             "gate": t["gate"], "age": R.age(t["updated"])} for g, t in gates]})
        return
    if not gates:
        print(f"⚡ nothing waits on you  ·  {scope_text(a, goals)}")
        return
    gn = len({g["id"] for g, _ in gates})
    print(f"⚡ CLEAR NOW   {len(gates)} waiting on you, across {gn} goal{'s' if gn != 1 else ''}  ·  {scope_text(a, goals)}")
    idw = max(5, max(len(t["id"]) + 3 for _, t in gates))
    cur = None
    for i, (g, t) in enumerate(gates, 1):
        if g["id"] != cur:
            cur = g["id"]
            print(f"\n{R.goal_emoji(g)}  {R.ellip(g['outcome'], R.BOX_W - 4)}   ·   {g['id'][:6]}")
        stale = "  ⚠ set " + R.age(t["updated"]) + " ago, re-check" if R.age(t["updated"]).endswith("d") else ""
        print(f"   {i}  " + R.dljust(f"#{t['id']}", idw) + " " + R.ellip(t["subject"], R.BOX_W - 20) + stale)
        print(" " * (idw + 6) + "▸ do    " + R.ellip(t["gate"]["do"], R.BOX_W - idw - 14))


if __name__ == "__main__":
    main()
