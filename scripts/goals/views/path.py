#!/usr/bin/env python3
"""path: is each live goal converging, and on what.

The ruled table: header, CLEAR NOW (every owner gate, capped at three), then one
goal box per goal with its milestone meter, its acceptance meter, its milestone
bands and rows. Height within 44 lines; past that it truncates loudly.
"""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _common import G, R, SID, parse, goals_for, scope_text, armed_text, armed_state, emit_json


def quiet_main(a, goals):
    """The quiet style: one glyph per row, no rails, one line per row when it fits."""
    out = R.Out(a.detail)
    st = {g["id"]: R.states_of(g) for g in goals}
    gates = [(g, t) for g in goals for t in R.gates_of(g, st[g["id"]])]
    running = sum(1 for g in goals for t in g["tasks"] if st[g["id"]][t["id"]] == "active")
    ms_t = sum(len(g["milestones"]) for g in goals); ms_c = sum(R.milestones_closed(g, st[g["id"]]) for g in goals)
    acc_t = sum(len(g["accept"]) for g in goals); acc_p = sum(1 for g in goals for x in g["accept"] if x["status"] == "proven")
    armed, label = armed_state()
    arm_word = "armed" if "armed, on" in label else ("linked, not armed" if armed else "no goal")
    out.w(R.dljust(f"TASKS  {len(goals)} goal{'s' if len(goals) != 1 else ''} · milestones {ms_c}/{ms_t} · accepted {acc_p}/{acc_t} · running {running} · needs you {len(gates)}", R.BOX_W - len(arm_word) - 2) + arm_word)
    out.w("  " + scope_text(a, goals))
    if armed:
        for ln in R.wrap("/goal " + armed, R.BOX_W): out.w(ln)
    drifting = [g for g in goals if G.drift(g)[1] in ("drifting", "park-due")]
    built = [g for g in goals if g["status"] == "live" and g["tasks"] and not R.open_rows(g, st[g["id"]]) and any(x["status"] != "proven" for x in g["accept"])]
    unread = sum(len(G.unconsumed_notes(g)) for g in goals)
    flags = ([f"built, not accepted: {len(built)}"] if built else []) + ([f"drifting: {len(drifting)}"] if drifting else []) + ([f"unread notes: {unread}"] if unread else [])
    if flags: out.w("  !! " + "  ·  ".join(flags))
    idw = max(3, max((len(t["id"]) + 1 for g in goals for t in g["tasks"]), default=3))
    trait_col = min(R.BOX_W - 30, 78)
    out.footer = 2
    if gates:
        out.w("")
        out.w(f"NEEDS YOU  {len(gates)}")
        for g, t in gates[:3]:
            out.w("    ! " + R.dljust(f"#{t['id']}", idw) + " " + R.ellip(t["subject"], R.BOX_W - idw - 8) + (f"   ({g['id'][:6]})" if len(goals) > 1 else ""))
            out.w(" " * (idw + 7) + "do: " + R.ellip(t["gate"]["do"], R.BOX_W - idw - 11))
        if len(gates) > 3: out.w(f"    +{len(gates) - 3} more, --detail lists them")
    states_used = set()
    for g in sorted(goals, key=lambda g: (0 if any(st[g["id"]][t["id"]] == "owner-gate" for t in g["tasks"]) else 1, g["updated"])):
        out.w("")
        R.quiet_goal(out, g, st[g["id"]], idw, trait_col, tag=f"·{g['id'][:6]}" if len(goals) > 1 else "")
        states_used |= {st[g["id"]][t["id"]] for t in g["tasks"] if st[g["id"]][t["id"]] != "done"}
    R.hidden_line(out)
    done_n = sum(1 for g in goals for t in g["tasks"] if st[g["id"]][t["id"]] == "done")
    R.quiet_legend(out, states_used, extra=f"{done_n} done" if done_n else "")
    print("\n".join(out.lines))


def editorial_main(a, goals):
    """The editorial render (2026-09-24 night): a briefing a person reads top to bottom."""
    out = R.Out(a.detail)
    st = {g["id"]: R.states_of(g) for g in goals}
    out.w(R.editorial_header(goals, st) + "   " + scope_text(a, goals).replace("scope: ", ""))
    order = {"waiting on you": 0, "drifting": 1, "moving": 2, "waiting on others": 3, "not started": 4, "met": 5, "parked": 6}
    armed, label = armed_state()
    paste = 0 if (not armed or "armed, on" in label) else len(R.wrap("/goal " + armed, R.BOX_W)) + 1
    out.footer = paste
    for g in sorted(goals, key=lambda g: (order.get(R.goal_state(g, st[g["id"]]), 9), g["updated"])):
        out.w("")
        R.editorial_card(out, g, st[g["id"]])
    if paste:
        out.w("")
        for ln in R.wrap("/goal " + armed, R.BOX_W): out.w(ln)
    if len(out.lines) > R.HEIGHT and not a.detail:
        keep = out.lines[:R.HEIGHT - 1]
        keep.append(f"  … {len(out.lines) - R.HEIGHT + 1} more lines; /tasks left <goal> or --detail")
        out.lines = keep
    print("\n".join(out.lines))


