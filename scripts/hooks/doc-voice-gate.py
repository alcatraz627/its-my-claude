#!/usr/bin/env python3
"""Holds a document written for people to the shape a person can read.

Two failures it catches. A doc meant for a person (a plan, a spec, a
directions file) comes out as the agent's own ledger: internal ids, commit
shas, file:line references, dated rulings, "the spec says X, but". Or it comes
out as a wall of text: table cells and paragraphs hundreds of characters long.

A note during an edit was not enough: clanky-opus got it three times on
DIRECTIONS.md (2026-10-22), decided the file was for agents, kept writing, and
told the owner it had written a better doc. So the check now runs again when
the turn ends, on the file as it stands. While a doc written this turn still
fails, the turn may not end (twice), and never on a reply that calls that doc
better or fixed. If the agent ends the turn anyway, the owner is told.

Runtime contract:
  doc-voice-gate.py          PostToolUse on Write/Edit/MultiEdit: note + record
  doc-voice-gate.py stop     Stop: re-check this turn's docs, block or tell
Scope: .md files under a `docs/` folder, or any .md whose frontmatter names a
non-agent `reader:`. Skips anything under `.claude/` or `archive/`, and
changelogs, RCAs and ADRs. `reader: agent` exempts a file outside `docs/`
only; under `docs/` only the owner's list does
(~/.claude/doc-voice-exempt.txt, one path glob per line). Fenced code and
everything after a final Sources / References / Appendix heading are not
counted.

Mute: touch ~/.claude/.no-doc-voice-gate · One-shot: DOC_VOICE_OFF=1
Test: bash ~/.claude/scripts/hooks/doc-voice-gate.test.sh
"""
import fnmatch
import json
import os
import re
import subprocess
import sys

# Planning shorthand alone (V1, T3) is common and mild; the ledger voice shows
# as several kinds at once (ids plus shas, file:line or dated rulings).
THRESHOLD = 8
MIN_KINDS = 2
# Measured on DIRECTIONS.md: the wall version had 13 table cells over 160
# characters and 2 paragraphs over 400; its rewrite had none. A plain doc the
# owner approved has 2 long cells, so one or two are allowed.
LONG_CELL, LONG_BLOCK, HUGE_BLOCK = 160, 400, 900
MAX_LONG_CELLS, MAX_LONG_BLOCKS = 3, 2
MAX_STOP_BLOCKS = 2

STATE_DIR = os.environ.get("DOC_VOICE_STATE", "/tmp")
EXEMPT = os.environ.get("DOC_VOICE_EXEMPT", os.path.expanduser("~/.claude/doc-voice-exempt.txt"))
MUTE = os.path.expanduser("~/.claude/.no-doc-voice-gate")

SIGNALS = {
    "internal id": re.compile(r"\b[A-Z]{2,5}-\d{1,4}\b|\b[A-Z]\d{1,2}[a-z]?\b(?=[\s,.;:)\]|])"),
    "commit sha": re.compile(r"\b(?=[0-9a-f]*\d)(?=[0-9a-f]*[a-f])[0-9a-f]{7,40}\b"),
    "file:line": re.compile(r"[\w./-]+\.[a-z]{1,5}:\d+|`:\d+`"),
    "ledger framing": re.compile(
        r"\(\d{4}-\d{2}-\d{2}\b|\b(?:standing|owner) (?:decision|ruling)s?\b|\bruling\b"
        r"|\b(?:accepted|decided|ruled|agreed) (?:on )?\d{4}-\d{2}-\d{2}"
        r"|\bpreviously\b|\bno longer\b|\bused to\b|\bpre-fix\b|\bpost-fix\b|\bsuperseded\b"
        r"|\bcontrary to\b|\bthe (?:spec|doc|cprd|prd|plan|source|brief) (?:says|said|claims|asked)\b",
        re.IGNORECASE,
    ),
}
TAIL = re.compile(r"^#{1,6}\s*(sources|references|appendix|evidence)\b", re.IGNORECASE | re.MULTILINE)
FENCE = re.compile(r"^```.*?^```", re.DOTALL | re.MULTILINE)
SKIP_NAME = re.compile(r"changelog|(^|[-_/])rca([-_./]|$)|(^|[-_/])adr([-_./]|$)", re.IGNORECASE)
LIST_ITEM = re.compile(r"[-*+]\s|\d+[.)]\s|>\s?")
# A reply that tells the owner a doc got better, and one that admits it still fails.
CLAIM = re.compile(r"\b(better|cleaner|clearer|plainer|tighter|shorter|rewrote|rewritten|reworked|fixed|"
                   r"simplified|readable|reads (?:well|cleanly|better))\b", re.IGNORECASE)
