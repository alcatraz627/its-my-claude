#!/usr/bin/env python3
"""Turns a session transcript into a plain-markdown journal, with no model call.

Says what the owner asked, how each turn ended, what got committed and touched,
and what the session would have cost at API prices. The SessionEnd hook appends
this to its snapshot so every session leaves a record even when nobody ran
/core-dump.

Usage: session-journal.py --transcript FILE [--cwd DIR] [--budget SECS]
Prints markdown on stdout; prints nothing when the transcript has no owner turns.
Always exits 0: a journal failure must never hold up session exit.

The transcript is streamed line by line (a 1M-token session is hundreds of MB),
and a wall-clock budget cuts the scan short rather than overrun the hook.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import time
from collections import OrderedDict

# input, output, cache read, cache write per million tokens (API-price equivalent).
# Same table as the handoff sweep's pairs.py; keep the two in step.
PRICE = {"opus": (4, 20, 0.20, 8), "fable": (10, 50, 0.25, 20), "sonnet": (2, 10, 0.20, 4),
         "haiku": (0.10, 0.50, 0.01, 0.20)}

OWNER_KEEP, OWNER_CLIP = 40, 600
REPLY_KEEP, REPLY_CLIP = 15, 700
FILES_KEEP = 40
COMMITS_PER_REPO = 15
MAX_REPOS = 6
EDIT_TOOLS = ("Write", "Edit", "MultiEdit", "NotebookEdit")


def cost(model, u):
    for k, (pi, po, pr, pw) in PRICE.items():
        if k in (model or ""):
            return (u.get("input_tokens", 0) * pi + u.get("output_tokens", 0) * po
                    + u.get("cache_read_input_tokens", 0) * pr
                    + u.get("cache_creation_input_tokens", 0) * pw) / 1e6
    return None


_REMINDER = re.compile(r"<system-reminder>.*?</system-reminder>", re.S)


def owner_text(e):
    """The owner's own words in a user entry, or None for tool results and injections."""
    if e.get("type") != "user" or e.get("isMeta"):
        return None
    c = e.get("message", {}).get("content")
    if isinstance(c, list):
        if any(isinstance(b, dict) and b.get("type") == "tool_result" for b in c):
            return None
        c = " ".join(b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text")
    if not isinstance(c, str):
        return None
    # Hook output rides along inside the user turn; the owner never typed it.
    t = _REMINDER.sub("", c).strip()
    if not t:
        return None
    if t.startswith(("<task-notification", "<local-command-stdout", "Caveat:", "[keepwarm]",
                     "This session is being continued")):
        return None
    m = re.search(r"<command-name>(/[^<]+)</command-name>", t)
    if m:
        args = re.search(r"<command-args>(.*?)</command-args>", t, re.S)
        return (m.group(1) + " " + (args.group(1).strip() if args else "")).strip()
    if t.startswith("<command-message>"):
        return None
    return t


def is_wake(e):
    """A keep-warm ping: the agent's answer to it is chatter, not the end of a real turn."""
    c = e.get("message", {}).get("content")
    if isinstance(c, list):
        c = " ".join(b.get("text", "") for b in c if isinstance(b, dict))
    return e.get("type") == "user" and isinstance(c, str) and c.lstrip().startswith("[keepwarm]")


def clip(s, n):
    s = re.sub(r"\s+", " ", s or "").strip()
    return s if len(s) <= n else s[:n] + " ..."


def hhmm(ts):
    m = re.search(r"T(\d\d:\d\d)", ts or "")
    return m.group(1) if m else "--:--"


def scan(path, budget):
    """One pass over the transcript. Returns the collected facts."""
    deadline = time.monotonic() + budget
    r = {"owner": [], "replies": [], "files": OrderedDict(), "cost": 0.0, "unpriced": 0,
         "first": None, "last": None, "cut": False, "calls": 0}
    seen = set()
    last_text = None  # (ts, text) of the current turn's final assistant text
    in_wake = False   # replies to a keep-warm ping do not count as a turn's final reply
    with open(path, errors="replace") as f:
        for i, line in enumerate(f):
            if i % 256 == 0 and time.monotonic() > deadline:
                r["cut"] = True
                break
            # Cheap reject for the attachment/bookkeeping lines that dominate big files.
            if not re.search(r'"type": ?"(user|assistant)"', line):
                continue
            try:
                e = json.loads(line)
            except ValueError:
                continue
            ts = e.get("timestamp", "")
            t = owner_text(e)
            if t is not None:
                if last_text:
                    r["replies"].append(last_text)
                last_text = None
                in_wake = False
                r["owner"].append((ts, t))
                r["first"] = r["first"] or ts
                r["last"] = ts or r["last"]
                continue
            if is_wake(e):
                if last_text:
                    r["replies"].append(last_text)
                last_text, in_wake = None, True
                continue
            if e.get("type") != "assistant":
                continue
            r["last"] = ts or r["last"]
            m = e.get("message", {})
            for b in m.get("content") or []:
                if not isinstance(b, dict):
                    continue
                if b.get("type") == "text" and b.get("text", "").strip() and not in_wake:
                    last_text = (ts, b["text"])
                elif b.get("type") == "tool_use" and b.get("name") in EDIT_TOOLS:
                    inp = b.get("input") or {}
                    fp = inp.get("file_path") or inp.get("notebook_path")
                    if fp:
                        r["files"][fp] = r["files"].get(fp, 0) + 1
            u, mid = m.get("usage"), m.get("id")
            if u and mid not in seen:
                seen.add(mid)
                r["calls"] += 1
                c = cost(m.get("model"), u)
                if c is None:
                    r["unpriced"] += 1
                else:
                    r["cost"] += c
    if last_text:
        r["replies"].append(last_text)
    return r


def git_log(repo, since, until):
    try:
        out = subprocess.run(
            ["git", "-c", "core.useBuiltinFSMonitor=false", "-C", repo, "log", "--no-merges",
             f"--since={since}", f"--until={until}", f"-n{COMMITS_PER_REPO}", "--format=%h %s"],
            capture_output=True, text=True, timeout=2).stdout
        return [ln for ln in out.splitlines() if ln.strip()]
    except (subprocess.SubprocessError, OSError):
        return []


def git_toplevel(d):
    try:
        out = subprocess.run(["git", "-C", d, "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, timeout=2).stdout.strip()
        return out or None
    except (subprocess.SubprocessError, OSError):
        return None


def commits(r, cwd, deadline):
    """Commits in the session's repos during its time window: cwd's plus any a touched file lives in."""
    if not r["first"]:
        return []
    dirs = [cwd] if cwd else []
    for fp in r["files"]:
        d = os.path.dirname(fp)
        if d and d not in dirs:
            dirs.append(d)
    roots = []
    for d in dirs:
        if time.monotonic() > deadline or len(roots) >= MAX_REPOS:
            break
        if not os.path.isdir(d):
            continue
        root = git_toplevel(d)
        if root and root not in roots:
            roots.append(root)
    found = []
    for root in roots:
        if time.monotonic() > deadline:
            break
        for ln in git_log(root, r["first"], r["last"] or r["first"]):
            found.append((root, ln))
    return found


def render(r, cwd, deadline):
    n_owner, n_reply = len(r["owner"]), len(r["replies"])
    com = commits(r, cwd, deadline)
    files = list(r["files"].items())
    out = ["## Session Journal", "",
           "> Free record built from the transcript at session end, with no model call.",
           f"> Window {r['first']} to {r['last']}." +
           (" Transcript scan was cut short by its time budget." if r["cut"] else ""), ""]

    out += [f"## Owner Messages ({min(n_owner, OWNER_KEEP)} of {n_owner})", ""]
    for ts, t in r["owner"][-OWNER_KEEP:]:
        out.append(f"- {hhmm(ts)} {clip(t, OWNER_CLIP)}")
    out.append("")

    out += [f"## Final Replies ({min(n_reply, REPLY_KEEP)} of {n_reply})", ""]
    for ts, t in r["replies"][-REPLY_KEEP:]:
        out.append(f"- {hhmm(ts)} {clip(t, REPLY_CLIP)}")
    out.append("")

    out += [f"## Session Commits ({len(com)})", ""]
    out += [f"- `{os.path.basename(root)}` {ln}" for root, ln in com] or ["- _(none in the session window)_"]
    out.append("")

    out += [f"## Files Touched ({len(files)})", ""]
    out += [f"- `{fp}` x{n}" for fp, n in files[-FILES_KEEP:]] or ["- _(no writes or edits)_"]
    if len(files) > FILES_KEEP:
        out.append(f"- _(and {len(files) - FILES_KEEP} earlier files)_")
    out.append("")

    unpriced = f", {r['unpriced']} unpriced" if r["unpriced"] else ""
    cost_line = f"${r['cost']:.2f} API-price equivalent over {r['calls']} model calls{unpriced}"
    out += ["## Session Cost", "", f"- {cost_line}", ""]

    # The dream ingester reads only Session Insights and Pending Items, so the
    # journal rides in on those headings as a compact digest of the above.
    out += ["## Session Insights", "", "**User feedback received:**"]
    out += [f"- {clip(t, OWNER_CLIP)}" for _, t in r["owner"][-OWNER_KEEP:]] or ["- _(none)_"]
    out += ["", "**Notes for future agents:**", f"- Cost: {cost_line}"]
    out += [f"- Commit {os.path.basename(root)} {ln}" for root, ln in com[:10]]
    out += [f"- Touched {len(files)} files, last: {os.path.basename(files[-1][0])}"] if files else []
    out += [f"- Closed turn: {clip(t, 300)}" for _, t in r["replies"][-REPLY_KEEP:]]
    out.append("")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--transcript", required=True)
    ap.add_argument("--cwd", default="")
    ap.add_argument("--budget", type=float, default=3.0)
    a = ap.parse_args()
    started = time.monotonic()
    r = scan(a.transcript, a.budget)
    if not r["owner"]:
        return
    # Leave git a slice of the budget even when the scan ate its share.
    sys.stdout.write(render(r, a.cwd, started + a.budget + 1.0))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # never hold up session exit
        try:
            logdir = os.path.expanduser("~/.claude/logs")
            os.makedirs(logdir, exist_ok=True)
            with open(os.path.join(logdir, "session-journal.log"), "a") as lf:
                lf.write(f"{time.strftime('%FT%T')} {type(exc).__name__}: {exc}\n")
        except OSError:
            pass
    sys.exit(0)
