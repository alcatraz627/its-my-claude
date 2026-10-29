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

A third failure is a doc that is hard to skim: dense paragraphs, lines spliced
with semicolons, runs of sentences that only name code and paths. Those checks
are shared with the GitHub prose gate through the prose engine
(scripts/style/prose-lint.py, surface "doc"), with a few more
allowed here because a doc is longer than a comment.

Runtime contract:
  doc-voice-gate.py          PostToolUse on Write/Edit/MultiEdit: note + record
  doc-voice-gate.py stop     Stop: re-check this turn's docs, block or tell
Scope: .md files under a `docs/` folder, or any .md whose frontmatter names a
non-agent `reader:` (that includes a file under `.claude/`). Skips `archive/`,
other `.claude/` files, and changelogs, RCAs and ADRs. `reader: agent` exempts
a file outside `docs/` only; under `docs/` only the owner's list does
(~/.claude/doc-voice-exempt.txt, one path glob per line). Fenced code and
everything after a final Sources / References / Appendix heading are not
counted.
A doc under `.claude/output/` that names no reader is judged only when the
reply at the end of the turn points the owner at it by its full path, because
that is the moment it becomes something a person reads. A seat's own output is
never judged this way. `reader: agent` at the top of the file clears it.

Mute: touch ~/.claude/.no-doc-voice-gate · One-shot: DOC_VOICE_OFF=1
Test: bash ~/.claude/scripts/hooks/doc-voice-gate.test.sh
"""
import fnmatch
import importlib.util
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SURFACE = "doc"          # the style/profiles.json row for documents
SKIM_TELLS = ("dense-block", "spliced-line", "mechanism-run")
_ENGINE = None


def engine():
    """The prose engine (scripts/style/prose-lint.py), loaded on first use."""
    global _ENGINE
    if _ENGINE is None:
        spec = importlib.util.spec_from_file_location("prose_lint", os.path.join(HERE, "..", "style", "prose-lint.py"))
        _ENGINE = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(_ENGINE)
    return _ENGINE

# Planning shorthand alone (V1, T3) is common and mild; the ledger voice shows
# as several kinds at once (ids plus shas, file:line or dated rulings).
THRESHOLD = 8
MIN_KINDS = 2
# Measured on DIRECTIONS.md: the wall version had 13 table cells over 160
# characters and 2 paragraphs over 400; its rewrite had none. A plain doc the
# owner approved has 2 long cells, so one or two are allowed.
LONG_CELL, LONG_BLOCK, HUGE_BLOCK = 160, 400, 900
MAX_LONG_CELLS, MAX_LONG_BLOCKS = 3, 2
# Skim checks (the engine's dense-block, spliced-line and mechanism-run tells). Across the docs/ folders on this machine
# the approved plain docs have none of the three, and the ledger-style ones have
# several, so a few of each are allowed before the doc is called hard to skim.
MAX_DENSE, MAX_SPLICED, MAX_MECHANISM = 2, 2, 2
MAX_STOP_BLOCKS = 2
# Shape signals from doc-writing.md section 6b. Agent codes in running text are a
# ledger on their own once there are this many (a table's id column does not count).
MAX_PROSE_CODES = 10
# Sentences over this many words, more than this many times.
LONG_SENTENCE_WORDS, MAX_LONG_SENTENCES = 40, 3
# A page this long needs a heading at least this often, or it is one flat wall.
FLAT_PAGE_WORDS, WORDS_PER_HEADING = 2000, 600

STATE_DIR = os.environ.get("DOC_VOICE_STATE", "/tmp")
EXEMPT = os.environ.get("DOC_VOICE_EXEMPT", os.path.expanduser("~/.claude/doc-voice-exempt.txt"))
MUTE = os.path.expanduser("~/.claude/.no-doc-voice-gate")

# Names a reader already knows, which the id pattern would otherwise count as an
# agent's code: cloud services, percentiles, encodings, hashes and paper sizes.
# Codes agents use with each other (A4, D2, S1, V1) stay counted.
KNOWN_TOKENS = {"S3", "EC2", "P50", "P90", "P95", "P99", "UTF-8", "UTF-16", "SHA-1", "SHA-256", "SHA-512",
                "ISO-8601", "IPV4", "IPV6", "H1", "H2", "H3", "H4", "H5", "H6", "MP3", "MP4", "K8S", "E2E"}
# The source-file extensions a file:line can point into, so host:port and times do not count.
CODE_EXT = (r"(?:py|pyi|ts|tsx|js|jsx|mjs|cjs|go|rs|rb|java|kt|swift|c|h|cc|cpp|hpp|cs|php|sh|bash|zsh|sql|"
            r"ya?ml|json|toml|md|mdx|html|css|scss|vue|svelte|tf|lua|ex|exs)")
_ID = re.compile(r"\b[A-Z]{2,5}-\d{1,4}\b|\b[A-Z]\d{1,2}[a-z]?\b(?=[\s,.;:)\]|])")


class _Ids:
    """The internal-id pattern, minus tokens a reader already knows (S3, P95, UTF-8)."""

    def findall(self, text):
        return [t for t in _ID.findall(text) if t.upper() not in KNOWN_TOKENS]


SIGNALS = {
    "internal id": _Ids(),
    "commit sha": re.compile(r"\b(?=[0-9a-f]*\d)(?=[0-9a-f]*[a-f])[0-9a-f]{7,40}\b"),
    "file:line": re.compile(r"[\w./\[\]-]+\." + CODE_EXT + r":\d+\b|`:\d+`"),
    # "Used to", "no longer" and "previously" read as plain history in ordinary prose
    # ("the key used to sign"), so only dated rulings and spec-arguing count here.
    "ledger framing": re.compile(
        r"\(\d{4}-\d{2}-\d{2}\b|\b(?:standing|owner) (?:decision|ruling)s?\b|\bruling\b"
        r"|\b(?:accepted|decided|ruled|agreed) (?:on )?\d{4}-\d{2}-\d{2}"
        r"|\bpre-fix\b|\bpost-fix\b|\bsuperseded\b"
        r"|\bcontrary to\b|\bthe (?:spec|doc|cprd|prd|plan|source|brief) (?:says|said|claims|asked)\b",
        re.IGNORECASE,
    ),
    # A living status doc is rewritten to be current, so "Updated 20:15" or
    # "Status at ~22:10" is an audit trail about the doc, not information in it.
    "update stamp": re.compile(
        r"\b(?:updated|status at|as of|refreshed|checked at|verified at)\s*(?:on\s+|at\s+)?~?\s*"
        r"(?:\d{4}-\d{2}-\d{2}|\d{1,2}:\d{2})",
        re.IGNORECASE,
    ),
}
TAIL = re.compile(r"^#{1,6}\s*(sources|references|appendix|evidence)\b", re.IGNORECASE | re.MULTILINE)
# A fence may be indented under a list item and may use tildes, as in readability_core.
FENCE = re.compile(r"^[ \t]*(```|~~~).*?^[ \t]*\1", re.DOTALL | re.MULTILINE)
SEPARATOR_CELL = re.compile(r"^:?-+:?$")
SKIP_NAME = re.compile(r"changelog|(^|[-_/])rca([-_./]|$)|(^|[-_/])adr([-_./]|$)", re.IGNORECASE)
LIST_ITEM = re.compile(r"[-*+]\s|\d+[.)]\s|>\s?")
# A reply that tells the owner a doc got better, and one that admits it still fails.
CLAIM = re.compile(r"\b(better|cleaner|clearer|plainer|tighter|shorter|rewrote|rewritten|reworked|fixed|"
                   r"simplified|readable|reads (?:well|cleanly|better))\b", re.IGNORECASE)
ADMIT = re.compile(r"\bstill (?:fails?|flagged|reads like|has|have)|\bdoc(?:-| )voice\b|\bwall of text\b"
                   r"|\bfails? the doc check\b", re.IGNORECASE)
SENTENCE = re.compile(r"(?<=[.!?])\s+|\n+")


def sentences_naming(reply, path):
    """The reply's sentences that name this doc. The file name with its extension
    always counts. The bare stem counts as a whole word only when it cannot be an
    ordinary word (DIRECTIONS, user-org-access, ADR-004), so "testing" in "fixed the
    testing job" does not name testing.md."""
    name = os.path.basename(path)
    stem = os.path.splitext(name)[0]
    distinct = bool(re.search(r"[A-Z0-9_-]", stem))
    stem_rx = re.compile(r"(?<![\w.-])%s(?![\w-])" % re.escape(stem)) if distinct else None
    return [s for s in SENTENCE.split(reply) if name.lower() in s.lower() or (stem_rx and stem_rx.search(s))]


