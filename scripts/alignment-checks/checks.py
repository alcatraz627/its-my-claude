#!/usr/bin/env python3
"""Nine checks that say whether /tasks, /goal and the board answer the owner.

Each check is a definition of done written before the work. It prints one line,
RED or GREEN, with the evidence that decided it, and never asks a reader to
interpret anything. A check that goes green while the owner is still failed is a
defect in the check, and gets fixed before any code does.

Usage: checks.py [name ...]      run all, or the named ones
       checks.py --list          the nine names, one per line
Exit code: the number of red checks.

Provenance: ~/.claude/assets/reports/20260907-alignment-surfaces-diagnosis/diagnosis.md,
section "What a fix has to satisfy before it is called one".
"""
import glob
import json
import os
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
GCC = os.path.join(HOME, ".claude")
TASKS = os.path.join(GCC, "tasks")
TABLE = os.path.join(GCC, "scripts", "task-table", "task-table.sh")
TASK_SH = os.path.join(GCC, "scripts", "task-table", "task.sh")
GOAL_SH = os.path.join(GCC, "scripts", "goal", "goal.sh")
KANBAN_SH = os.path.join(GCC, "scripts", "kanban", "kanban.sh")
PROJECTS = os.path.join(GCC, "projects")
BIG_STORES = ["f04ae843", "1523e931"]          # the two stores over the 44-line cap
WEEK = 7 * 86400


def sh(args, cwd=None):
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True)
    return p.returncode, p.stdout, p.stderr


def rows(sid8):
    out = []
    for f in glob.glob(os.path.join(TASKS, f"session-{sid8}", "*.json")):
        try:
            t = json.load(open(f))
        except Exception:
            continue
        if isinstance(t, dict) and "status" in t:
            t["_file"] = f
            out.append(t)
    return out


def meta(t, k):
    return (t.get("metadata") or {}).get(k)


def first_screen_same_from_any_cwd():
    """The first screen does not depend on where the shell happens to be.

    Mechanical half of test 1. The judgment half (do the four questions get
    answered on that screen) reads the fixture this writes.
    """
    dirs = [os.path.join(HOME, "Code/Versable/gcp"),
            os.path.join(HOME, "Code/Versable/versable-foundry/runner")]
    heads = []
    for d in dirs:
        if not os.path.isdir(d):
            return "RED", f"directory missing: {d}"
        rc, out, _ = sh(["bash", TABLE, "--session", "f04ae843"], cwd=d)
        lines = out.splitlines()
        # A renderer that prints nothing compared equal to itself and passed
        # (review 2026-09-08, exit 9 mutation): the render has to be a table.
        if rc != 0 or not lines or not lines[0].startswith("TASKS") or len(lines) < 2:
            return "RED", f"no table rendered from {d} (rc {rc}): {lines[0][:60] if lines else '(nothing)'}"
        heads.append(lines[1])
        fx = os.path.join(GCC, "scripts", "alignment-checks", "fixtures")
        os.makedirs(fx, exist_ok=True)
        # The frozen first-screen-from-<dir>.txt files are what the cold read was
        # judged against and are never rewritten here; the live capture goes beside them.
        open(os.path.join(fx, f"first-screen-from-{os.path.basename(d)}.latest.txt"), "w").write("\n".join(lines[:44]))
    a = heads[0].split("·")[-1].strip()
    b = heads[1].split("·")[-1].strip()
    if a and a == b:
        return "GREEN", f"same grouping from both dirs: {a}"
    return "RED", f"gcp says '{a}'; foundry/runner says '{b}'"


def render_reactions_are_logged():
    """The owner's next message after a /tasks render is recorded beside the render."""
    log = os.path.join(GCC, "logs", "tasks-render-reactions.jsonl")
    if not os.path.exists(log):
        return "RED", f"no log at {log}; nothing records what he said after a render"
    n = 0
    cut = time.time() - WEEK
    for line in open(log):
        try:
            o = json.loads(line)
        except Exception:
            continue
        if o.get("ts", 0) >= cut:
            n += 1
    if n == 0:
        return "RED", "log exists but holds no row from the last 7 days"
    return "GREEN", f"{n} render-reaction rows in the last 7 days"