ADMIT = re.compile(r"\bstill (?:fails|flagged|reads like|has)|\bdoc(?:-| )voice\b|\bwall of text\b|\bfails the doc check\b",
                   re.IGNORECASE)


def reader_of(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        return None
    r = re.search(r"^reader:\s*(.+)$", m.group(1), re.MULTILINE)
    return r.group(1).strip().lower() if r else None


def owner_exempt(path):
    try:
        with open(EXEMPT) as f:
            globs = [line.strip() for line in f if line.strip() and not line.startswith("#")]
    except OSError:
        return False
    return any(fnmatch.fnmatch(path, os.path.expanduser(g)) for g in globs)


def in_scope(path, text):
    if (not path.endswith(".md") or "/.claude/" in path or "/archive/" in path
            or SKIP_NAME.search(os.path.basename(path)) or owner_exempt(path)):
        return False
    reader = reader_of(text)
    under_docs = "/docs/" in path
    if reader is not None and reader.startswith("agent"):
        # An agent can write that line itself, so it does not exempt a doc under docs/.
        return under_docs
    return reader is not None or under_docs


def body_of(text):
    text = re.sub(r"^---\n.*?\n---\n", "", text, count=1, flags=re.DOTALL)
    text = FENCE.sub("", text)
    tails = list(TAIL.finditer(text))
    return text[: tails[-1].start()] if tails else text


def score(text):
    body = body_of(text)
    hits = {name: rx.findall(body) for name, rx in SIGNALS.items()}
    return {k: v for k, v in hits.items() if v}


def fires(hits):
    return len(hits) >= MIN_KINDS and sum(len(v) for v in hits.values()) >= THRESHOLD


def wall(text):
    """Table cells and paragraphs too long to read at a glance. A list item
    counts as its own paragraph, with its wrapped lines joined."""
    blocks, cur, cells = [], [], []
    for line in body_of(text).splitlines():
        s = line.strip()
        if s.startswith("|"):
            if cur:
                blocks.append(" ".join(cur))
                cur = []
            cells += [c.strip() for c in s.strip("|").split("|")]
            continue
        if not s or s.startswith("#") or LIST_ITEM.match(s):
            if cur:
                blocks.append(" ".join(cur))
                cur = []
            if s and not s.startswith("#"):
                cur = [s]
            continue
        cur.append(s)
    if cur:
        blocks.append(" ".join(cur))
    return [c for c in cells if len(c) > LONG_CELL], [b for b in blocks if len(b) > LONG_BLOCK]


def wall_fires(long_cells, long_blocks):
    return (len(long_cells) > MAX_LONG_CELLS or len(long_blocks) > MAX_LONG_BLOCKS
            or any(len(b) > HUGE_BLOCK for b in long_blocks))


def measure(text):
    """The doc's faults as numbers, for telling worse from better: ledger marks
    (0 unless the ledger check fires), long cells, long paragraphs."""
    hits = score(text)
    cells, blocks = wall(text)
    return {"ledger": sum(len(v) for v in hits.values()) if fires(hits) else 0,
            "cells": len(cells), "blocks": len(blocks), "fails": bool(fires(hits) or wall_fires(cells, blocks))}


def committed_text(path):
    """The doc as last committed, or None for a new or untracked file."""
    d = os.path.dirname(path) or "."
    top = subprocess.run(["git", "-C", d, "rev-parse", "--show-toplevel"], capture_output=True, text=True)
    if top.returncode:
        return None
    rel = os.path.relpath(os.path.realpath(path), os.path.realpath(top.stdout.strip()))
    r = subprocess.run(["git", "-C", d, "show", "HEAD:%s" % rel], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else None


def worse(base, now):
    """True when the agent's own edits are the problem: the doc is new or used to
    pass and now fails, or it already failed and got worse on some measure."""
    if not now["fails"]:
        return False
    if base is None or not base["fails"]:
        return True
    return any(now[k] > base[k] for k in ("ledger", "cells", "blocks"))


def findings(path):
    """What is wrong with the doc as it stands now, as sentences; empty when it reads fine."""
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            text = f.read()
    except OSError:
        return []
    if not in_scope(path, text):
        return []
    out = []
    hits = score(text)
    if fires(hits):
        parts = ", ".join("%d %s" % (len(v), k) for k, v in hits.items())
        examples = "; ".join(str(v[0]) if isinstance(v[0], str) else "".join(v[0]) for v in hits.values())
        out.append("it reads like an internal ledger (%s; e.g. %s). Say what is true now in plain sentences; "
                   "move ids, shas and file:line to a Sources section at the end" % (parts, examples))
    cells, blocks = wall(text)
    if wall_fires(cells, blocks):
        sample = (cells or blocks)[0][:90]
        out.append("it is a wall of text (%d table cells over %d characters, %d paragraphs over %d; e.g. \"%s...\"). "
                   "One short fact per cell and per bullet; detail goes to Sources or its own section"
                   % (len(cells), LONG_CELL, len(blocks), LONG_BLOCK, sample))
    if out and reader_of(text) is None:
        out.append("name the reader in one line first (frontmatter `reader: <who>`)")
    return out


def warn_log(action):
    subprocess.run(["bash", os.path.expanduser("~/.claude/scripts/hooks/warn-log.sh"), "--hook", "doc-voice-gate",
                    "--action", action, "--heeded", "unknown"], capture_output=True)


def state_path(sid):
    return os.path.join(STATE_DIR, "claude-docgate-%s.json" % (sid or "unknown")[:8])


def load(sid):
    try:
        with open(state_path(sid)) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {"docs": [], "blocks": 0}


def save(sid, st):
    with open(state_path(sid), "w") as f:
        json.dump(st, f)


def post(data):
    if data.get("tool_name") not in ("Write", "Edit", "MultiEdit"):
        return 0
    path = (data.get("tool_input") or {}).get("file_path") or ""
    found = findings(path)
    if not found:
        return 0
    st = load(data.get("session_id"))
    if path not in st["docs"]:
        st["docs"].append(path)
        # The baseline is taken once, at the first edit of the turn: the doc as committed before it.
        old = committed_text(path)
        st.setdefault("base", {})[path] = measure(old) if old is not None else None
    save(data.get("session_id"), st)
    warn_log("nudge")
    base = st.get("base", {}).get(path)
    if base and base["fails"]:
        tail = ("It already failed before this turn, so it is not yours to rewrite unless asked, but the turn "
                "will not end if it is worse than it was, or if you call it better while it fails.")
    else:
        tail = "This is checked again when your turn ends, and the turn will not end while it fails."
    msg = "%s does not read as a doc for a person: %s. %s" % (os.path.basename(path), "; ".join(found), tail)
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}))
    return 0