def claims_better(reply, path):
    """A sentence that names the doc and says it got better, without admitting it still fails."""
    return any(CLAIM.search(s) and not ADMIT.search(s) for s in sentences_naming(reply, path))


def admits(reply, path):
    """A sentence that names the doc and says plainly that it still fails."""
    return any(ADMIT.search(s) for s in sentences_naming(reply, path))


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


def skippable(path):
    return (not path.endswith(".md") or "/archive/" in path
            or SKIP_NAME.search(os.path.basename(path)) or owner_exempt(path))


def in_scope(path, text):
    if skippable(path):
        return False
    reader = reader_of(text)
    under_docs = "/docs/" in path
    if reader is not None and reader.startswith("agent"):
        # An agent can write that line itself, so it does not exempt a doc under docs/.
        return under_docs and "/.claude/" not in path
    if "/.claude/" in path:
        # Agent working folders are skipped unless the file promises a human reader.
        return reader is not None
    return reader is not None or under_docs


def handover_candidate(path, text):
    """A doc under .claude/output/ that names no reader. It is judged only if the
    reply hands it to the owner (see stop)."""
    if skippable(path) or "/.claude/output/" not in path or in_scope(path, text):
        return False
    return reader_of(text) is None


def cited(path, reply):
    return path in reply or path.replace(os.path.expanduser("~"), "~", 1) in reply