def header_says_which_goal_it_counts():
    """The goal the header counts is the armed goal, or the header says which object it is counting."""
    sid = os.environ.get("CLAUDE_CODE_SESSION_ID", "")
    if not sid:
        return "RED", "no CLAUDE_CODE_SESSION_ID; run inside a session"
    # Bare run first, as the owner's /tasks resolves; --session <live sid> only
    # holds when the session owns a store named for it, and from a pinned
    # session it fed the check a refusal instead of a header.
    rc, out, _ = sh(["bash", TABLE])
    if rc != 0 or not out.startswith("TASKS"):
        rc, out, _ = sh(["bash", TABLE, "--session", sid[:8]])
    head = out.splitlines()[0] if out else ""
    if not head.startswith("TASKS"):
        return "RED", f"no table rendered for this session: {head[:70]}"
    rc2, hj, _ = sh(["bash", GOAL_SH, "harness", "--sid", sid])
    armed = ""
    try:
        armed = json.loads(hj).get("text") or ""
    except Exception:
        pass
    # Two facts, both required: line 1 carries the armed goal (or says none is
    # armed), and the count names itself as tags. A green on the count alone
    # survived the armed segment being deleted (review 2026-09-08).
    if armed:
        # Since 2026-09-08 (unblock-0908 D2b) line 1 says a goal is armed and
        # the text rides its own /goal line under the provenance line, whole.
        first = out.splitlines()[:8]
        goal_line = next((l for l in first if l.startswith("/goal ")), "")
        if "armed" not in head or not goal_line or armed[:24] not in goal_line:
            return "RED", f"a goal is armed but the first screen does not carry it on a /goal line: {head[:80]}"
    elif "no /goal armed" not in head:
        return "RED", f"no goal is armed and line 1 does not say so: {head[:80]}"
    if "goal tag" in head or "metadata.goal" in head or "no rows" in head.lower():
        return "GREEN", f"line 1 carries the armed goal and names what it counts: {head[:80]}"
    return "RED", f"header '{head[:70]}' counts metadata.goal strings without saying so"


def gates_carry_the_date_they_were_believed():
    """Every USER: gate records when it was set, so a render can age it against later rulings."""
    missing, total = [], 0
    for sid in BIG_STORES:
        for t in rows(sid):
            if t.get("status") == "completed":
                continue
            bo = str(meta(t, "blocked_on") or "")
            if bo.startswith("USER:"):
                total += 1
                if not meta(t, "blocked_on_at"):
                    missing.append(f"{sid}#{t.get('id')}")
    if total == 0:
        return "RED", "no USER: gates found in the two big stores; check the stores exist"
    if missing:
        return "RED", f"{len(missing)} of {total} gates carry no blocked_on_at: {' '.join(missing[:6])}"
    return "GREEN", f"all {total} gates carry blocked_on_at"


def suite_renders_the_real_stores():
    """The renderer's suite includes frozen copies of the two real stores and a golden first screen for each."""
    fx = os.path.join(GCC, "scripts", "task-table", "fixtures")
    have = []
    for sid in BIG_STORES:
        bundle = os.path.join(fx, f"session-{sid}.json")
        golden = os.path.join(fx, f"session-{sid}.golden.txt")
        if os.path.exists(bundle) and os.path.exists(golden):
            have.append(sid)
    tests = glob.glob(os.path.join(GCC, "scripts", "task-table", "*.test.sh"))
    cites = [t for t in tests if any(sid in open(t, errors="ignore").read() for sid in BIG_STORES)]
    if len(have) == 2 and cites:
        return "GREEN", f"both stores frozen with goldens; cited by {os.path.basename(cites[0])}"
    return "RED", (f"frozen stores with goldens: {have or 'none'}; suites citing a real store: {len(cites)} of {len(tests)}"
                   f"; the fixtures are local only (public remote, D4a 2026-09-08): python3 {fx}/freeze.py {' '.join(BIG_STORES)}")


def a_row_moves_between_store_and_board():
    """One command moves a task row to the board and back, so project-altitude work has a legal home."""
    # Read the dispatch tables, not the help text: -h printed a clipped header
    # and the word survived on its last line (review 2026-09-08).
    body = open(TASK_SH, errors="ignore").read() + open(KANBAN_SH, errors="ignore").read()
    words = ("to-board)", "from-task)", "promote)", "import-task)")
    hits = [w.rstrip(")") for w in words if w in body]
    if hits:
        return "GREEN", f"verb handled in code: {hits} (a string scan of the dispatch table; the verb is exercised by task.test.sh, not here)"
    return "RED", "neither task.sh nor kanban.sh has a verb that moves a row between store and board"


