#!/usr/bin/env python3
"""Pick up another session's workstream in a fresh agent, without reviving it.

Given an ipc alias (clanky-opus) or a session id prefix, this writes one digest
a new agent can read in a single call: what the owner asked, what got committed,
the open task list, the last thing the session said, the repo's state now, and
any hibernation note. No model call, so it costs nothing to build, and the new
agent pays for a few thousand tokens instead of rebuilding the old session's
whole cache. A core-dump newer than the session's last turn is used as is.

Usage: resume-from.py <alias|sid> [--out FILE]
Prints the digest path on the first line, then a one-line summary.
/catchup --from <alias|sid> runs this and reads the result.
"""
import json
import os
import re
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import usage5h  # noqa: E402

G = os.path.join(HOME, ".claude")
JOURNAL = os.path.join(G, "scripts", "session-mgmt", "session-journal.py")
RESOLVE_STORE = os.path.join(G, "scripts", "task-table", "resolve-store.sh")
INDEX = os.path.join(G, "checkpoints", "index.jsonl")
OUT_DIR = os.path.join(G, "checkpoints", "resume")
FRESH_DUMP_S = 600     # a dump this close to the last turn already says everything


def run(cmd, cwd=None, timeout=30):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd, timeout=timeout)
        return r.stdout.strip() if r.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError):
        return ""


def resolve(target):
    """(sid, alias) for an ipc alias or a session id prefix."""
    if re.fullmatch(r"[0-9a-f-]{6,36}", target):
        t = usage5h.transcript_for_prefix(target)
        sid = os.path.basename(t)[:-6] if t else None
        alias = None
        if sid:
            peers = json.loads(run(["claude-ipc", "peers", "--by-session"]) or "{}").get("peers", [])
            for p in peers:
                if p.get("sessionId") == sid and p.get("aliases"):
                    alias = p["aliases"][0]
        return sid, alias
    peers = json.loads(run(["claude-ipc", "peers", "--by-session"]) or "{}").get("peers", [])
    for p in peers:
        if target in (p.get("aliases") or []) and not p.get("sessionId", "").startswith("svc:"):
            return p["sessionId"], target
    return None, None


def read_lines(transcript):
    with open(transcript, errors="replace") as f:
        for line in f:
            try:
                yield json.loads(line)
            except ValueError:
                continue


def transcript_facts(transcript):
    """The launch folder, and the session's last reply in full."""
    cwd, last_reply = None, ""
    for o in read_lines(transcript):
        cwd = cwd or o.get("cwd")
        msg = o.get("message")
        if o.get("type") == "assistant" and isinstance(msg, dict) and isinstance(msg.get("content"), list):
            texts = [b.get("text", "") for b in msg["content"] if isinstance(b, dict) and b.get("type") == "text"]
            text = "\n".join(t for t in texts if t.strip())
            if len(text) > 200:
                last_reply = text
    return cwd, last_reply


def newest_dump(sid):
    """The newest owner-grade checkpoint for this session, as (path, epoch)."""
    best = None
    try:
        with open(INDEX) as f:
            for line in f:
                try:
                    e = json.loads(line)
                except ValueError:
                    continue
                if e.get("session_id") != sid or e.get("kind") in ("precompact",):
                    continue
                p = e.get("checkpoint_path")
                if p and os.path.exists(p):
                    ts = os.path.getmtime(p)
                    if best is None or ts > best[1]:
                        best = (p, ts)
    except OSError:
        pass
    return best


