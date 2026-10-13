#!/usr/bin/env python3
"""Everything /core-dump does after the model's Write, in one call.

Formats and validates the checkpoint, flags what a successor could be misled by
(vanished caveats and constraints, authorizations the owner never said, rulings
recorded nowhere), indexes the pointer, then renders the sealed record last.

Usage: finalize.sh <checkpoint> [--name NAME] [--summary TEXT] [--headless] [--prev FILE]
         [--mini] [--session-id SID] [--uuid UUID] [--project-root DIR]
Exit 0 when the dump is indexed, 1 when the contract is broken or the pointer
write failed (the report then says FIX), 2 on usage errors.
Test seams: HOME decides where ~/.claude lives; CK_PRETTIER_CMD replaces
`npx --no-install prettier`; CK_TMP is where the render's data file goes (default
~/.claude/checkpoints/.render, mode 600, removed after the render); CK_TRACE replaces trace.sh.
"""
import argparse
import glob
import json
import os
import re
import shlex
import subprocess
import sys
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ckutil as ck  # noqa: E402

SCRIPTS = os.path.dirname(HERE)
VALIDATE = os.path.join(HERE, "validate-checkpoint.sh")
WRITE = os.path.join(HERE, "write.sh")
TRACE = os.environ.get("CK_TRACE") or os.path.join(SCRIPTS, "render", "trace.sh")
NONE_WORDS = ("", "none", "-", "—", "n/a")
STOP = set("this that with from have been were will into also than then them they their there what when "
           "which while about after before still just only more most some such each other over under "
           "again next item items file files work done".split())
DONE_RE = re.compile(r"\b(done|pushed|merged|sent|shipped|landed|completed|finished)\b", re.I)
FAIL_RE = re.compile(r"\b(didn.t|did not|failed|fails|wrong|broke|broken|dead end|gotcha|trap|bug|mistake|"
                     r"wasted|misled|problem|never worked|not work)", re.I)
QUOTED_RE = re.compile(r"[\"“][^\"”]{4,}[\"”]")


def run(cmd, timeout=60):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout, p.stderr
    except FileNotFoundError:
        return None, "", "command not found: " + cmd[0]
    except subprocess.TimeoutExpired:
        return None, "", "timed out after %ss" % timeout
    except OSError as e:
        return None, "", str(e)


def clip(s, n):
    s = re.sub(r"\s+", " ", s or "").strip()
    return s if len(s) <= n else s[:n - 1].rstrip() + "…"


def blank_value(v):
    return re.sub(r"\s+", " ", v).strip().strip("`").lower() in NONE_WORDS


def split_items(block):
    """Entries of a caveat or constraint field: numbered, bulleted, or joined by a middle dot."""
    parts = re.split(r"\(\d+[a-z]?\)|^\s+[-*]\s+|\s·\s", block, flags=re.M)
    parts = [p.strip() for p in parts if p.strip()]
    if len(parts) > 1 and re.match(r"^\d+\b", parts[0]) and len(parts[0]) < 90:
        parts = parts[1:]
    return parts


def stem_of(path):
    return re.sub(r"\.claude\.md$", "", re.sub(r"^_\d{8}-", "", os.path.basename(path)))


def find_prev(path, explicit, uuid, sid, report):
    if explicit:
        if os.path.isfile(explicit):
            return explicit
        report.append("WARN: --prev %s is not a file; carry-forward from it skipped" % explicit)
    stem = stem_of(path)
    pat = re.compile(r"^_\d{8}-" + re.escape(stem) + r"\.claude\.md$")
    me = os.path.abspath(path)
    cands = [p for p in glob.glob(os.path.join(os.path.dirname(me), "_*.claude.md"))
             if pat.match(os.path.basename(p)) and os.path.abspath(p) != me]
    if cands:
        return max(cands, key=os.path.getmtime)
    snap = ck.prev_snapshot(uuid, sid)
    return snap if os.path.isfile(snap) else None


def vanished(new_items, old_items):
    """Old entries with no new entry holding 60% of their words (the --diff-caveats rule)."""
    new_w = [ck.wordset(x) for x in new_items]
    gone = []
    for o in old_items:
        w = ck.wordset(o)
        if w and not any(len(w & n) / len(w) >= 0.6 for n in new_w):
            gone.append(o)
    return gone


def field_items(text, label):
    f = ck.contract_fields(text).get(label)
    if not f or blank_value(f[0]):
        return []
    return split_items(f[0])