def proposed_goal_never_stops_work():
    """After an agent prints a /goal paste line, its next act is a tool call, not the end of the turn."""
    # A paste line printed at a hand-off (catchup's closing question, a
    # core-dump's checkpoint) is followed by nothing on purpose, so those are
    # counted separately rather than as stops.
    handoff = ("Which pending item", "/catchup", "checkpoint", "core-dump")
    cut = time.time() - WEEK
    stops, proposals, handoffs = [], 0, 0
    for f in glob.glob(os.path.join(PROJECTS, "*", "*.jsonl")):
        if os.stat(f).st_mtime < cut:
            continue
        msgs = []
        for line in open(f, errors="ignore"):
            try:
                o = json.loads(line)
            except Exception:
                continue
            if o.get("type") in ("user", "assistant"):
                msgs.append(o)
        for i, o in enumerate(msgs):
            if o["type"] != "assistant":
                continue
            c = o.get("message", {}).get("content")
            if not isinstance(c, list):
                continue
            texts = [b.get("text", "") for b in c if b.get("type") == "text"]
            if not any(l.strip().startswith("/goal ") for t in texts for l in t.splitlines()):
                continue
            joined = "\n".join(texts)
            if any(h in joined for h in handoff) or i == len(msgs) - 1:
                handoffs += 1
                continue
            proposals += 1
            # did any assistant message before the next user turn carry a tool_use?
            acted = any(b.get("type") == "tool_use" for b in c)
            j = i + 1
            while not acted and j < len(msgs) and msgs[j]["type"] == "assistant":
                cc = msgs[j].get("message", {}).get("content")
                if isinstance(cc, list) and any(b.get("type") == "tool_use" for b in cc):
                    acted = True
                j += 1
            if not acted:
                stops.append(f"{os.path.basename(f)[:8]}")
    if proposals == 0:
        return "RED", f"no mid-work /goal proposals found in 7 days ({handoffs} hand-off paste lines excluded)"
    if stops:
        return "RED", f"{len(stops)} of {proposals} mid-work proposals ended the turn with no tool call ({handoffs} hand-off lines excluded): {' '.join(sorted(set(stops))[:6])}"
    return "GREEN", f"all {proposals} mid-work proposals were followed by a tool call ({handoffs} hand-off lines excluded)"


def owner_actor_clause_is_detected_on_arm():
    """Arming a goal whose clause names the owner as actor is detected on every path, the harness /goal included."""
    hooks = glob.glob(os.path.join(GCC, "hinters", "*.sh")) + glob.glob(os.path.join(GCC, "scripts", "hooks", "*.sh"))
    detectors = []
    for h in hooks:
        body = open(h, errors="ignore").read()
        if "goal.sh" in body and "harness" in body and "lint" in body and os.access(h, os.X_OK):
            detectors.append(h)
    if not detectors:
        return "RED", "no executable hook reads the harness-armed goal and lints it; goal.sh lint only runs on goal.sh set"
    # The linter itself has to fire on an owner-actor clause; a detector that
    # calls it is nothing if it stays silent (review 2026-09-08).
    rc, _, err = sh(["bash", GOAL_SH, "lint", "Draft the plan and take the owner's review of it"])
    if "OWNER action" not in err:
        return "RED", "goal.sh lint stayed silent on 'take the owner's review of it'"
    rc, _, err2 = sh(["bash", GOAL_SH, "lint", "The runner suite is green at head"])
    if "OWNER action" in err2:
        return "RED", "goal.sh lint flags a clause with no owner actor"
    return "GREEN", f"arm detector: {os.path.basename(detectors[0])} reads the harness arm; goal.sh lint fires on an owner-actor clause and not on a plain one"


def done_rows_name_their_instrument():
    """A row closed in the last 7 days says what proved it: verified true, prod, or a named instrument."""
    # Rows carry no timestamp of their own, so the file's mtime is the only
    # record of when a row was last written, and a completed row's last write
    # is its closing.
    cut = time.time() - WEEK
    total, missing = 0, 0
    for d in glob.glob(os.path.join(TASKS, "session-*")):
        for f in glob.glob(os.path.join(d, "*.json")):
            if os.stat(f).st_mtime < cut:
                continue
            try:
                t = json.load(open(f))
            except Exception:
                continue
            if t.get("status") != "completed":
                continue
            total += 1
            if meta(t, "verified") in (None, "", False):
                missing += 1
    if total == 0:
        return "RED", "no rows completed in the last 7 days found"
    if missing:
        return "RED", f"{missing} of {total} rows closed this week carry no verified instrument"
    return "GREEN", f"all {total} rows closed this week name their instrument"


