#!/usr/bin/env python3
"""queue-run: work a goal's rows one after another without fixating or halting early.

The queue is the session's goal record (rows under milestones). This hands the
agent one row at a time, keeps a per-row budget so a stuck row is parked with a
reason instead of eating the run, and collects everything only the owner can
clear into one list for one decision page at the end. Called through
queue-run.sh; the Stop hook queue-stop.sh and session-state.sh read `ready`.

  queue-run.sh on [--goal G]          start a drive on this session's linked goal (or G); also opts into compaction
  queue-run.sh off                    stop the drive; restores the compaction gate if `on` changed it
  queue-run.sh status                 goal, on/off, the row in hand with its budget, counts
  queue-run.sh next                   the row to work now (starts it, or counts another attempt on it)
  queue-run.sh park <id> --why "…"    defer the row, note what blocked it and where the evidence is
  queue-run.sh ready                  every agent-ready row, the one in hand first; exit 1 when none
  queue-run.sh gates [--json]         owner-gated rows, owner-checked acceptance rows, parked rows
Common flags: --sid S (default CLAUDE_CODE_SESSION_ID), --goal G (default the drive's goal, else the linked one).
Exit: 0 ok · 1 nothing agent-ready · 2 refused or usage · 4 the row in hand spent its budget (park it).
"""
import argparse, calendar, json, os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import goalstore as G

BUDGET_ATTEMPTS, BUDGET_MINUTES = 2, 30  # per row before it is parked (owner ruling queue-1015 Q2)

RUNS = os.path.join(G.ROOT, "runs")
ACTIVE = os.path.join(RUNS, "active")
COMPACT_GATE = os.path.join(os.path.expanduser("~"), ".claude", "scripts", "session-mgmt", "compact-gate.sh")
OWNER_CHECKED = ("visual", "reviewed", "other")  # acceptance kinds only the owner can prove; same split as the gcc-mods band


def die(msg, code=2):
    print(f"queue-run: {msg}", file=sys.stderr); sys.exit(code)


def ledger_path(gid):
    return os.path.join(RUNS, f"{gid}.jsonl")


def ledger(gid):
    p = ledger_path(gid)
    if not os.path.exists(p): return []
    out = []
    for line in open(p):
        try: out.append(json.loads(line))
        except ValueError: pass
    return out


def log(gid, ev, sid, **kw):
    os.makedirs(RUNS, exist_ok=True)
    row = {"ts": G.now(), "ev": ev, "sid": sid or None}
    row.update(kw)
    with open(ledger_path(gid), "a") as f: f.write(json.dumps(row, ensure_ascii=False) + "\n")


def active_path(sid):
    return os.path.join(ACTIVE, f"{sid}.json")


def drive_of(sid):
    p = active_path(sid) if sid else None
    if not p or not os.path.exists(p): return None
    try: return json.load(open(p))
    except ValueError: return None


def goal_for(a):
    """The drive's goal, else the goal this session is linked to. Never a guess."""
    ref = a.goal or (drive_of(a.sid) or {}).get("goal") or (G.session_goal(a.sid) if a.sid else None)
    if not ref:
        live = G.ids()
        die("no goal: this session is linked to none and no --goal was named. Name the goal the owner gave you "
            f"(--goal <id>); live goals: {', '.join(live) or 'none'}")
    try: return G.load(G.resolve(ref))
    except G.GoalError as e: die(str(e))


def _ts(s):
    # Ledger stamps are UTC; timegm reads them as UTC (mktime would read them as local time).
    return calendar.timegm(time.strptime(s, "%Y-%m-%dT%H:%M:%SZ"))


def row_history(events, tid):
    """Events for one row since it last left the runner's hands (closed or parked ends a stint)."""
    return [e for e in events if e.get("id") == tid]


def in_hand(rec, events):
    """The row the runner last started and that is still open, with its attempts and minutes so far."""
    starts = [e for e in events if e["ev"] in ("start", "retry")]
    if not starts: return None
    tid = starts[-1]["id"]
    t = next((x for x in rec["tasks"] if x["id"] == tid), None)
    if not t: return None
    st = G.effective_state(t, rec)
    if st not in ("ready", "active"): return None
    hist = row_history(events, tid)
    since = max(i for i, e in enumerate(hist) if e["ev"] in ("start", "retry"))
    stint = hist[since:]
    if any(e["ev"] == "park" for e in stint): return None
    attempts = len([e for e in stint if e["ev"] in ("start", "retry", "attempt")])
    minutes = (time.time() - _ts(stint[0]["ts"])) / 60
    return {"task": t, "attempts": attempts, "minutes": minutes}


def parks(events, tid):
    return [e for e in events if e.get("id") == tid and e["ev"] == "park"]


def retry_eligible(rec, events):
    """Parked rows get one more try after everything else: parked once by the runner, not retried since."""
    out = []
    for t in rec["tasks"]:
        if G.effective_state(t, rec) != "deferred": continue
        p = parks(events, t["id"])
        r = [e for e in events if e.get("id") == t["id"] and e["ev"] == "retry"]
        if len(p) == 1 and not r: out.append(t)
    return out