def task_section(sid):
    store = run(["bash", RESOLVE_STORE, "--as-session", sid])
    if not store or not os.path.isdir(store):
        return ["_No task store resolved for this session._"]
    rows = []
    for name in os.listdir(store):
        if name.endswith(".json"):
            try:
                with open(os.path.join(store, name)) as f:
                    rows.append(json.load(f))
            except (OSError, ValueError):
                pass
    rows.sort(key=lambda t: int(t.get("id", 0)) if str(t.get("id", "")).isdigit() else 0)
    open_rows = [t for t in rows if t.get("status") != "completed"]
    done = len(rows) - len(open_rows)
    out = ["%d of %d tasks completed. Store: `%s`" % (done, len(rows), store), ""]
    for t in open_rows:
        out.append("- [%s] #%s %s" % (t.get("status"), t.get("id"), t.get("subject", "")))
        d = (t.get("description") or "").strip().replace("\n", " ")
        if d:
            out.append("  %s" % d[:400])
    if not open_rows:
        out.append("_Nothing open in the task list._")
    return out


def git_section(cwd):
    if not cwd or not run(["git", "-C", cwd, "rev-parse", "--git-dir"]):
        return ["_Not a git repo._"]
    branch = run(["git", "-C", cwd, "branch", "--show-current"])
    dirty = run(["git", "-C", cwd, "status", "--short"])
    ahead = run(["git", "-C", cwd, "rev-list", "--count", "@{upstream}..HEAD"])
    log = run(["git", "-C", cwd, "log", "--oneline", "-5"])
    out = ["Branch `%s`, %s ahead of upstream, %d uncommitted file(s)." % (
        branch or "?", ahead or "?", len(dirty.splitlines()) if dirty else 0), "", "```", log, "```"]
    return out


def main(argv):
    if not argv or argv[0].startswith("-"):
        print(__doc__)
        return 2
    target = argv[0]
    out = argv[argv.index("--out") + 1] if "--out" in argv else None
    sid, alias = resolve(target)
    if not sid:
        print("no session found for '%s' (tried ipc aliases and transcript ids)" % target, file=sys.stderr)
        return 4
    transcript = usage5h.transcript_for_prefix(sid)
    if not transcript:
        print("no transcript for session %s" % sid, file=sys.stderr)
        return 4
    last_epoch, ctx = usage5h.last_turn(transcript)
    dump = newest_dump(sid)
    if dump and last_epoch and dump[1] >= last_epoch - FRESH_DUMP_S:
        print(dump[0])
        print("a core-dump newer than the last turn exists; /catchup it directly")
        return 0

    cwd, last_reply = transcript_facts(transcript)
    name = alias or sid[:8]
    lines = ["# Resume digest: %s" % name, "",
             "> Built %s from the transcript, with no model call. Session `%s`, launched in `%s`." % (
                 time.strftime("%Y-%m-%d %H:%M"), sid, cwd or "?"),
             "> Last turn %s; context then %sk tokens. The old session is not revived; continue its work here." % (
                 time.strftime("%Y-%m-%d %H:%M", time.localtime(last_epoch)) if last_epoch else "unknown",
                 (ctx // 1000) if ctx else "?"), ""]
    h = usage5h.load(sid).get("hibernate")
    if h:
        lines += ["## Hibernation note", "", "Strategy `%s`: %s" % (h["strategy"], h.get("note") or "(no note)"), ""]
    if dump:
        lines += ["## Older checkpoint", "",
                  "`%s` predates the last turn; the sections below cover what came after it." % dump[0], ""]
    lines += ["## Open tasks", ""] + task_section(sid) + [""]
    lines += ["## Repo now", ""] + git_section(cwd) + [""]
    lines += ["## Last reply in full", "", last_reply or "_none_", ""]
    journal = run([sys.executable, JOURNAL, "--transcript", transcript, "--cwd", cwd or HOME, "--budget", "20"], timeout=40)
    # The journal's own Session Insights repeats the sections above it.
    journal = journal.split("\n## Session Insights")[0]
    lines += [journal.replace("## Session Journal", "## Session journal", 1)]

    os.makedirs(OUT_DIR, exist_ok=True)
    out = out or os.path.join(OUT_DIR, "%s-%s.md" % (time.strftime("%Y%m%d-%H%M"), name))
    with open(out, "w") as f:
        f.write("\n".join(lines).rstrip() + "\n")
    print(out)
    print("digest for %s (%s): %d lines" % (name, sid[:8], len(lines)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
