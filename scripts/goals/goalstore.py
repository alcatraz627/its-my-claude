#!/usr/bin/env python3
"""The goal record: one file per goal, the single source of what is left.

A goal is the outcome the owner armed, what would make them accept it, the
milestones (states) on the way, and the rows under each milestone. Sessions and
projects are attributes of a goal, never the key. This module owns the file
format, the validation, and the lifecycle rules; `gs` and the views call it.

Layout under $HOME/.claude/goals/:
  by-id/<goal_id>.json     the record (this module writes it)
  archive/<goal_id>.json   met and dropped goals, rows travel with them
  <sid>.json               the session pointer goal.sh already writes (read here,
                           written by `link`, so the armed /goal and the record agree)

Design v2, 2026-09-23: assets/reports/20260923-tasks-rebuild/design.md
"""
import hashlib, json, os, re, time, uuid

ROOT = os.path.join(os.environ.get("HOME", os.path.expanduser("~")), ".claude", "goals")
BY_ID = os.path.join(ROOT, "by-id")
ARCHIVE = os.path.join(ROOT, "archive")

GOAL_STATUSES = ["live", "met", "parked", "dropped"]
ACCEPT_KINDS = ["visual", "functional", "deployed", "reviewed", "other"]
# The ruled nine (REDESIGN.md D7a plus delegated), two channels each in the render.
TASK_STATES = ["ready", "active", "blocked", "owner-gate", "review", "deferred",
               "unassigned", "delegated", "done"]
OPEN_STATES = [s for s in TASK_STATES if s != "done"]
TIERS = ["fable", "opus", "sonnet", "haiku", "lm"]
SUBJECT_MAX = 70
DRIFT_DAYS = 14
PARK_DAYS = 30


class GoalError(Exception):
    """A refusal. The message always names the whole acceptable set (owner, 2026-08-20)."""


def now():
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def goal_id(text):
    """Same hash goal.sh uses, so an armed /goal and a record share one id."""
    norm = re.sub(r"\s+", " ", text.lower()).strip()
    return hashlib.sha256(norm.encode()).hexdigest()[:12]


def _ensure_dirs():
    os.makedirs(BY_ID, exist_ok=True)
    os.makedirs(ARCHIVE, exist_ok=True)


def _path(gid, archived=False):
    return os.path.join(ARCHIVE if archived else BY_ID, f"{gid}.json")


def _atomic_write(path, rec):
    tmp = f"{path}.tmp.{os.getpid()}"
    with open(tmp, "w") as f:
        json.dump(rec, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, path)


class locked:
    """A per-record mkdir lock. Held for one write; a dead holder is reaped after 5s."""

    def __init__(self, gid):
        self.d = os.path.join(BY_ID, f".lock-{gid}")

    def __enter__(self):
        _ensure_dirs()
        for _ in range(50):
            try:
                os.mkdir(self.d)
                return self
            except FileExistsError:
                if time.time() - os.path.getmtime(self.d) > 5:
                    try: os.rmdir(self.d)
                    except OSError: pass
                else:
                    time.sleep(0.1)
        raise GoalError(f"lock held over 5s: {self.d}")

    def __exit__(self, *a):
        try: os.rmdir(self.d)
        except OSError: pass


# read

def exists(gid):
    return os.path.exists(_path(gid)) or os.path.exists(_path(gid, True))


def load(gid):
    """The record, wherever it lives. Raises GoalError with the live ids when missing."""
    for archived in (False, True):
        p = _path(gid, archived)
        if os.path.exists(p):
            with open(p) as f:
                rec = json.load(f)
            rec["_archived"] = archived
            return rec
    raise GoalError(f"no goal {gid}. Live goals: {', '.join(ids()) or 'none'}")


def ids(archived=False):
    d = ARCHIVE if archived else BY_ID
    if not os.path.isdir(d): return []
    return sorted(f[:-5] for f in os.listdir(d) if f.endswith(".json"))


def all_goals(include_archived=False):
    out = [load(g) for g in ids()]
    if include_archived:
        out += [load(g) for g in ids(True)]
    return out


def resolve(ref):
    """A goal by full id, unique id prefix, or a unique substring of its outcome."""
    live = ids(); arch = ids(True)
    if ref in live or ref in arch: return ref
    pre = [g for g in live + arch if g.startswith(ref)]
    if len(pre) == 1: return pre[0]
    if len(pre) > 1: raise GoalError(f"'{ref}' matches {len(pre)} goals: {', '.join(pre)}")
    hits = [g for g in live if ref.lower() in load(g)["outcome"].lower()]
    if len(hits) == 1: return hits[0]
    if len(hits) > 1: raise GoalError(f"'{ref}' matches {len(hits)} live goals: {', '.join(hits)}")
    raise GoalError(f"no goal matches '{ref}'. Live goals: {', '.join(live) or 'none'}")


