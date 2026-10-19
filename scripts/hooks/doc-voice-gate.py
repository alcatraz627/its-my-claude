#!/usr/bin/env python3
"""Flags a document written for people that reads like the agent's own ledger.

The failure it catches: a doc meant for a person (a plan, a spec, a parity
map) comes out full of the agent's bookkeeping, internal ids (CAP-12, A5),
commit shas, file:line references, dated rulings, and "the spec says X, but"
framing that argues with source documents the reader never saw. The owner has
asked for plain, direct docs; this makes the slip visible the moment the file
is written.

Runtime contract: PostToolUse on Write/Edit/MultiEdit. Looks only at .md files
under a `docs/` folder, or any .md whose frontmatter names a non-agent
`reader:`. Skips `reader: agent`, anything under a `.claude/` or `archive/`
folder, and changelogs, RCAs and ADRs, which are histories by design. Fenced code and
everything after a final Sources / References / Appendix heading are not
counted. Dry-run by default: it adds a note for the agent and logs telemetry;
DOC_VOICE_ENFORCE=1 turns the note into a block the agent must answer.

Mute: touch ~/.claude/.no-doc-voice-gate · One-shot: DOC_VOICE_OFF=1
Test: bash ~/.claude/scripts/hooks/doc-voice-gate.test.sh
"""
import json
import os
import re
import subprocess
import sys

# Planning shorthand alone (V1, T3) is common and mild; the ledger voice shows
# as several kinds at once (ids plus shas, file:line or dated rulings).
THRESHOLD = 8
MIN_KINDS = 2

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


def reader_of(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        return None
    r = re.search(r"^reader:\s*(.+)$", m.group(1), re.MULTILINE)
    return r.group(1).strip().lower() if r else None


def in_scope(path, text):
    if (not path.endswith(".md") or "/.claude/" in path or "/archive/" in path
            or SKIP_NAME.search(os.path.basename(path))):
        return False
    reader = reader_of(text)
    if reader is not None:
        return not reader.startswith("agent")
    return "/docs/" in path


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


def message(path, hits, has_reader):
    parts = ", ".join("%d %s" % (len(v), k) for k, v in hits.items())
    examples = "; ".join(str(v[0]) if isinstance(v[0], str) else "".join(v[0]) for v in hits.values())
    lines = [
        "%s reads like an internal ledger, not a doc for a person (%s; e.g. %s)." % (os.path.basename(path), parts, examples),
        "Rewrite for the reader: say what is true now in plain sentences. Drop internal ids, shas and file:line "
        "from the body (a short Sources section at the end may keep them), and drop the history of how a "
        "decision was reached or how this differs from a source doc.",
    ]
    if not has_reader:
        lines.append("Name the reader in one line first (frontmatter `reader: <who>`).")
    return " ".join(lines)


def main():
    if os.environ.get("DOC_VOICE_OFF") == "1" or os.path.exists(os.path.expanduser("~/.claude/.no-doc-voice-gate")):
        return 0
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    if data.get("tool_name") not in ("Write", "Edit", "MultiEdit"):
        return 0
    path = (data.get("tool_input") or {}).get("file_path") or ""
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            text = f.read()
    except OSError:
        return 0
    if not in_scope(path, text):
        return 0
    hits = score(text)
    if not fires(hits):
        return 0
    msg = message(path, hits, reader_of(text) is not None)
    enforce = os.environ.get("DOC_VOICE_ENFORCE") == "1"
    subprocess.run(
        ["bash", os.path.expanduser("~/.claude/scripts/hooks/warn-log.sh"), "--hook", "doc-voice-gate",
         "--action", "block" if enforce else "nudge", "--heeded", "unknown"],
        capture_output=True,
    )
    if enforce:
        print(json.dumps({"decision": "block", "reason": msg}))
    else:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
