#!/usr/bin/env python3
"""left: one goal, and what stands between here and met.

Acceptance rows with their evidence state first (that is what "done" means),
then open milestones and their rows, then unread handoff notes, which this view
consumes. With no --goal it takes this session's goal, else refuses with the
list, because "what is left" about the wrong goal is worse than nothing.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _common import G, R, SID, parse, goals_for, emit_json


def main():
    a = parse(__doc__)
    if not a.goal:
        gid = G.session_goal(SID) if SID else None
        if not gid or not G.exists(gid):
            live = G.ids()
            print("left: no --goal and this session points at none. Name one:  /tasks left <goal>", file=sys.stderr)
            for g in live[:8]:
                r = G.load(g); print(f"   {g}  {R.ellip(r['outcome'], 70)}", file=sys.stderr)
            sys.exit(2)
        a.goal = gid
    g = goals_for(a)[0]
    st = R.states_of(g)
    notes = G.unconsumed_notes(g)
    if a.json:
        emit_json(dict(g, effective=st, containment=G.containment(g), notes_unread=notes)); return
    out = R.Out(a.detail)
    out.footer = 2
    d, verdict = G.drift(g)
    out.w(f"LEFT  {R.goal_emoji(g)} {g['id']}  ·  {g['status']}{'' if verdict in ('fresh', g['status']) else ' · ' + verdict}  ·  {R.age(g['updated'])} since last write")
    for ln in R.wrap(g["outcome"], R.BOX_W): out.w(ln)
    if g.get("direction"): out.w("\U0001F9ED " + R.ellip(g["direction"], R.BOX_W - 3))
    out.w("")
    out.w("what accepted means, and what has proved it:")
    for x in g["accept"]:
        mark = "✅" if x["status"] == "proven" else "◻︎"
        ev = f"   · by {x['evidence']}" if x["evidence"] else "   · unproven"
        out.w(f"  {mark} {x['id']} {x['kind']:<11} " + R.ellip(x["text"], R.BOX_W - 40) + R.ellip(ev, 36))
    out.w("")
    open_rows = R.open_rows(g, st)
    idw = max(5, max((len(t["id"]) + 3 for t in g["tasks"]), default=5))
    traitws = R.trait_widths(open_rows)
    if open_rows:
        R.goal_box(out, g, st, idw, traitws, title=False)
    else:
        out.w("every row is done" if g["tasks"] else "no rows yet")
    c = G.containment(g)
    out.w("")
    if not c:
        out.w("MAY CLOSE: nothing stands between here and met   ·   gs met " + g["id"][:6] + " --by \"<what proved it>\"")
    else:
        out.w("to met: " + R.ellip(" · ".join(c), R.BOX_W - 8))
    if notes:
        out.w("")
        for n in notes:
            out.w(R.ellip(f"📝 {n['on']}: {n['text']}   ({n['created'][:10]})", R.BOX_W))
        G.consume_notes(g); G.save(g)
    R.hidden_line(out)
    states_used = {st[t["id"]] for t in open_rows}
    R.legend(out, states_used, traitws_used=bool(open_rows))
    print("\n".join(out.lines))


if __name__ == "__main__":
    main()