def empty_own_store_never_renders():
    """A session whose own store is empty and whose real rows live in an inherited store never gets an empty table: the project's one stamped store renders, several stamped stores refuse by name.

    Reported by forge-console 2026-09-08 (ipc msg-f0162e0df3584d2a): the injector
    put an EMPTY STORE table into an agent's context under a trust-this instruction.
    """
    sid = "chk0empt-0000-4000-8000-000000000000"
    d = os.path.join(TASKS, f"session-{sid[:8]}")
    os.makedirs(d, exist_ok=True)
    try:
        env = dict(os.environ, CLAUDE_CODE_SESSION_ID=sid)
        # from the forge-console project, whose rows live in an inherited store
        proj = os.path.join(HOME, "Code/Versable/gcp")
        p = subprocess.run(["bash", TABLE], cwd=proj if os.path.isdir(proj) else GCC,
                           capture_output=True, text=True, env=env)
        out = p.stdout + p.stderr
        head = p.stdout.splitlines()[0] if p.stdout else ""
        # A refusal says so; a crash does not (review 2026-09-08: exit 9 passed).
        if p.returncode != 0 and "EMPTY STORE" not in p.stdout and ("own store is empty" in out or "could not identify" in out):
            return "GREEN", f"bare run refused (rc {p.returncode}) naming the stamped stores instead of rendering the empty own-store"
        # Since 2026-09-08 one populated store stamped with the project is the
        # answer, so a render of THAT store (never the empty own one) is green too.
        if p.returncode == 0 and head.startswith("TASKS") and f"session-{sid[:8]}" not in head and "EMPTY STORE" not in p.stdout:
            return "GREEN", f"bare run rendered the project's stamped store, not the empty own one: {head[:70]}"
        return "RED", f"bare run exited {p.returncode} and rendered: {out.splitlines()[0][:80] if out else '(nothing)'}"
    finally:
        try:
            os.rmdir(d)
        except OSError:
            pass


def ledger_entries_carry_a_disposition():
    """Every peer-ledger entry older than seven days carries a disposition; the ledger is the instrument the pass lacked (check 11)."""
    led = os.path.join(GCC, "logs", "alignment-issues.jsonl")
    dis = os.path.join(GCC, "logs", "alignment-issues.dispositions.jsonl")
    if not os.path.exists(led):
        return "RED", f"no ledger at {led}"
    rows_ = [json.loads(l) for l in open(led) if l.strip()]
    have = set()
    if os.path.exists(dis):
        for l in open(dis):
            try:
                d = json.loads(l); have.add(int(d.get("n", 0)))
            except Exception:
                pass
    cut = time.time() - WEEK
    old = []
    for i, r in enumerate(rows_, 1):
        try:
            ts = calendar_ts(r.get("ts", ""))
        except Exception:
            ts = None
        if ts is not None and ts < cut and i not in have:
            old.append(i)
    if old:
        return "RED", f"{len(old)} of {len(rows_)} ledger entries are older than 7 days with no disposition: {old[:8]}"
    return "GREEN", f"{len(rows_)} entries, {len([i for i in range(1, len(rows_) + 1) if i in have])} dispositioned, none older than 7 days undispositioned"


def calendar_ts(s):
    import calendar
    return calendar.timegm(time.strptime(s, "%Y-%m-%dT%H:%M:%SZ"))


CHECKS = [
    ("empty-own-store-never-renders", empty_own_store_never_renders),
    ("first-screen-same-from-any-cwd", first_screen_same_from_any_cwd),
    ("render-reactions-are-logged", render_reactions_are_logged),
    ("header-says-which-goal-it-counts", header_says_which_goal_it_counts),
    ("gates-carry-the-date-they-were-believed", gates_carry_the_date_they_were_believed),
    ("suite-renders-the-real-stores", suite_renders_the_real_stores),
    ("a-row-moves-between-store-and-board", a_row_moves_between_store_and_board),
    ("proposed-goal-never-stops-work", proposed_goal_never_stops_work),
    ("owner-actor-clause-is-detected-on-arm", owner_actor_clause_is_detected_on_arm),
    ("done-rows-name-their-instrument", done_rows_name_their_instrument),
    ("ledger-entries-carry-a-disposition", ledger_entries_carry_a_disposition),
]


def main():
    args = sys.argv[1:]
    if args == ["--list"]:
        for n, _ in CHECKS:
            print(n)
        return 0
    want = set(args)
    red = 0
    for name, fn in CHECKS:
        if want and name not in want:
            continue
        try:
            state, why = fn()
        except Exception as e:  # a crashing check is red, with the crash as evidence
            state, why = "RED", f"check crashed: {e!r}"
        red += state == "RED"
        print(f"{state:5} {name:42} {why}")
    return red


if __name__ == "__main__":
    sys.exit(main())