def ms_order(rec):
    return {m["id"]: m.get("order", i) for i, m in enumerate(rec["milestones"])}


def ready_rows(rec):
    """Rows the agent can take now: no gate, nothing open in front of them, not parked or handed off."""
    order = ms_order(rec)
    rows = [t for t in rec["tasks"] if G.effective_state(t, rec) in ("ready", "active")]
    rows.sort(key=lambda t: (order.get(t["milestone"], 99), int(t["id"])))
    gated = [t for t in rec["tasks"] if G.effective_state(t, rec) == "owner-gate"]
    if gated:
        # While the owner waits on something, a row that stands in front of a gate goes first.
        unblocks = {b for g in gated for b in g.get("blocked_by", [])}
        rows.sort(key=lambda t: 0 if t["id"] in unblocks else 1)
    return rows


def agent_ready(rec, events):
    """The whole agent-ready set in work order: the row in hand, ready rows, then one-time retries."""
    hand = in_hand(rec, events)
    rows = ready_rows(rec)
    if hand:
        rows = [hand["task"]] + [t for t in rows if t["id"] != hand["task"]["id"]]
    return rows + [t for t in retry_eligible(rec, events) if t not in rows]


def line(t, extra=""):
    return f"#{t['id']} {t['subject']}{extra}"


# commands

def cmd_on(a):
    if not a.sid: die("no session id (pass --sid or set CLAUDE_CODE_SESSION_ID)", 2)
    rec = goal_for(a)
    if rec.get("_archived") or rec["status"] != "live":
        die(f"goal {rec['id']} is {rec['status']}; a drive runs on a live goal")
    os.makedirs(ACTIVE, exist_ok=True)
    gate_was = ""
    if os.path.exists(COMPACT_GATE):
        r = subprocess.run(["bash", COMPACT_GATE, "status"], capture_output=True, text=True)
        gate_was = r.stdout.strip()
        if gate_was != "allowed":
            subprocess.run(["bash", COMPACT_GATE, "on"], capture_output=True, text=True)
    prior = drive_of(a.sid) or {}
    j = {"goal": rec["id"], "sid": a.sid, "since": prior.get("since") or G.now(),
         "compact_gate_was": prior.get("compact_gate_was", gate_was)}
    with open(active_path(a.sid), "w") as f: json.dump(j, f)
    log(rec["id"], "on", a.sid)
    n = len(agent_ready(rec, ledger(rec["id"])))
    print(f"drive on · goal {rec['id']} “{rec['outcome'][:60]}” · {n} agent-ready row(s) · "
          f"budget {BUDGET_ATTEMPTS} attempts or {BUDGET_MINUTES} min per row · compaction allowed for this session")
    print("next: queue-run.sh next")


def cmd_off(a):
    d = drive_of(a.sid) if a.sid else None
    if not d: print("no drive on in this session"); return
    if d.get("compact_gate_was") == "refused" and os.path.exists(COMPACT_GATE):
        subprocess.run(["bash", COMPACT_GATE, "off"], capture_output=True, text=True)
    subprocess.run(["trash", active_path(a.sid)], capture_output=True)
    if os.path.exists(active_path(a.sid)): die(f"could not remove {active_path(a.sid)}; the drive is still on")
    log(d["goal"], "off", a.sid)
    print(f"drive off · goal {d['goal']}")


def cmd_status(a):
    rec = goal_for(a); ev = ledger(rec["id"])
    d = drive_of(a.sid) if a.sid else None
    hand = in_hand(rec, ev)
    rows = agent_ready(rec, ev)
    gated = [t for t in rec["tasks"] if G.effective_state(t, rec) == "owner-gate"]
    parked = [t for t in rec["tasks"] if G.effective_state(t, rec) == "deferred"]
    print(f"goal {rec['id']} “{rec['outcome'][:60]}” · drive {'on since ' + d['since'] if d and d['goal'] == rec['id'] else 'off'}")
    if hand:
        print(f"in hand: {line(hand['task'])} · attempt {hand['attempts']} of {BUDGET_ATTEMPTS} · "
              f"{int(hand['minutes'])} of {BUDGET_MINUTES} min")
    print(f"agent-ready {len(rows)} · owner-gated {len(gated)} · parked {len(parked)} · "
          f"open {len([t for t in rec['tasks'] if t['state'] != 'done'])} of {len(rec['tasks'])}")