def body_of(text, keep_tail=False):
    """The text a reader reads, without front matter, code, and the final Sources
    section, which is the right home for ids and file:line (keep_tail=True keeps it)."""
    text = re.sub(r"^---\n.*?\n---\n", "", text, count=1, flags=re.DOTALL)
    text = FENCE.sub("", text)
    if keep_tail:
        return text
    tails = list(TAIL.finditer(text))
    return text[: tails[-1].start()] if tails else text


WORD = re.compile(r"[A-Za-z0-9][\w'’-]*")
SENT_SPLIT = re.compile(r"(?<=[.!?])\s+(?=[A-Z0-9`\"'(\[*])")


def prose_lines(text):
    """Body lines that are running text: not tables, headings or blank lines."""
    return [ln.strip() for ln in body_of(text).splitlines()
            if ln.strip() and not ln.strip().startswith(("|", "#"))]


def shape(text):
    """The doc-level shape signals: agent codes in running text, long sentences,
    a long page with too few headings, and no opening sentence before the first
    table or list."""
    lines = prose_lines(text)
    codes = [t for ln in lines for t in SIGNALS["internal id"].findall(ln)]
    long_sents = []
    for ln in lines:
        plain = re.sub(r"`[^`]*`|\[([^\]]*)\]\([^)]*\)", r" \1 ", LIST_ITEM.sub("", ln, count=1))
        for s in SENT_SPLIT.split(plain):
            if len(WORD.findall(s)) > LONG_SENTENCE_WORDS:
                long_sents.append(s.strip())
    body = body_of(text, keep_tail=True)
    words = len(WORD.findall(body))
    headings = len(re.findall(r"^#{2,6}\s", body, re.MULTILINE))
    flat = words > FLAT_PAGE_WORDS and headings < words // WORDS_PER_HEADING
    # A `>` summary line is an opening. An index page is a list by nature.
    first = next((ln.strip() for ln in body.splitlines() if ln.strip() and not ln.strip().startswith("#")), "")
    no_opening = bool(first) and (first.startswith("|") or bool(re.match(r"[-*+]\s|\d+[.)]\s", first)))
    # A Sources section is for citations. When it outweighs the page, the page has
    # been moved into it to get past the checks above.
    page = len(WORD.findall(body_of(text)))
    tails = list(TAIL.finditer(body))
    # A page whose own title is "Appendix" or "References" is not hiding anything.
    tail = words - page if tails and not tails[-1].group(0).startswith("# ") else 0
    return {"codes": codes, "long_sentences": long_sents, "flat": (words, headings) if flat else None,
            "no_opening": no_opening, "heavy_tail": (tail, page) if tail > 150 and tail > 2 * page else None}


def shape_fires(sh):
    return (len(sh["codes"]) > MAX_PROSE_CODES or len(sh["long_sentences"]) > MAX_LONG_SENTENCES
            or bool(sh["flat"]) or bool(sh["heavy_tail"]))


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
            cells += [c.strip() for c in s.strip("|").split("|") if not SEPARATOR_CELL.match(c.strip())]
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