def carried_grants(path, prev):
    """Entry texts that an earlier dump in this project directory holds verified (no UNVERIFIED: prefix)."""
    me = os.path.realpath(path)
    mtime = os.path.getmtime(path)
    files = [p for p in glob.glob(os.path.join(os.path.dirname(os.path.abspath(path)), "_*.claude.md"))
             if os.path.realpath(p) != me and os.path.getmtime(p) <= mtime]
    if prev and prev not in files and os.path.realpath(prev) != me:
        files.append(prev)
    found = set()
    for p in files:
        try:
            txt = ck.read_text(p)
        except OSError:
            continue
        f = ck.contract_fields(txt).get("Standing authorizations") if "Standing authorizations" in txt else None
        if not f:
            continue
        for s, e in ck.auth_entries(f[0]):
            t = ck.flat(f[0][s:e])
            if not t.upper().startswith("UNVERIFIED:"):
                found.add(ck.norm(t))
    return found


def check_authorizations(text, path, prev, scan, report):
    """Prefix every Standing authorizations entry that is not a full grant the owner said with UNVERIFIED:."""
    f = ck.contract_fields(text).get("Standing authorizations")
    if not f or blank_value(f[0]):
        return text
    value, vstart, _ = f
    haystack = [ck.norm(t) for _, t in scan["owner"]] if scan else []
    carried = None
    why = "" if scan else " (no transcript to check against)"
    inserts = []
    for s, e in ck.auth_entries(value):
        entry = ck.flat(value[s:e])
        if entry.upper().startswith("UNVERIFIED:"):
            report.append('UNVERIFIED: already marked, catchup will not act on it: %s' % clip(entry, 90))
            continue
        m = ck.AUTH_SHAPE_RE.match(entry)
        if not m:
            inserts.append(vstart + s)
            report.append('UNVERIFIED: not shaped as "<owner words>" (date) · target: … · one-shot|standing, '
                          'so it cannot be checked; marked so catchup will not act on it: %s' % clip(entry, 90))
            continue
        if carried is None:
            carried = carried_grants(path, prev)
        if ck.norm(entry) in carried:
            continue
        ok, reason = ck.judge_quote(m.group("words"), haystack)
        if ok:
            continue
        inserts.append(vstart + s)
        if reason == "not said":
            report.append('UNVERIFIED: no owner message of this session says "%s"%s; rewritten so catchup '
                          'will not act on it' % (clip(m.group("words"), 90), why))
        else:
            report.append('UNVERIFIED: %s: "%s"; rewritten so catchup will not act on it'
                          % (reason, clip(m.group("words"), 90)))
    for pos in sorted(inserts, reverse=True):
        text = text[:pos] + "UNVERIFIED: " + text[pos:]
    return text


def check_rulings(text, path, root, report):
    f = ck.contract_fields(text).get("Rulings this session")
    if not f or blank_value(f[0]):
        return
    base = os.path.dirname(os.path.abspath(path))
    for m in re.finditer(r"->\s*(\S+)", f[0]):
        p = re.sub(r"[.,;)\]`]+$", "", m.group(1).strip("`("))
        p = re.sub(r":\d+(-\d+)?$", "", p)
        full = os.path.expanduser(p)
        cands = [full] if os.path.isabs(full) else [os.path.join(root, full), os.path.join(base, full)]
        if not any(os.path.exists(c) for c in cands):
            report.append("WARN: a ruling is recorded at %s, which does not exist" % p)


def check_consistency(text, report):
    fields = ck.contract_fields(text)
    pending = ck.bullets(ck.section(text, "Pending Items"))
    if fields.get("Next action"):
        pending.append(fields["Next action"][0])
    sources = []
    for label in ("Blocked on", "Verification state"):
        if fields.get(label):
            sources.append(fields[label][0])
    sources.extend(re.split(r"(?<=[.!?])\s+|\n", ck.quick_summary(text)))
    sources = [s for s in sources if DONE_RE.search(s)]
    for item in pending:
        iw = {w for w in ck.wordset(item) if len(w) >= 4 and w not in STOP}
        if len(iw) < 3:
            continue
        for s in sources:
            common = iw & ck.wordset(s)
            if len(common) >= 3 and len(common) / len(iw) >= 0.5:
                report.append('WARN: pending item may already be done: "%s" against "%s"'
                              % (clip(item, 80), clip(s, 80)))
                break


def check_constraints(text, prev_text, prev_name, report):
    items = field_items(text, "Standing constraints")
    for it in items:
        if not QUOTED_RE.search(it):
            report.append("CONFIRM OR RETIRE: constraint with no quoted owner words: %s" % clip(it, 110))
    if prev_text:
        for g in vanished(items, field_items(prev_text, "Standing constraints")):
            report.append("DECIDE: constraint in %s is absent now, restore it verbatim or retire it with a "
                          "reason in the dump: %s" % (prev_name, clip(g, 140)))