# validate

def _check_subject(s):
    s = re.sub(r"\s+", " ", (s or "")).strip()
    if not s: raise GoalError("a subject is required")
    return s


def cut_subject(s):
    """Over 70 chars, cut at a word; the tail returns for the note (Q5a)."""
    s = _check_subject(s)
    if len(s) <= SUBJECT_MAX: return s, ""
    head = s[:SUBJECT_MAX].rsplit(" ", 1)[0]
    return head, s[len(head):].strip()


def validate(rec):
    """Every rule the store enforces. Raises on the first violation, naming the set."""
    if not rec.get("outcome", "").strip():
        raise GoalError("a goal needs an outcome: the sentence that is true when it is met")
    if rec.get("status") not in GOAL_STATUSES:
        raise GoalError(f"goal status {rec.get('status')!r} not in {GOAL_STATUSES}")
    if not rec.get("accept"):
        raise GoalError(f"a goal needs at least one acceptance row (--accept \"<kind>: <text>\"; kinds {ACCEPT_KINDS}). "
                        "Convergence is measured against what the owner will check, never against row counts.")
    for a in rec["accept"]:
        if a.get("kind") not in ACCEPT_KINDS:
            raise GoalError(f"acceptance kind {a.get('kind')!r} not in {ACCEPT_KINDS}")
        if not a.get("text", "").strip():
            raise GoalError("an acceptance row needs text")
    mids = {m["id"] for m in rec.get("milestones", [])}
    for m in rec.get("milestones", []):
        if not m.get("name", "").strip():
            raise GoalError("a milestone needs a name: a STATE that reads true or false after 'Right now,'")
        if m.get("status") not in ("open", "met"):
            raise GoalError(f"milestone status {m.get('status')!r} not in ['open', 'met']")
    tids = {t["id"] for t in rec.get("tasks", [])}
    for t in rec.get("tasks", []):
        if t.get("milestone") not in mids:
            raise GoalError(f"task #{t.get('id')} names milestone {t.get('milestone')!r}; this goal has {sorted(mids) or 'none'}. "
                            "A task always sits under a milestone (D6a: three levels).")
        if t.get("state") not in TASK_STATES:
            raise GoalError(f"task state {t.get('state')!r} not in {TASK_STATES}")
        if len(t.get("subject", "")) > SUBJECT_MAX:
            raise GoalError(f"task #{t['id']} subject over {SUBJECT_MAX} chars; cut_subject() first")
        g = t.get("gate")
        if g is not None and not (g.get("text", "").strip() and g.get("do", "").strip()):
            raise GoalError(f"task #{t['id']} gate needs both text (\"USER: …\") and a do-line the owner can act on")
        if t.get("tier") and t["tier"] not in TIERS:
            raise GoalError(f"tier {t['tier']!r} not in {TIERS}")
        for b in t.get("blocked_by", []):
            if b not in tids:
                raise GoalError(f"task #{t['id']} blocked by #{b}, which is not in this goal")
    return rec


# write

def save(rec):
    validate(rec)
    rec["updated"] = now()
    archived = rec.pop("_archived", False)
    _ensure_dirs()
    _atomic_write(_path(rec["id"], archived), rec)
    rec["_archived"] = archived
    return rec


def new_goal(outcome, accept, projects=None, direction=None, sid=None, cwd=None):
    """Create, or link to, the record for this outcome. Same text is the same goal."""
    gid = goal_id(outcome)
    if exists(gid):
        rec = load(gid)
        if sid and sid not in rec["sessions"]:
            rec["sessions"].append(sid)
        for p in projects or []:
            if p not in rec["projects"]: rec["projects"].append(p)
        return save(rec), False
    rec = {
        "id": gid, "outcome": re.sub(r"\s+", " ", outcome).strip(), "direction": direction,
        "accept": [], "projects": list(projects or []), "sessions": [sid] if sid else [],
        "status": "live", "created": now(), "updated": now(), "closed": None, "closed_by": None,
        "milestones": [], "tasks": [], "notes": [], "cwd": cwd,
    }
    for a in accept:
        add_accept(rec, a)
    return save(rec), True