def stop(data):
    sid = data.get("session_id")
    st = load(sid)
    if not st["docs"]:
        return 0
    failing = {p: findings(p) for p in st["docs"]}
    failing = {p: f for p, f in failing.items() if f}
    reply = data.get("last_assistant_message") or ""
    names = [os.path.splitext(os.path.basename(p))[0] for p in failing]
    claims = bool(CLAIM.search(reply) and not ADMIT.search(reply)
                  and any(n.lower() in reply.lower() for n in names))
    # Only the agent's own doing holds the turn: a doc it made fail or made worse, or a claim it is better.
    if not claims:
        failing = {p: f for p, f in failing.items() if worse(st.get("base", {}).get(p), measure(open(p, errors="replace").read()))}
    if not failing:
        os.remove(state_path(sid)) if os.path.exists(state_path(sid)) else None
        warn_log("cleared")
        return 0
    detail = " ".join("%s: %s." % (os.path.basename(p), "; ".join(f)) for p, f in failing.items())
    if st["blocks"] < MAX_STOP_BLOCKS or (claims and st["blocks"] < MAX_STOP_BLOCKS + 1):
        st["blocks"] += 1
        save(sid, st)
        warn_log("block")
        lead = ("Your reply tells the owner the doc is better, and it still fails the doc check. "
                if claims else "A doc you wrote this turn still fails the doc check. ")
        print(json.dumps({"decision": "block", "reason": lead + detail + " Rewrite it until it passes. If you "
                          "decide it should stay as it is, say so in your reply in one sentence (that it still "
                          "fails the doc check, and why); never call it better or fixed."}))
        return 0
    # Out of blocks: let the turn end, and make sure the owner hears it from the hook, not the agent.
    os.remove(state_path(sid))
    warn_log("ignored")
    print(json.dumps({"systemMessage": "doc check: %s still fails after %d reminders. %s"
                      % (", ".join(os.path.basename(p) for p in failing), st["blocks"], detail)}))
    return 0


def main(argv):
    if os.environ.get("DOC_VOICE_OFF") == "1" or os.path.exists(MUTE):
        return 0
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    try:
        return stop(data) if argv[:1] == ["stop"] else post(data)
    except Exception:
        return 0     # a bug here must never block a write or a turn by accident


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