def skim(text):
    """Dense paragraphs, spliced lines and internals-only runs in the doc body.
    A line glued with an em-dash counts the same as one glued with a semicolon,
    so swapping one mark for the other is never an improvement."""
    found = {"dense": [], "spliced": [], "mechanism": []}
    body = body_of(text)
    for kind, snip, _b in engine().core().spliced_findings(body, dashes=True, semicolons=False):
        found["spliced"].append("dash: " + snip)
    for f in engine().lint(body, SURFACE, only=SKIM_TELLS)["findings"]:
        if f["tell"] == "dense-block":
            found["dense"].append(f["snippet"])
        elif f["tell"] == "spliced-line":
            found["spliced"].append("semicolon: " + f["snippet"])
        elif f["tell"] == "mechanism-run":
            found["mechanism"].append(f["snippet"])
    return {k: v for k, v in found.items() if v}


def skim_fires(found):
    limits = {"dense": MAX_DENSE, "spliced": MAX_SPLICED, "mechanism": MAX_MECHANISM}
    return any(len(v) > limits[k] for k, v in found.items())


def measure(text):
    """The doc's faults as numbers, for telling worse from better: ledger marks
    (0 unless the ledger check fires), long cells, long paragraphs, and the
    three skim counts."""
    hits = score(text)
    cells, blocks = wall(text)
    found = skim(text)
    sh = shape(text)
    return {"ledger": sum(len(v) for v in hits.values()) if fires(hits) else 0,
            "cells": len(cells), "blocks": len(blocks),
            "dense": len(found.get("dense", [])), "spliced": len(found.get("spliced", [])),
            "mechanism": len(found.get("mechanism", [])),
            "codes": len(sh["codes"]), "sentences": len(sh["long_sentences"]),
            "flat": 1 if sh["flat"] else 0, "tail": 1 if sh["heavy_tail"] else 0,
            "fails": bool(fires(hits) or wall_fires(cells, blocks) or skim_fires(found) or shape_fires(sh))}


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
    return any(now[k] > base.get(k, 0) for k in ("ledger", "cells", "blocks", "dense", "spliced", "mechanism",
                                                 "codes", "sentences", "flat", "tail"))


def findings(path, force=False):
    """What is wrong with the doc as it stands now, as sentences; empty when it
    reads fine. `force` judges a doc that is out of scope by location, because
    the reply handed it to the owner."""
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            text = f.read()
    except OSError:
        return []
    if not force and not in_scope(path, text):
        return []
    out = []
    hits = score(text)
    if fires(hits):
        parts = ", ".join("%d %s" % (len(v), k) for k, v in hits.items())
        examples = "; ".join(str(v[0]) if isinstance(v[0], str) else "".join(v[0]) for v in hits.values())
        out.append("it reads like an internal ledger (%s; e.g. %s). Write it in layers: what is true now and what to "
                   "do, then how it works, then a final `## Sources` section that holds the ids, shas, file:line and "
                   "dates. Say what each code means rather than deleting it" % (parts, examples))
    cells, blocks = wall(text)
    if wall_fires(cells, blocks):
        sample = (cells or blocks)[0][:90]
        out.append("it is a wall of text (%d table cells over %d characters, %d paragraphs over %d; e.g. \"%s...\"). "
                   "Change the shape, not the wording: keep a short value in each cell and move its explanation to a "
                   "subsection named after the row, and split a long paragraph into a claim, steps and evidence"
                   % (len(cells), LONG_CELL, len(blocks), LONG_BLOCK, sample))
    found = skim(text)
    if skim_fires(found):
        parts = []
        if len(found.get("dense", [])) > MAX_DENSE:
            parts.append("%d dense paragraphs or bullets (e.g. \"%s\")" % (len(found["dense"]), found["dense"][0]))
        if len(found.get("spliced", [])) > MAX_SPLICED:
            parts.append("%d lines glued with a semicolon or dash (e.g. \"%s\")" % (len(found["spliced"]), found["spliced"][0].split(": ", 1)[-1]))
        if len(found.get("mechanism", [])) > MAX_MECHANISM:
            parts.append("%d runs of three or more sentences that only name code, paths and numbers (e.g. \"%s\")"
                         % (len(found["mechanism"]), found["mechanism"][0]))
        out.append("it is hard to skim: %s. Restructure rather than trim: a dense block becomes one claim plus a list "
                   "or steps, a glued line becomes separate sentences (never a different splice mark), and a run of "
                   "code names opens with what it means, then a table of what each thing is and where it lives"
                   % "; ".join(parts))
    sh = shape(text)
    if len(sh["codes"]) > MAX_PROSE_CODES and not fires(hits):
        out.append("its running text leans on %d agent codes (e.g. %s). Say what each one is; keep a code only in "
                   "a table's id column or in Sources, where a reader looks it up"
                   % (len(sh["codes"]), ", ".join(list(dict.fromkeys(sh["codes"]))[:6])))
    if len(sh["long_sentences"]) > MAX_LONG_SENTENCES:
        out.append("%d sentences run past %d words (e.g. \"%s...\"). Break each at its \"and then\": one action "
                   "per sentence, or numbered steps when the actions happen in order"
                   % (len(sh["long_sentences"]), LONG_SENTENCE_WORDS, sh["long_sentences"][0][:90]))
    if sh["flat"]:
        out.append("it is %d words with %d section headings. Give each topic its own `##` section, about one per "
                   "400 words, or split it into an overview page and detail pages" % sh["flat"])
    if sh["heavy_tail"]:
        out.append("its Sources section (%d words) outweighs the page (%d words). Sources is for citations; the "
                   "explanation belongs above it, in layers" % sh["heavy_tail"])
    # An index page may open with a list, so a missing opening is only advice
    # alongside a real fault, never a fault on its own.
    if out and sh["no_opening"]:
        out.append("it also opens with a table or list. Start with two sentences: who the page is for and what "
                   "they get from it")
    if out:
        out.append("the moves and size signals are in ~/.claude/conventions/doc-writing.md section 6b. Keep every fact")
    if out and reader_of(text) is None:
        if force:
            out.append("you pointed the owner at this file. If it is for agents, put `reader: agent` at the top; "
                       "if it is for the owner, name them (`reader: <who>`) and fix the points above")
        else:
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