def parse_accept(spec):
    """'visual: the page renders the table' → (kind, text). A bare text is kind other."""
    m = re.match(r"^\s*(visual|functional|deployed|reviewed|other)\s*:\s*(.+)$", spec, re.I)
    if m: return m.group(1).lower(), m.group(2).strip()
    return "other", spec.strip()


def _next(prefix, items):
    n = 1 + max((int(re.sub(r"\D", "", x["id"]) or 0) for x in items), default=0)
    return f"{prefix}{n}"


def add_accept(rec, spec):
    kind, text = parse_accept(spec) if isinstance(spec, str) else (spec["kind"], spec["text"])
    if not text: raise GoalError(f"an acceptance row needs text after the kind; kinds {ACCEPT_KINDS}")
    a = {"id": _next("a", rec["accept"]), "kind": kind, "text": text,
         "evidence": None, "status": "open", "proven_at": None, "source": None}
    rec["accept"].append(a)
    return a


def prove(rec, aid, evidence):
    a = _find(rec["accept"], aid, "acceptance row")
    if not evidence.strip():
        raise GoalError("--by names the instrument: the check run, the screenshot, the deploy seen live")
    a.update(evidence=evidence, status="proven", proven_at=now())
    return a


def add_milestone(rec, name, emoji=None):
    name = re.sub(r"\s+", " ", name).strip()
    if len(re.sub(r"[^A-Za-z]", "", name)) < 3:
        raise GoalError("a milestone name needs at least three letters (owner, 2026-09-05)")
    m = {"id": _next("m", rec["milestones"]), "name": name, "status": "open", "emoji": emoji,
         "order": len(rec["milestones"]) + 1, "created": now()}
    rec["milestones"].append(m)
    return m


def add_task(rec, milestone, subject, sid=None, **kw):
    mid = _find(rec["milestones"], milestone, "milestone")["id"]
    head, tail = cut_subject(subject)
    note = kw.pop("note", None)
    if tail: note = f"{tail}{' · ' + note if note else ''}"
    t = {"id": "", "subject": head, "milestone": mid,
         "state": kw.pop("state", "ready"), "gate": None, "blocked_by": [],
         "lane": kw.pop("lane", None), "tier": kw.pop("tier", None), "kind": kw.pop("kind", None), "domain": kw.pop("domain", None),
         "session": sid, "delegated_to": None, "verified": None, "note": note,
         "desc": kw.pop("desc", None), "created": now(), "updated": now(), "closed": None}
    t["id"] = str(1 + max((int(x["id"]) for x in rec["tasks"]), default=0))
    gate = kw.pop("gate", None); do = kw.pop("do", None)
    if gate:
        set_gate(t, gate, do)
    for b in kw.pop("blocked_by", []) or []:
        _find(rec["tasks"], str(b), "task")
        t["blocked_by"].append(str(b))
        if t["state"] == "ready": t["state"] = "blocked"
    if kw: raise GoalError(f"unknown task fields {sorted(kw)}")
    rec["tasks"].append(t)
    return t


def set_gate(t, text, do):
    text = text.strip()
    if not text.upper().startswith("USER:"): text = "USER: " + text
    if not (do or "").strip():
        raise GoalError("a gate needs a do-line: the one thing the owner does to clear it (--do \"…\")")
    t["gate"] = {"text": text, "do": do.strip()}
    t["state"] = "owner-gate"


def set_closure(t, why):
    """Closure pain: the known finalization hassle (a deploy, a migration, a review
    round, a smoke check) between rows done and goal met. Marked, never skipped."""
    if not (why or "").strip():
        raise GoalError("closure pain needs a reason: what the hassle is (deploy, migration, review round, smoke check)")
    t["closure"] = why.strip(); t["updated"] = now()


def clear_closure(t):
    t.pop("closure", None); t["updated"] = now()


def stop_of(t, rec):
    """Who the agent stops for on this row, or None: 'you', 'seat', 'peer', 'closure'."""
    s = effective_state(t, rec)
    if s == "done": return None
    if t.get("gate"): return "you"
    if s == "delegated": return "seat"
    if s == "review": return "peer"
    if t.get("closure"): return "closure"
    return None


