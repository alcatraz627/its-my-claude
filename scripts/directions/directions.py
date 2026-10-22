#!/usr/bin/env python3
"""Keeps a repo's DIRECTIONS.md honest: the board the owner reads to choose
what comes next.

The file is written by agents describing their own work, which is how every
earlier tracker went wrong: done that was not done, two copies of one state
drifting apart, rows that grew into paragraphs, and owner asks the owner could
not act on. This checks the file against what can be checked (git, the issue
tracker, the goal record) and against the shape the owner set, and it copies
states from the goal record and the tracker into the file so the file never
becomes a second authority.

Usage:
  directions.py lint <file> [--json]   findings; exit 1 when any is an error
  directions.py sync <file> [--dry-run] mark rows done that their source shows done
  directions.py hook-post              PostToolUse: Edit/Write baseline, gs auto-sync
  directions.py hook-stop              Stop: hold the turn on errors this turn added

Design and evidence: ~/.claude/assets/reports/20261022-directions-lint/DESIGN.md
Mute the hooks: touch ~/.claude/.no-directions-gate
"""
import glob
import json
import os
import re
import subprocess
import sys

HOME = os.path.expanduser("~")
GOALS_DIR = os.environ.get("DIRECTIONS_GOALS_DIR", os.path.join(HOME, ".claude", "goals", "by-id"))
STATE_DIR = os.environ.get("DIRECTIONS_STATE", "/tmp")
MUTE = os.path.join(HOME, ".claude", ".no-directions-gate")
MAX_STOP_BLOCKS = 2

DONE, NEEDS_YOU, INFERRED = "✅", "🔴", "💭"
# Caps that keep the file glanceable. Over a cap is a warning naming what to fold.
MAX_ROWS_PER_TABLE, MAX_DIRECTIONS, MAX_STANDING, MAX_WAITING = 8, 7, 5, 12
# Characters in a row's task or an ask. The versions the owner accepted (39e01c4
# on) peak at 74 and 52; the wall-of-text versions they rejected ran 111 to 545.
LONG_TASK = 100

TICK = re.compile(r"`([^`]+)`")
SHA = re.compile(r"\b(?=[0-9a-f]*\d)(?=[0-9a-f]*[a-f])[0-9a-f]{7,40}\b")
GOAL_ID = re.compile(r"\b[0-9a-f]{12}\b")
PATHISH = re.compile(r"^~?[\w.-]+(/[\w.@-]+)+/?$|^[\w.-]+\.(py|md|ts|tsx|js|cjs|mjs|sh|json|yml|yaml|toml|sql)$")
# Proof that belongs in Sources, not in a row: a commit, a file:line, a run id. A
# folder or file named as the subject of a task ("move X to ops/") is fine.
ROW_PROOF = re.compile(r"\b(?=[0-9a-f]*\d)(?=[0-9a-f]*[a-f])[0-9a-f]{7,40}\b|[\w./-]+\.[a-z]{1,5}:\d+|\b\d{9,}\b")
NO_DEFAULT = {"", "-", "—", "n/a", "none", "?", "tbd"}
GS_DONE = {"done", "dropped"}


def error(code, msg, ids=()):
    return {"level": "error", "code": code, "ids": list(ids), "msg": msg}


def warn(code, msg, ids=()):
    return {"level": "warn", "code": code, "ids": list(ids), "msg": msg}


# Reading the file