def note_candidate(data, path):
    """Remember a doc written by the main agent that is out of scope by location
    but might be handed to the owner in the closing reply. A sub-agent's file is
    for the agent that dispatched it, so it is never remembered."""
    if data.get("agent_id") or not path.endswith(".md"):
        return
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            text = f.read()
    except OSError:
        return
    if not handover_candidate(path, text):
        return
    sid = data.get("session_id")
    st = load(sid)
    if path not in st.setdefault("cands", []):
        st["cands"].append(path)
    if path not in st.setdefault("base", {}):
        old = committed_text(path)
        st["base"][path] = measure(old) if old is not None else None
    save(sid, st)


def post(data):
    if data.get("tool_name") not in ("Write", "Edit", "MultiEdit"):
        return 0
    path = (data.get("tool_input") or {}).get("file_path") or ""
    found = findings(path)
    if not found:
        note_candidate(data, path)
        return 0
    if data.get("agent_id"):
        # A sub-agent's write: the seat gets the note in its own context, but the
        # parent's turn is never held for a doc the parent did not write.
        warn_log("nudge")
        msg = "%s does not read as a doc for a person: %s." % (os.path.basename(path), "; ".join(found))
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}))
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
    reply = data.get("last_assistant_message") or ""
    # A doc written this turn under .claude/output/ becomes something a person reads
    # when the reply names its path.
    cands = st.pop("cands", [])
    for p in cands:
        if cited(p, reply) and p not in st["docs"]:
            st["docs"].append(p)
            st.setdefault("forced", []).append(p)
    if not st["docs"]:
        if cands and os.path.exists(state_path(sid)):
            os.remove(state_path(sid))
        return 0
    forced = st.get("forced", [])
    failing = {p: findings(p, force=p in forced) for p in st["docs"]}
    failing = {p: f for p, f in failing.items() if f}
    claims = any(claims_better(reply, p) for p in failing)
    # Only the agent's own doing holds the turn: a doc it made fail or made worse, or a claim it is better.
    if not claims:
        failing = {p: f for p, f in failing.items() if worse(st.get("base", {}).get(p), measure(open(p, errors="replace").read()))}
    # A doc the reply names and says plainly still fails is the agent's decision to
    # leave it. The turn may end, and the owner hears it from the hook.
    admitted = {p: f for p, f in failing.items() if admits(reply, p) and not claims_better(reply, p)}
    failing = {p: f for p, f in failing.items() if p not in admitted}
    detail = " ".join("%s: %s." % (os.path.basename(p), "; ".join(f)) for p, f in failing.items())
    if not failing:
        os.remove(state_path(sid)) if os.path.exists(state_path(sid)) else None
        if admitted:
            warn_log("declined")
            print(json.dumps({"systemMessage": "doc check: the agent left %s failing on purpose and said so. %s"
                              % (", ".join(os.path.basename(p) for p in admitted),
                                 " ".join("%s: %s." % (os.path.basename(p), "; ".join(f)) for p, f in admitted.items()))}))
        else:
            warn_log("cleared")
        return 0
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