def cmd_next(a):
    rec = goal_for(a); ev = ledger(rec["id"])
    hand = in_hand(rec, ev)
    if hand:
        t = hand["task"]
        if hand["attempts"] >= BUDGET_ATTEMPTS or hand["minutes"] >= BUDGET_MINUTES:
            print(f"budget spent on {line(t)}: {hand['attempts']} attempt(s), {int(hand['minutes'])} min "
                  f"(budget {BUDGET_ATTEMPTS} attempts or {BUDGET_MINUTES} min). Park it with what blocked it and where the evidence is:\n"
                  f"queue-run.sh park {t['id']} --why \"<what blocked it>; evidence <path>\"")
            sys.exit(4)
        log(rec["id"], "attempt", a.sid, id=t["id"])
        print(line(t, f"   · attempt {hand['attempts'] + 1} of {BUDGET_ATTEMPTS}"))
        return
    rows = ready_rows(rec)
    ev_kind = "start"
    if not rows:
        rows = retry_eligible(rec, ev); ev_kind = "retry"
    if not rows:
        print("nothing agent-ready. Collect the owner's part: queue-run.sh gates"); sys.exit(1)
    t = rows[0]
    try:
        G.set_state(rec, t["id"], "active"); G.save(rec)
    except G.GoalError as e: die(str(e))
    log(rec["id"], ev_kind, a.sid, id=t["id"])
    tail = "   · second pass after a park" if ev_kind == "retry" else ""
    print(line(t, f"{tail}   · attempt 1 of {BUDGET_ATTEMPTS}, {BUDGET_MINUTES} min"))
    if t.get("desc"): print(f"   {t['desc']}")
    if t.get("note"): print(f"   note: {t['note']}")


def cmd_park(a):
    if not (a.why or "").strip(): die("--why is required: what blocked the row and where the evidence is")
    rec = goal_for(a); ev = ledger(rec["id"])
    try:
        t = G._find(rec["tasks"], a.id.lstrip("#"), "task")
        if t["state"] == "done": die(f"#{t['id']} is done; nothing to park")
        hand = in_hand(rec, ev)
        spent = f" after {hand['attempts']} attempt(s), {int(hand['minutes'])} min" if hand and hand["task"]["id"] == t["id"] else ""
        G.set_state(rec, t["id"], "deferred")
        G.add_note(rec, t["id"], f"parked by the queue runner{spent}: {a.why.strip()}", a.sid or None)
        G.save(rec)
    except G.GoalError as e: die(str(e))
    log(rec["id"], "park", a.sid, id=t["id"], why=a.why.strip(), by=a.by)
    print(f"parked {line(t)}{spent}: {a.why.strip()}")
    rows = agent_ready(rec, ledger(rec["id"]))
    print(f"next: {line(rows[0])}" if rows else "nothing agent-ready left. Collect the owner's part: queue-run.sh gates")


def cmd_ready(a):
    rec = goal_for(a); ev = ledger(rec["id"])
    rows = agent_ready(rec, ev)
    retry = {t["id"] for t in retry_eligible(rec, ev)}
    for t in rows: print(line(t, "   · retry after park" if t["id"] in retry else ""))
    sys.exit(0 if rows else 1)


def cmd_gates(a):
    rec = goal_for(a); ev = ledger(rec["id"])
    gated = [t for t in rec["tasks"] if G.effective_state(t, rec) == "owner-gate"]
    accept = [x for x in rec["accept"] if x["status"] != "proven" and x["kind"] in OWNER_CHECKED]
    parked = []
    for t in rec["tasks"]:
        if G.effective_state(t, rec) != "deferred": continue
        p = parks(ev, t["id"])
        # Every park's reason, oldest first: a later backstop park must not hide the agent's evidence.
        parked.append({"id": t["id"], "subject": t["subject"],
                       "why": " · then: ".join(e["why"] for e in p) if p else "deferred outside the runner",
                       "parks": len(p)})
    if a.json:
        print(json.dumps({"goal": rec["id"], "outcome": rec["outcome"],
                          "gated": [{"id": t["id"], "subject": t["subject"], "gate": t["gate"]["text"], "draft": t["gate"]["do"]} for t in gated],
                          "accept": [{"id": x["id"], "kind": x["kind"], "text": x["text"]} for x in accept],
                          "parked": parked}, indent=2, ensure_ascii=False))
        return
    print(f"goal {rec['id']} “{rec['outcome'][:60]}”: what only the owner can clear")
    if not (gated or accept or parked): print("  nothing: every row is done or agent-ready"); return
    for t in gated: print(f"  gated   #{t['id']} {t['subject']}: {t['gate']['text']}  » draft: {t['gate']['do']}")
    for x in accept: print(f"  accept  {x['id']} {x['kind']}: {x['text']}")
    for p in parked: print(f"  parked  #{p['id']} {p['subject']}: {p['why']}")


def main():
    p = argparse.ArgumentParser(prog="queue-run.sh", add_help=False)
    p.add_argument("-h", "--help", action="store_true")
    sub = p.add_subparsers(dest="cmd")
    for name in ("on", "off", "status", "next", "ready", "gates", "park"):
        s = sub.add_parser(name)
        s.add_argument("--sid", default=os.environ.get("CLAUDE_CODE_SESSION_ID", ""))
        s.add_argument("--goal")
        if name == "gates": s.add_argument("--json", action="store_true")
        if name == "park":
            s.add_argument("id"); s.add_argument("--why"); s.add_argument("--by", default="agent")
    a = p.parse_args()
    if a.help or not a.cmd:
        print(__doc__.strip()); sys.exit(0 if a.help else 2)
    {"on": cmd_on, "off": cmd_off, "status": cmd_status, "next": cmd_next, "park": cmd_park,
     "ready": cmd_ready, "gates": cmd_gates}[a.cmd](a)


if __name__ == "__main__":
    main()