def cells(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def header_key(c):
    return re.sub(r"[^a-z ]", "", c.lower()).strip()


def expand_ids(text):
    """The ids a cell names, with "`H1` to `H5`" and "`#184` to `#187`" expanded."""
    toks = []
    for t in TICK.findall(text):
        # "`#184 to #187`" written inside one pair of backticks
        m = re.match(r"^(\S+)\s+to\s+(\S+)$", t)
        toks += [m.group(1), "\0to", m.group(2)] if m else [t]
    text = text + " " + " ".join("`%s` to `%s`" % (toks[k - 1], toks[k + 1])
                                 for k in range(1, len(toks) - 1) if toks[k] == "\0to")
    toks = [t for t in toks if t != "\0to"]
    out = []
    for i, t in enumerate(toks):
        out.append(t)
        m_to = re.search(r"`%s`\s+to\s+`([^`]+)`" % re.escape(t), text)
        if m_to:
            a, b = re.match(r"^(.*?)(\d+)$", t), re.match(r"^(.*?)(\d+)$", m_to.group(1))
            if a and b and a.group(1) == b.group(1) and int(a.group(2)) < int(b.group(2)) <= int(a.group(2)) + 50:
                out += ["%s%d" % (a.group(1), n) for n in range(int(a.group(2)) + 1, int(b.group(2)))]
    seen, uniq = set(), []
    for t in out:
        if t not in seen:
            seen.add(t)
            uniq.append(t)
    return uniq


def parse(text):
    """The file as sections, tables and Sources bullets, keyed by what the
    owner's headers name, so a three- or six-column table both read."""
    doc = {"tables": [], "sources": [], "directions": [], "standing": 0, "lines": text.split("\n")}
    h2 = h3 = ""
    in_sources = in_standing = False
    lines = doc["lines"]
    i = 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("## "):
            h2, h3 = ln[3:].strip(), ""
            in_sources = h2.lower().startswith("sources")
            in_standing = h2.lower().startswith("where things stand")
            if "🧭" in h2:
                doc["directions"].append(h2)
        elif ln.startswith("### "):
            h3 = ln[4:].strip()
        elif in_sources and re.match(r"\s*[-*]\s", ln):
            doc["sources"].append(ln)
        elif in_standing and re.match(r"\s*[-*]\s", ln):
            doc["standing"] += 1
        if ln.lstrip().startswith("|") and i + 1 < len(lines) and re.match(r"^\s*\|[\s:|-]+\|\s*$", lines[i + 1]):
            head = [header_key(c) for c in cells(ln)]
            rows, j = [], i + 2
            while j < len(lines) and lines[j].lstrip().startswith("|"):
                rows.append((j, cells(lines[j])))
                j += 1
            doc["tables"].append({"h2": h2, "h3": h3, "head": head, "rows": rows})
            i = j
            continue
        i += 1
    return doc


def col(head, *names):
    for n in names:
        for k, h in enumerate(head):
            if h == n or h.endswith(" " + n) or h.startswith(n):
                return k
    return None


def kind(table):
    head = table["head"]
    if col(head, "ask") is not None or table["h2"].lower().startswith("waiting on you"):
        return "waiting"
    if col(head, "direction") is not None:
        return "shape"
    if col(head, "id") is not None and col(head, "state") is not None:
        return "rows"
    return "other"


def row_entries(doc):
    """Every work row: its line number, ids, state cell and task cell."""
    out = []
    for t in doc["tables"]:
        if kind(t) != "rows":
            continue
        ci, cs, ct = col(t["head"], "id"), col(t["head"], "state"), col(t["head"], "task")
        for ln, cs_ in t["rows"]:
            if max(ci, cs) >= len(cs_):
                continue
            out.append({"line": ln, "ids": expand_ids(cs_[ci]), "state": cs_[cs],
                        "task": cs_[ct] if ct is not None and ct < len(cs_) else "",
                        "raw": doc["lines"][ln], "table": t})
    return out


# Reading the sources of truth

def repo_root(path):
    r = subprocess.run(["git", "-C", os.path.dirname(os.path.abspath(path)) or ".", "rev-parse", "--show-toplevel"],
                       capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else None


def goal_rows(text):
    """Goal-record rows by '#n', from every goal the file cites by id."""
    rows, goals = {}, []
    for gid in sorted(set(GOAL_ID.findall(text))):
        p = os.path.join(GOALS_DIR, gid + ".json")
        if not os.path.exists(p):
            continue
        try:
            with open(p) as f:
                g = json.load(f)
        except (OSError, ValueError):
            continue
        goals.append(g)
        for t in g.get("tasks") or []:
            key = "#%s" % t.get("id")
            rows[key] = None if key in rows else dict(t, goal=gid)   # in two goals: ambiguous, skip
    return {k: v for k, v in rows.items() if v}, goals


def issue_states(root):
    """Issue number -> OPEN or CLOSED, in one tracker call. Never cached: an
    issue's state changes outside this machine."""
    fake = os.environ.get("DIRECTIONS_GH_STATES")
    if fake is not None:
        return {int(k): v for k, v in json.loads(fake).items()}
    try:
        r = subprocess.run(["gh", "issue", "list", "--state", "all", "--limit", "1000", "--json", "number,state"],
                           cwd=root, capture_output=True, text=True, timeout=30)
        return {i["number"]: i["state"] for i in json.loads(r.stdout)} if r.returncode == 0 else None
    except (OSError, ValueError, subprocess.SubprocessError):
        return None


def commit_exists(root, sha):
    return subprocess.run(["git", "-C", root, "cat-file", "-e", sha + "^{commit}"], capture_output=True).returncode == 0


def source_state(i, gs_rows, issues):
    """'done', 'open', or None when no checkable source owns this id."""
    if i in gs_rows:
        return "done" if gs_rows[i].get("state") in GS_DONE else "open"
    m = re.match(r"^GH#(\d+)$", i)
    if m and issues is not None and int(m.group(1)) in issues:
        return "done" if issues[int(m.group(1))] == "CLOSED" else "open"
    return None


def proof_for(ids, doc, root, goal_ids):
    """Whether Sources backs these ids: 'checked' (a commit or path that
    resolves), 'cited' (a bullet names them, nothing machine-checkable),
    'broken' (every commit or path it names fails), or None (no bullet)."""
    best = None
    for b in doc["sources"]:
        if not set(expand_ids(b)) & set(ids):
            continue
        pointers = [s for s in SHA.findall(b) if s not in goal_ids]
        paths = [t.split(":")[0] for t in TICK.findall(b) if PATHISH.match(t.split(":")[0])]
        ok = any(commit_exists(root, s) for s in pointers) or any(
            os.path.exists(os.path.join(root, p)) or os.path.exists(os.path.expanduser(p)) for p in paths)
        verdict = "checked" if ok else ("broken" if pointers or paths else "cited")
        rank = {"checked": 3, "cited": 2, "broken": 1}
        if best is None or rank[verdict] > rank[best]:
            best = verdict
    return best


# The checks

def lint(path, text=None):
    if text is None:
        with open(path, encoding="utf-8", errors="replace") as f:
            text = f.read()
    doc = parse(text)
    root = repo_root(path) or os.path.dirname(os.path.abspath(path))
    gs_rows, goals = goal_rows(text)
    goal_ids = {g.get("id") for g in goals}
    needs_gh = re.search(r"`GH#\d+`", text) is not None
    issues = issue_states(root) if needs_gh else {}
    out = []
    if needs_gh and issues is None:
        out.append(warn("no-tracker", "Could not read the issue tracker, so GH# rows were not checked."))

    rows = row_entries(doc)
    for r in rows:
        ids, done = r["ids"], DONE in r["state"]
        label = ", ".join(ids) or "a row"
        states = [source_state(i, gs_rows, issues) for i in ids]
        owned = [s for s in states if s is not None]
        if owned and len(owned) == len(ids):
            if all(s == "done" for s in owned) and not done:
                out.append(error("open-but-done", "%s: its source shows it done, but the row is not ✅. Run "
                                 "`directions.py sync` or mark it ✅." % label, ids))
            if done and any(s == "open" for s in owned):
                src = "the goal record" if any(i in gs_rows for i in ids) else "the issue tracker"
                out.append(error("done-but-open", "%s: the row says ✅ but %s says it is still open. If it is "
                                 "done, close it there with its proof; if not, reopen the row." % (label, src), ids))
        elif done and INFERRED not in r["raw"]:
            p = proof_for(ids, doc, root, goal_ids)
            if p is None:
                out.append(error("done-unproven", "%s: marked ✅ with nothing in Sources behind it. Add the commit, "
                                 "file or run that shows it, or mark it 💭 (agent inferred)." % label, ids))
            elif p == "broken":
                out.append(error("proof-broken", "%s: its Sources line names a commit or file that does not exist "
                                 "in this repo." % label, ids))
        task = TICK.sub(lambda m: m.group(1), r["task"])
        if len(task) > LONG_TASK:
            out.append(error("row-long", "%s: the task is %d characters. One short line; detail goes to Sources."
                             % (label, len(task)), ids))
        if ROW_PROOF.search(r["task"]):
            out.append(error("proof-in-row", "%s: the task carries a commit, file:line or run id. Move it to "
                             "Sources and keep the row to what is true." % label, ids))

    states_by_id = {}
    for r in rows:
        for i in r["ids"]:
            states_by_id.setdefault(i, r["state"])
    for t in doc["tables"]:
        if kind(t) != "waiting":
            continue
        ci, cd = col(t["head"], "id"), col(t["head"], "if you say nothing", "default", "if")
        if len(t["rows"]) > MAX_WAITING:
            out.append(warn("too-many-asks", "Waiting on you has %d entries. Keep what you can act on today; the "
                            "rest belongs under its direction." % len(t["rows"])))
        for _, c in t["rows"]:
            ids = expand_ids(c[ci]) if ci is not None and ci < len(c) else []
            label = ", ".join(ids) or "an ask"
            ca = col(t["head"], "ask", "what")
            ask = TICK.sub(lambda m: m.group(1), c[ca]) if ca is not None and ca < len(c) else ""
            if len(ask) > LONG_TASK:
                out.append(error("ask-long", "%s: the ask is %d characters. Say the one thing the owner does; "
                                 "the why goes under its direction." % (label, len(ask)), ids))
            default = c[cd] if cd is not None and cd < len(c) else ""
            if default.strip().lower() in NO_DEFAULT:
                out.append(error("ask-no-default", "%s: no default. Say what happens if the owner says nothing."
                                 % label, ids))
            srcs = [source_state(i, gs_rows, issues) for i in ids]
            if ids and all(s == "done" for s in srcs):
                out.append(error("ask-stale", "%s: already done at its source, so it is not waiting on the owner."
                                 % label, ids))
            blockers = [b for i in ids if i in gs_rows for b in gs_rows[i].get("blocked_by") or []
                        if source_state("#%s" % b, gs_rows, issues) == "open"]
            if blockers:
                out.append(error("ask-blocked", "%s: waits on open work (%s) first, so the owner cannot act on it "
                                 "today. Move it under its direction." % (label, ", ".join("#%s" % b for b in blockers)),
                                 ids))
            for i in ids:
                st = states_by_id.get(i)
                if st is not None and NEEDS_YOU not in st and DONE not in st:
                    out.append(warn("ask-row-state", "%s: asked of the owner, but its row is %s, not 🔴." % (i, st),
                                    [i]))

    for t in doc["tables"]:
        if kind(t) == "rows" and len(t["rows"]) > MAX_ROWS_PER_TABLE:
            out.append(warn("too-many-rows", "%s has %d rows. Fold the done or minor ones into one line."
                            % (t["h3"] or t["h2"], len(t["rows"]))))
        if kind(t) == "rows" and t["rows"] and t["h3"]:
            cs = col(t["head"], "state")
            if all(DONE in c[cs] for _, c in t["rows"] if cs < len(c)) and DONE not in t["h3"]:
                out.append(warn("goal-done-unmarked", "%s: every row is ✅; mark the goal ✅ and fold its rows."
                                % t["h3"]))
    if len(doc["directions"]) > MAX_DIRECTIONS:
        out.append(warn("too-many-directions", "%d directions; a reader holds about seven." % len(doc["directions"])))
    if doc["standing"] > MAX_STANDING:
        out.append(warn("standing-long", "Where things stand has %d lines; keep it to five." % doc["standing"]))
    cited = set(GOAL_ID.findall(text))
    repo = os.path.basename(root)
    for p in glob.glob(os.path.join(GOALS_DIR, "*.json")):
        try:
            with open(p) as f:
                g = json.load(f)
        except (OSError, ValueError):
            continue
        if g.get("status") == "live" and repo in (g.get("projects") or []) and g.get("id") not in cited:
            out.append(warn("goal-uncited", "Goal %s (%s) is live for this repo and sits under no direction."
                            % (g.get("id"), (g.get("outcome") or "")[:60])))
    return out


# Copying states in

def sync(path, dry=False):
    """Mark ✅ every row whose source shows it done. Only forward: a ✅ the
    source disagrees with is a question (lint says so), never flipped back."""
    with open(path, encoding="utf-8") as f:
        text = f.read()
    doc = parse(text)
    root = repo_root(path) or os.path.dirname(os.path.abspath(path))
    gs_rows, _ = goal_rows(text)
    issues = issue_states(root) if re.search(r"`GH#\d+`", text) else {}
    lines, changed = doc["lines"], []
    for r in row_entries(doc):
        if DONE in r["state"] or not r["ids"]:
            continue    # sync only ever marks rows done, so a done row has nothing to gain
        states = [source_state(i, gs_rows, issues) for i in r["ids"]]
        if all(s == "done" for s in states):
            c = cells(lines[r["line"]])
            cs = col(r["table"]["head"], "state")
            c[cs] = DONE
            lines[r["line"]] = "| " + " | ".join(c) + " |"
            changed.append(", ".join(r["ids"]))
    if changed and not dry:
        with open(path, "w", encoding="utf-8") as f:
            f.write("\n".join(lines))
    return changed


# Hooks

def state_path(sid):
    return os.path.join(STATE_DIR, "claude-directions-%s.json" % (sid or "unknown")[:8])


def load_state(sid):
    try:
        with open(state_path(sid)) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {"files": {}, "blocks": 0}


def save_state(sid, st):
    with open(state_path(sid), "w") as f:
        json.dump(st, f)


def committed(path):
    root = repo_root(path)
    if not root:
        return None
    rel = os.path.relpath(os.path.realpath(path), os.path.realpath(root))
    r = subprocess.run(["git", "-C", root, "show", "HEAD:%s" % rel], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else None


def keys(findings):
    return {"%s|%s" % (f["code"], ",".join(f["ids"])) for f in findings if f["level"] == "error"}


def directions_file(cwd):
    root = repo_root(os.path.join(cwd or ".", "x"))
    if not root:
        return None
    for p in (os.path.join(root, "docs", "plan", "DIRECTIONS.md"), os.path.join(root, "DIRECTIONS.md")):
        if os.path.exists(p):
            return p
    return None


def hook_post(data):
    tool, ti = data.get("tool_name"), data.get("tool_input") or {}
    if tool in ("Write", "Edit", "MultiEdit") and os.path.basename(ti.get("file_path") or "") == "DIRECTIONS.md":
        path = ti["file_path"]
        st = load_state(data.get("session_id"))
        if path not in st["files"]:
            old = committed(path)
            # The baseline is the file as committed, so only errors this turn added hold the turn.
            st["files"][path] = sorted(keys(lint(path, old))) if old is not None else []
            save_state(data.get("session_id"), st)
        return 0
    cmd = ti.get("command") or ""
    if tool == "Bash" and re.search(r"\bgs\s+(close|met|drop)\b", cmd):
        path = directions_file(data.get("cwd"))
        if path and any(g in cmd for g in GOAL_ID.findall(open(path, encoding="utf-8", errors="replace").read())):
            done = sync(path)
            if done:
                msg = ("DIRECTIONS.md followed the goal record: %s now ✅. Commit it with your change."
                       % "; ".join(done))
                print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}))
    return 0