def burst_split(rec):
    """Rows the agent takes alone (burst), rows that stop for someone (stop), and rows
    that wait behind a stop (after). A blocked row follows its blockers' segment."""
    states = {t["id"]: effective_state(t, rec) for t in rec["tasks"]}
    open_t = [t for t in rec["tasks"] if states[t["id"]] != "done"]
    seg = {}
    def classify(t, seen=()):
        if t["id"] in seg: return seg[t["id"]]
        if stop_of(t, rec): seg[t["id"]] = "stop"; return "stop"
        if states[t["id"]] == "deferred": seg[t["id"]] = "after"; return "after"
        for b in t.get("blocked_by", []):
            bt = next((x for x in open_t if x["id"] == b), None)
            if bt and bt["id"] not in seen and classify(bt, seen + (t["id"],)) in ("stop", "after"):
                seg[t["id"]] = "after"; return "after"
        seg[t["id"]] = "burst"; return "burst"
    for t in open_t: classify(t)
    return seg


def clear_gate(t):
    t["gate"] = None
    if t["state"] == "owner-gate": t["state"] = "ready"


def set_state(rec, tid, state, by=None, delegated_to=None):
    t = _find(rec["tasks"], str(tid), "task")
    if state not in TASK_STATES:
        raise GoalError(f"state {state!r} not in {TASK_STATES}")
    if state == "done":
        t["closed"] = now(); t["verified"] = by or t.get("verified")
    if state == "delegated":
        if not delegated_to: raise GoalError("delegated needs --to <agent>")
        t["delegated_to"] = delegated_to
    elif t.get("delegated_to") and state != "delegated":
        t["delegated_to"] = None
    t["state"] = state; t["updated"] = now()
    return t


def effective_state(t, rec):
    """What the row IS, given its gate and what it waits on. Stored state otherwise."""
    if t["state"] == "done": return "done"
    if t.get("gate"): return "owner-gate"
    open_ids = {x["id"] for x in rec["tasks"] if x["state"] != "done"}
    if any(b in open_ids for b in t.get("blocked_by", [])): return "blocked"
    # a row filed as blocked whose blockers have since closed is ready, not stuck
    if t["state"] == "blocked": return "ready"
    return t["state"]


def add_note(rec, on, text, sid=None):
    """An ephemeral handoff. No state, no count; consumed the first time it is read."""
    target = _target(rec, on)
    n = {"id": _next("n", rec["notes"]), "on": target, "text": text.strip(),
         "created": now(), "by": sid, "consumed": None}
    rec["notes"].append(n)
    return n


def unconsumed_notes(rec):
    return [n for n in rec["notes"] if not n["consumed"]]


def consume_notes(rec):
    out = unconsumed_notes(rec)
    for n in out: n["consumed"] = now()
    return out


def _target(rec, on):
    if on in (None, "", "goal"): return "goal"
    if on.startswith("m"): return _find(rec["milestones"], on, "milestone")["id"]
    return _find(rec["tasks"], on.lstrip("#"), "task")["id"]


# lifecycle

def containment(rec):
    """What stands between here and met. Empty means the goal may close."""
    blockers = []
    open_tasks = [t for t in rec["tasks"] if t["state"] != "done"]
    if open_tasks:
        blockers.append(f"{len(open_tasks)} open row(s): " + ", ".join("#" + t["id"] for t in open_tasks[:8]))
    for m in rec["milestones"]:
        if m["status"] == "open" and not any(t["milestone"] == m["id"] and t["state"] != "done" for t in rec["tasks"]) \
                and any(t["milestone"] == m["id"] for t in rec["tasks"]):
            continue  # every row done; met when the goal closes
        if m["status"] == "open" and not any(t["milestone"] == m["id"] for t in rec["tasks"]):
            blockers.append(f"milestone {m['id']} '{m['name']}' has no rows and is not met")
    unproven = [a for a in rec["accept"] if a["status"] != "proven"]
    if unproven:
        blockers.append("acceptance unproven: " + "; ".join(f"{a['id']} {a['kind']}: {a['text']}" for a in unproven))
    return blockers


def close_milestones_whose_rows_are_done(rec):
    for m in rec["milestones"]:
        rows = [t for t in rec["tasks"] if t["milestone"] == m["id"]]
        if rows and all(t["state"] == "done" for t in rows) and m["status"] == "open":
            m["status"] = "met"; m["met_at"] = now()


def met(rec, by):
    blockers = containment(rec)
    if blockers:
        raise GoalError("not met. " + " · ".join(blockers))
    if not by.strip():
        raise GoalError("--by names what proved the goal (a suite, a deploy seen live, the owner's word)")
    close_milestones_whose_rows_are_done(rec)
    rec.update(status="met", closed=now(), closed_by=by)
    return rec