def state_main(a, goals):
    """State-first cards (2026-09-24 evening): each goal leads with its state and its ask."""
    out = R.Out(a.detail)
    st = {g["id"]: R.states_of(g) for g in goals}
    out.w(R.state_header(goals, st))
    out.w("  " + scope_text(a, goals))
    order = {"waiting on you": 0, "drifting": 1, "moving": 2, "waiting on others": 3, "not started": 4, "met": 5, "parked": 6}
    armed, label = armed_state()
    paste = 0 if (not armed or "armed, on" in label) else len(R.wrap("/goal " + armed, R.BOX_W)) + 2
    out.footer = 1 + paste
    ordered = sorted(goals, key=lambda g: (order.get(R.goal_state(g, st[g["id"]]), 9), g["updated"]))
    for i, g in enumerate(ordered):
        out.w("")
        share = max(3, (out.cap() - len(out.lines)) // (len(ordered) - i) - 6)
        R.state_card(out, g, st[g["id"]], share=share)
    body = "\n".join(out.lines)
    glyphs = [f"{R.STOP_GLYPH[s]} {R.STOP_WORD[s]}" for s in ("you", "seat", "peer", "closure") if R.STOP_GLYPH[s] + " " in body]
    glyphs += [f"{R.TWIN[s]} {R.LEGEND_NAME[s]}" for s in ("active", "ready", "blocked", "deferred") if " " + R.TWIN[s] + " #" in body]
    if paste:
        out.w("")
        for ln in R.wrap("/goal " + armed, R.BOX_W): out.w(ln)
        out.w("  (paste the line above to arm the Stop hook; the record is linked, the hook is not)")
    out.w("  " + "   ".join(glyphs + [f"height {len(out.lines) + 1}/{R.HEIGHT}"]))
    print("\n".join(out.lines))


def card_main(a, goals):
    """Cards: the default since the two rulings of 2026-09-24."""
    out = R.Out(a.detail)
    st = {g["id"]: R.states_of(g) for g in goals}
    stops = [(g, t) for g in goals for t in g["tasks"] if G.stop_of(t, g)]
    done_n = sum(1 for g in goals for t in g["tasks"] if st[g["id"]][t["id"]] == "done")
    total = sum(len(g["tasks"]) for g in goals)
    acc_t = sum(len(g["accept"]) for g in goals); acc_p = sum(1 for g in goals for x in g["accept"] if x["status"] == "proven")
    armed, label = armed_state()
    arm_word = "armed" if "armed, on" in label else ("linked, not armed" if armed else "no goal")
    out.w(R.dljust(f"TASKS  {len(goals)} goal{'s' if len(goals) != 1 else ''} · rows {done_n}/{total} done · accepted {acc_p}/{acc_t} · stops {len(stops)}", R.BOX_W - len(arm_word) - 2) + arm_word)
    out.w("  " + scope_text(a, goals))
    if armed:
        for ln in R.wrap("/goal " + armed, R.BOX_W): out.w(ln)
    drifting = [g for g in goals if G.drift(g)[1] in ("drifting", "park-due")]
    if drifting: out.w("  !! drifting: " + " · ".join(f"{g['id'][:6]} idle {int(G.drift(g)[0])}d" for g in drifting[:4]))
    out.footer = 1
    stops_used = set()
    # The goal holding your gate first, then the freshest; every card gets a fair
    # share of the height so one sixty-row goal cannot starve the others.
    ordered = sorted(goals, key=lambda g: g["updated"], reverse=True)
    ordered.sort(key=lambda g: 0 if any(G.stop_of(t, g) == "you" for t in g["tasks"] if st[g["id"]][t["id"]] != "done") else 1)
    for i, g in enumerate(ordered):
        out.w("")
        remaining = len(ordered) - i
        share = max(4, (out.cap() - len(out.lines)) // remaining - 5)
        R.card(out, g, st[g["id"]], tag=f"·{g['id'][:6]}" if len(goals) > 1 else "", share=share)
        stops_used |= {G.stop_of(t, g) for t in g["tasks"] if G.stop_of(t, g)}
        if not R.open_rows(g, st[g["id"]]) and any(x["status"] != "proven" for x in g["accept"]): stops_used.add("you")
    R.hidden_line(out)
    R.card_legend(out, stops_used)
    print("\n".join(out.lines))


def main():
    # Cards are the default (rulings of 2026-09-24); --quiet is the 09-23 flat style,
    # --boxed the 09-05 rail-and-ball shape.
    style = "editorial"
    for flag in ("--boxed", "--quiet", "--cards", "--state", "--editorial"):
        if flag in sys.argv: style = flag[2:]; sys.argv.remove(flag)
    style = os.environ.get("TASKS_STYLE", style)
    a = parse(__doc__)
    goals = goals_for(a)
    if style == "editorial" and goals and not a.json:
        editorial_main(a, goals); return
    if style == "state" and goals and not a.json:
        state_main(a, goals); return
    if style == "cards" and goals and not a.json:
        card_main(a, goals); return
    if style == "quiet" and goals and not a.json:
        quiet_main(a, goals); return
    if a.json:
        emit_json({"scope": scope_text(a, goals), "armed": armed_text(),
                   "goals": [dict(g, effective=R.states_of(g), containment=G.containment(g)) for g in goals]})
        return
    out = R.Out(a.detail)
    if not goals:
        print("no live goal here. Start one:  gs new \"<outcome>\" --accept \"functional: <what you will check>\"")
        return
    st = {g["id"]: R.states_of(g) for g in goals}
    gates = [(g, t) for g in goals for t in R.gates_of(g, st[g["id"]])]
    running = [t for g in goals for t in g["tasks"] if st[g["id"]][t["id"]] == "active"]
    met_n = sum(1 for g in goals if g["status"] == "met")
    parked = sum(1 for g in goals if g["status"] == "parked")
    ms_t = sum(len(g["milestones"]) for g in goals)
    ms_c = sum(R.milestones_closed(g, st[g["id"]]) for g in goals)
    acc_t = sum(len(g["accept"]) for g in goals); acc_p = sum(1 for g in goals for x in g["accept"] if x["status"] == "proven")
    armed, label = armed_state()
    head = "TASKS  path  ·  " + label
    head += f"  ·  \U0001F7E2 {len(goals)} goal{'s' if len(goals) != 1 else ''}, {met_n} met" + (f", {parked} parked" if parked else "")
    head += f"  ·  \U0001F3C1 {ms_c} of {ms_t} milestones  ·  ✅ {acc_p} of {acc_t} accepted"
    if gates: head += f"  ·  \U0001F534 {len(gates)} need you"
    head += f"  ·  {len(running)} running"
    out.w(head)
    out.w("  " + scope_text(a, goals))
    if armed:
        for ln in R.wrap("/goal " + armed, R.BOX_W): out.w(ln)
    drifting = [g for g in goals if G.drift(g)[1] in ("drifting", "park-due")]
    built = [g for g in goals if g["status"] == "live" and not R.open_rows(g, st[g["id"]]) and any(x["status"] != "proven" for x in g["accept"])]
    bangs = []
    if built: bangs.append("  !! built, not accepted: " + " · ".join(f"{g['id'][:6]} “{R.ellip(g['outcome'], 40)}”" for g in built[:3]) + "   ·   prove the acceptance rows or the goal cannot be met")
    if drifting: bangs.append("  !! drifting: " + " · ".join(f"{g['id'][:6]} idle {int(G.drift(g)[0])}d" for g in drifting[:4]) + "   ·   /tasks drift")
    unconsumed = sum(len(G.unconsumed_notes(g)) for g in goals)
    if unconsumed: bangs.append(f"  📝 {unconsumed} handoff note(s) unread   ·   gs notes <goal>")
    if bangs:
        out.w(bangs[0] + (f"   ·   +{len(bangs) - 1} more in --detail" if len(bangs) > 1 and not a.detail else ""))
        if a.detail:
            for b in bangs[1:]: out.w(b)
    idw = max(5, max((len(t["id"]) + 3 for g in goals for t in g["tasks"]), default=5))
    multi = len(goals) > 1
    traitws = R.trait_widths([t for g in goals for t in g["tasks"] if st[g["id"]][t["id"]] != "done"])
    out.footer = 4
    states_used = set()
    # CLEAR NOW
    if gates:
        gn = len({g["id"] for g, _ in gates})
        shown = gates[:3]
        if out.fits(2 + 2 * len(shown)):
            out.w("")
            out.w(f"⚡ CLEAR NOW   {len(shown)} of {len(gates)} waiting on you, across {gn} goal{'s' if gn != 1 else ''}")
            cw = idw + (7 if multi else 0)
            for i, (g, t) in enumerate(shown, 1):
                tag = f"·{g['id'][:6]}" if multi else ""
                out.w(f"   {i}  " + R.dljust(f"#{t['id']}{tag}", cw) + " " + R.ellip(t["subject"], R.BOX_W - R.ID_COL - cw))
                out.w(" " * (R.ID_COL + cw) + "▸ do    " + R.ellip(t["gate"]["do"], R.BOX_W - R.ID_COL - cw - 8))
            if len(gates) > 3 and out.fits(1):
                out.w(f"      +{len(gates) - 3} more waiting on you, held so this reads as a sitting; --detail lists them")
    # Boxes: the one holding a gate first, then by freshness.
    def key(g):
        has_gate = any(st[g["id"]][t["id"]] == "owner-gate" for t in g["tasks"])
        return (0 if has_gate else 1, g["updated"])
    for g in sorted(goals, key=key):
        out.w("")
        tag = f"·{g['id'][:6]}" if multi else ""
        R.goal_box(out, g, st[g["id"]], idw, traitws, tag=tag)
        states_used |= {st[g["id"]][t["id"]] for t in g["tasks"] if st[g["id"]][t["id"]] != "done"}
    R.hidden_line(out)
    done_n = sum(1 for g in goals for t in g["tasks"] if st[g["id"]][t["id"]] == "done")
    R.legend(out, states_used, extra=f"{done_n} done, ids in --json" if done_n else "")
    print("\n".join(out.lines))


if __name__ == "__main__":
    main()