def mini_not_done(text):
    """Items under a mini dump's **Not Done:** label, up to the next bold label."""
    m = re.search(r"^\*\*Not Done:\*\*(.*?)(?=^\*\*[A-Za-z ]+:\*\*|\Z)", text, re.M | re.S)
    if not m:
        return []
    items = [re.sub(r"^\s*(?:[-*]|\d+[.)])\s*", "", ln).strip() for ln in m.group(1).splitlines()]
    return [i for i in items if i and not blank_value(i)]


def build_render(text, path, root, scan, seal_only, sid):
    fields = ck.contract_fields(text)

    def val(label):
        return re.sub(r"\s+", " ", fields[label][0]).strip() if label in fields else ""

    blocked = val("Blocked on")
    pend = ck.bullets(ck.section(text, "Pending Items"))
    mini = text.lstrip().startswith("# Mini Core Dump")
    if blocked.upper().startswith("USER"):
        status = "blocked"
    elif mini and mini_not_done(text):
        status = "in-progress"
    elif not pend:
        status = "complete"
    else:
        status = "in-progress"
    data = {"session_id": sid, "status": status, "project_root": root, "checkpoint_path": path,
            "timestamp": datetime.now().astimezone().strftime("%a %b %d %Y, %I:%M %p %Z"),
            "emitted": [path]}
    if seal_only:
        return data
    goal_body = ck.section(text, "Initial Goal")
    mini_goal = re.search(r"^\*\*Goal:\*\*(.*)$", text, re.M)
    if not goal_body and mini_goal:
        goal_body = mini_goal.group(1)
    paras = [p for p in re.split(r"\n\s*\n", goal_body.strip()) if p.strip()]
    insights = ck.bullets(ck.section(text, "Session Insights"))
    files = []
    keyfiles = val("Key files")
    if keyfiles and not blank_value(keyfiles):
        for p in re.split(r",\s*(?=[/~`])", keyfiles):
            p = p.strip().strip("`")
            if p:
                files.append({"path": os.path.relpath(p, root) if p.startswith(root + "/") else p, "change": ""})
    data.update({
        "goal": clip(paras[0], 260) if paras else "",
        "pipeline": [clip(i, 150) for i in pend][:10],
        "interrupts": [] if (not blocked or re.match(r"^(AGENT:\s*)?none\b", blocked, re.I)) else [clip(blocked, 220)],
        "stack_trace": [clip(i, 110) for i in ck.bullets(ck.section(text, "Agent Actions"))][-20:],
        "files": files,
        "coprocessor": {"worked": [clip(i, 130) for i in insights if not FAIL_RE.search(i[:90])][:8],
                        "failed": [clip(i, 130) for i in insights if FAIL_RE.search(i[:90])][:8]},
    })
    ipc = val("ipc alias").strip("`")
    if ipc and not blank_value(ipc):
        data["ipc"] = ipc
    if scan and scan.get("last_model"):
        data["model"] = scan["last_model"]
    return data


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("checkpoint")
    ap.add_argument("--name")
    ap.add_argument("--summary")
    ap.add_argument("--headless", action="store_true")
    ap.add_argument("--mini", action="store_true")
    ap.add_argument("--prev")
    ap.add_argument("--session-id")
    ap.add_argument("--uuid")
    ap.add_argument("--project-root")
    a = ap.parse_args()

    path = os.path.abspath(a.checkpoint)
    if not os.path.isfile(path):
        print("finalize: no such file: %s" % path, file=sys.stderr)
        return 2
    report = []
    sid = a.session_id or stem_of(path)
    uuid = a.uuid or os.environ.get("CLAUDE_CODE_SESSION_ID") or ""
    if not uuid:
        try:
            uuid = ck.read_text(os.path.join(ck.claude_home(), ".current-session-id")).strip()
        except OSError:
            uuid = ""
    root = a.project_root
    if not root:
        d = os.path.dirname(path)
        while d != os.path.dirname(d) and not os.path.isdir(os.path.join(d, ".claude")):
            d = os.path.dirname(d)
        root = d if os.path.isdir(os.path.join(d, ".claude")) else os.path.dirname(path)

    # Format first so the validator and the diffs read the file as it will be kept.
    run(shlex.split(os.environ.get("CK_PRETTIER_CMD") or "npx --no-install prettier") + ["--write", path], 30)

    rc, out, err = run(["bash", VALIDATE, path] + (["--mini"] if a.mini else []), 30)
    if rc != 0:
        print("finalize: %s\nFIX: the checkpoint breaks the parse contract and was NOT indexed. "
              "Repair it with one Edit, then run finalize again.\n%s" % (path, (err or out).strip()))
        return 1
    for ln in out.splitlines():
        if ln.startswith("warn:"):
            report.append("WARN: " + ln[len("warn:"):].strip())
    report.append("OK: parse contract satisfied")

    text = ck.read_text(path)
    prev = find_prev(path, a.prev, uuid, sid, report)
    prev_text = ck.read_text(prev) if prev else ""
    if prev:
        rc, _, err = run(["bash", VALIDATE, path, "--diff-caveats", prev], 30)
        if rc == 3:
            for ln in err.splitlines():
                m = re.match(r"^\s+-\s+(.*)", ln)
                if m:
                    report.append("DECIDE: caveat in %s is absent now, restore it verbatim or retire it with a "
                                  "reason in the dump: %s" % (os.path.basename(prev), clip(m.group(1), 140)))
        elif rc == 0:
            report.append("OK: no caveats vanished since %s" % os.path.basename(prev))
    check_constraints(text, prev_text, os.path.basename(prev) if prev else "", report)

    scan = None
    tpath = ck.session_transcript_path(uuid, os.path.dirname(path)) if uuid else None
    if tpath:
        try:
            scan = ck.scan_transcript(tpath)
        except OSError:
            scan = None
    new_text = check_authorizations(text, path, prev, scan, report)
    if new_text != text:
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(new_text)
        text = new_text

    check_rulings(text, path, root, report)
    check_consistency(text, report)

    link = os.path.join(os.path.dirname(path), "_checkpoint.claude.md")
    if os.path.basename(path) != "_checkpoint.claude.md":
        try:
            if os.path.lexists(link) and not os.path.islink(link):
                report.append("WARN: %s is a regular file, not a link; left alone" % link)
            else:
                tmp = link + ".tmp%d" % os.getpid()
                os.symlink(os.path.basename(path), tmp)
                os.replace(tmp, link)
        except OSError as e:
            report.append("WARN: could not link _checkpoint.claude.md: %s" % e)
    name = a.name or sid
    if a.summary:
        summary = a.summary
    else:
        mini_goal = re.search(r"^\*\*Goal:\*\*(.*)$", text, re.M)
        summary = ck.first_sentence(ck.section(text, "Initial Goal") or (mini_goal.group(1) if mini_goal else ""))
    rc, out, err = run(["bash", WRITE, "--session-id", sid, "--session-uuid", uuid, "--project-root", root,
                        "--checkpoint-path", path, "--name", name, "--summary", summary], 60)
    # write.sh does not propagate its inner failures, so trust the pointer on disk, not the exit code.
    pointer_file = os.path.join(ck.claude_home(), "checkpoints", re.sub(r"[^A-Za-z0-9._-]", "_", sid) + ".json")
    try:
        pointer_ok = rc == 0 and json.loads(ck.read_text(pointer_file)).get("checkpoint_path") == path
    except (OSError, ValueError, AttributeError):
        pointer_ok = False
    if pointer_ok:
        report.append('OK: indexed as "%s", resume with /catchup at %s' % (name, path))
    else:
        report.append("FIX: the pointer write failed, so /catchup cannot find this checkpoint: %s"
                      % clip(err or out or "no output", 200))

    ingest = os.path.join(ck.claude_home(), "subconscious", "scripts", "ingest-checkpoint.sh")
    try:
        wired = "ingest-checkpoint.sh" in ck.read_text(WRITE)
    except OSError:
        wired = False
    if wired and os.access(ingest, os.X_OK):
        report.append("OK: dream ingestion is wired into write.sh")
    else:
        report.append("WARN: dream ingestion will not run (%s)" %
                      ("write.sh no longer calls it" if not wired else "%s is missing or not executable" % ingest))

    print("finalize: %s" % path)
    for ln in report:
        print(ln)
    if not pointer_ok:
        return 1

    seal_only = a.headless or a.mini
    data = build_render(text, path, root, scan, seal_only, sid)
    rdir = os.environ.get("CK_TMP") or os.path.join(ck.claude_home(), "checkpoints", ".render")
    os.makedirs(rdir, mode=0o700, exist_ok=True)
    dpath = os.path.join(rdir, "core-dump-data-%s.json" % re.sub(r"[^A-Za-z0-9._-]", "_", sid))
    fd = os.open(dpath, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    os.chmod(dpath, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False)
    sys.stdout.flush()
    try:
        rc, out, err = run(["/bin/bash", TRACE, dpath] + (["--receipt"] if seal_only else []), 60)
    finally:
        try:
            os.unlink(dpath)
        except OSError:
            pass
    if rc == 0:
        sys.stdout.write(out)
    else:
        print("WARN: the render failed (%s); the checkpoint is indexed regardless" % clip(err or out, 160))
    return 0


if __name__ == "__main__":
    sys.exit(main())