def drop(rec, why):
    if not why.strip(): raise GoalError("--why is required: a dropped goal says why")
    rec.update(status="dropped", closed=now(), closed_by=f"dropped: {why}")
    return rec


def archive(rec):
    """Move a met or dropped record out of by-id. Rows travel with it."""
    if rec["status"] not in ("met", "dropped"):
        raise GoalError(f"only met or dropped goals archive; this one is {rec['status']}")
    save(rec)
    src = _path(rec["id"]); dst = _path(rec["id"], True)
    if os.path.exists(src):
        os.replace(src, dst)
    rec["_archived"] = True
    return rec


def age_days(rec):
    t = time.mktime(time.strptime(rec["updated"], "%Y-%m-%dT%H:%M:%SZ"))
    return (time.time() - t) / 86400


def drift(rec):
    """Days idle, and the verdict: fresh, drifting (14d) or parked-due (30d)."""
    d = age_days(rec)
    if rec["status"] != "live": return d, rec["status"]
    if d >= PARK_DAYS: return d, "park-due"
    if d >= DRIFT_DAYS: return d, "drifting"
    return d, "fresh"


def park_due(rec):
    d, v = drift(rec)
    if v == "park-due":
        rec["status"] = "parked"; rec["parked_at"] = now(); rec["parked_why"] = f"{int(d)} days without a write"
        return True
    return False


# links

def pointer_path(sid):
    return os.path.join(ROOT, f"{sid}.json")


def session_goal(sid):
    """The goal_id this session points at, via goal.sh's pointer file, or None."""
    p = pointer_path(sid)
    if not os.path.exists(p): return None
    try:
        with open(p) as f: j = json.load(f)
    except Exception: return None
    return j.get("goal_id") or (goal_id(j["text"]) if j.get("text") else None)


def link(rec, sid, cwd=None, by="agent"):
    """Point this session at the goal: the pointer goal.sh reads, plus provenance here."""
    if sid not in rec["sessions"]: rec["sessions"].append(sid)
    p = pointer_path(sid)
    j = {}
    if os.path.exists(p):
        try:
            with open(p) as f: j = json.load(f)
        except Exception: j = {}
    j.update({"set": True, "text": rec["outcome"], "by": by, "via": "gs", "sid": sid,
              "cwd": cwd or j.get("cwd") or os.getcwd(), "set_at": now(), "goal_id": rec["id"],
              "first_set_at": j.get("first_set_at") or rec["created"], "first_by": j.get("first_by") or by,
              "rearms": j.get("rearms", 0), "sids": sorted(set((j.get("sids") or []) + [sid]))})
    os.makedirs(ROOT, exist_ok=True)
    _atomic_write(p, j)
    return j


def repo_root(path=None):
    """The git root of a path, or the path itself. Realpath, so symlinked CWDs agree."""
    import subprocess
    path = os.path.realpath(path or os.getcwd())
    try:
        r = subprocess.run(["git", "-C", path, "rev-parse", "--show-toplevel"],
                           capture_output=True, text=True, timeout=5)
        if r.returncode == 0 and r.stdout.strip(): return os.path.realpath(r.stdout.strip())
    except Exception: pass
    return path


def in_scope(sid=None, cwd=None, project=None, all_goals_flag=False):
    """Goals a view shows by default: this session's, plus live ones touching the CWD repo.
    From ~/.claude every live goal. Never a resolver: nothing here guesses a session."""
    goals = all_goals()
    if all_goals_flag: return goals
    if project:
        p = project.rstrip("/"); base = os.path.basename(p)
        return [g for g in goals if any(x.rstrip("/") == p or os.path.basename(x.rstrip("/")) == base for x in g["projects"])]
    # ~/.claude is a project like any other (the gcc), never a window onto every
    # goal: a gcc session showing a product session's goal is the wrong-queue defect
    # again (owner, 2026-09-24). --all is the only way to see everything.
    root = repo_root(cwd)
    mine = session_goal(sid) if sid else None
    out = []
    for g in goals:
        if g["id"] == mine or (sid and sid in g["sessions"]):
            out.append(g); continue
        if g["status"] == "live" and any(os.path.realpath(x) == root for x in g["projects"]):
            out.append(g)
    return out


def _find(items, ref, what):
    ref = str(ref)
    for x in items:
        if x["id"] == ref or x["id"] == ref.lstrip("#"): return x
    raise GoalError(f"no {what} {ref!r}; this goal has {', '.join(x['id'] for x in items) or 'none'}")