def hook_stop(data):
    sid = data.get("session_id")
    st = load_state(sid)
    if not st["files"]:
        return 0
    new = []
    for path, base in st["files"].items():
        if not os.path.exists(path):
            continue
        found = [f for f in lint(path) if f["level"] == "error"]
        new += [(path, f) for f in found if "%s|%s" % (f["code"], ",".join(f["ids"])) not in set(base)]
    if not new:
        os.remove(state_path(sid))
        return 0
    detail = " ".join("%s" % f["msg"] for _, f in new[:8])
    if st["blocks"] < MAX_STOP_BLOCKS:
        st["blocks"] += 1
        save_state(sid, st)
        print(json.dumps({"decision": "block", "reason": "DIRECTIONS.md has problems this turn added: " + detail +
                          " Fix them, or say in one sentence which one stays and why."}))
        return 0
    os.remove(state_path(sid))
    print(json.dumps({"systemMessage": "directions check: DIRECTIONS.md still has problems this turn added. " + detail}))
    return 0


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    cmd = argv[0]
    if cmd in ("hook-post", "hook-stop"):
        if os.path.exists(MUTE) or os.environ.get("DIRECTIONS_GATE_OFF") == "1":
            return 0
        try:
            data = json.load(sys.stdin)
            return hook_post(data) if cmd == "hook-post" else hook_stop(data)
        except Exception:
            return 0   # a bug here must never block a write or a turn by accident
    if cmd == "lint" and len(argv) > 1:
        found = lint(argv[1])
        if "--json" in argv:
            print(json.dumps(found, ensure_ascii=False, indent=1))
        else:
            for f in found:
                print("%s %-18s %s" % ("ERROR" if f["level"] == "error" else "warn ", f["code"], f["msg"]))
            print("%d errors, %d warnings" % (sum(f["level"] == "error" for f in found),
                                               sum(f["level"] == "warn" for f in found)))
        return 1 if any(f["level"] == "error" for f in found) else 0
    if cmd == "sync" and len(argv) > 1:
        changed = sync(argv[1], dry="--dry-run" in argv)
        print(("would mark ✅: " if "--dry-run" in argv else "marked ✅: ") + ("; ".join(changed) or "nothing"))
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
