"""Readability checks for prose a person has to read: part of the prose engine.

Would a busy reader get through this, or bounce off a block of text? The doc
gate and the GitHub gate both ask it, through prose-lint.py, which turns the
results here into findings. Three shapes fail it, and all three read as a
machine explaining itself:

  dense block      one paragraph or bullet that packs several sentences into
                   a wall, so there is no place to rest the eye.
  spliced line     a long line stitched together with an em-dash or a
                   semicolon instead of being split into sentences.
  mechanism run    three or more sentences in a row that talk only in code
                   names, file paths, units and internals, with no plain
                   sentence saying what it means for the reader.

Everything here is a pure function over a string. The surface profile decides
what a count means (a doc is allowed a few, a PR body none).
scripts/hooks/prose_readability.py re-exports this module for older callers.
"""
import re
from collections import namedtuple

# end is the last source line of the block; the default keeps three-field callers working.
Block = namedtuple("Block", "kind text line end", defaults=(0,))

# A paragraph or bullet is dense when it holds this much running text.
DENSE_SENTENCES, DENSE_CHARS = 3, 300
DENSE_SOLO_CHARS = 600
DENSE_MANY_SENTENCES, DENSE_MANY_CHARS = 5, 250
# A line this long that is joined with a semicolon reads as two thoughts glued.
SPLICE_MIN_CHARS = 100
RUN_LENGTH = 3
# Bullets that are each long, three in a row, are a paragraph in disguise.
LONG_ITEM_CHARS, LONG_ITEM_RUN = 200, 3

FENCE = re.compile(r"^\s*(```|~~~)")
ITEM = re.compile(r"^(\s*)(?:[-*+]|\d+[.)])\s+(?:\[[ xX]\]\s+)?")
CODE_SPAN = re.compile(r"`[^`\n]+`")
LEAD_LABEL = re.compile(r"^\*\*[^*]{1,120}\*\*\s*")
LINK = re.compile(r"!?\[([^\]]*)\]\([^)]*\)")
URL = re.compile(r"https?://\S+")
HTML_COMMENT = re.compile(r"<!--.*?-->", re.DOTALL)
FRONT = re.compile(r"\A---\n.*?\n---\n", re.DOTALL)
# The owner's attribution blockquote and the tool's own footer are not prose.
# Only the marker itself is removed; words written after it on the same line stay.
MARKER = re.compile(r"^\s*>?\s*Generated via a 🤖 on @\S+ machine(?: \(_[^)]*_\))?:?")
FOOTER = re.compile(r"^\s*🤖 Generated with ")
SESSION_URL = re.compile(r"^\s*https://claude\.ai/code/session_\S*\s*$")

# The GitHub-text dash rule: any em dash, and an en dash unless it sits between digits.
DASH = re.compile(r"\u2014|(?<!\d)\u2013(?!\d)")
SENTENCE_END = re.compile(r"(?<=[.!?])\s+(?=[A-Z0-9\"'(\[])")

PATH = re.compile(r"(?<![\w])(?:[\w.-]+/)+[\w.-]+|\b[\w-]+\.(?:ts|tsx|js|jsx|mjs|cjs|py|rs|go|sh|md|json|ya?ml|css|html|toml|sql|lock)\b")
UNIT = re.compile(r"\b\d+(?:\.\d+)?\s?(?:px|ms|s|kb|mb|gb|rem|em|vh|vw|fps)\b|\b\d+(?:\.\d+)?%", re.IGNORECASE)
IDENT = re.compile(r"\b[a-z]+[A-Z][A-Za-z]+\b|\b[a-z]+_[a-z_]+\b|(?<!\w)--[a-z][\w-]+|\b[A-Z][A-Z0-9]+_[A-Z0-9_]+\b|\b\w+\(\)")
VOCAB = re.compile(
    r"\b(?:memoi[sz]\w*|cach(?:e|es|ed|ing)|headers?|hydrat\w*|debounc\w*|serializ\w*|idempoten\w*|"
    r"regex\w*|schema\w*|mutex\w*|payloads?|endpoints?|resolv(?:e|es|ed|er|ers)|middleware|callbacks?|"
    r"viewport|breakpoints?|tracks?|grid|stylesheet|selectors?|specificity|retr(?:y|ies)|timeouts?|"
    r"async\w*|race condition|stale|invalidat\w*|dedup\w*|enum\w*|polyfill\w*|bundle[sd]?|"
    r"render(?:s|ed|ing)?|props?|refs?|reducers?|migrations?|indexes|queries|query)\b",
    re.IGNORECASE,
)


def clean(text):
    """The text with front matter and HTML comments removed."""
    text = FRONT.sub("", text, count=1)
    return HTML_COMMENT.sub("", text)


_clean = clean


def blocks(text, clean_first=True):
    """The prose blocks of a markdown text: paragraphs and list items, each with
    its lines joined. Fenced code, tables, headings, rules, the owner's marker
    line and trigger lines that start with a slash command are left out.
    Line numbers count the cleaned text; pass clean_first=False for text the
    caller already cleaned, so the numbers match its own copy."""
    out, cur, kind, start, last, fenced = [], [], None, 0, 0, False

    def flush():
        nonlocal cur, kind
        if cur:
            out.append(Block(kind, " ".join(cur).strip(), start, last))
        cur, kind = [], None

    src = _clean(text) if clean_first else text
    for n, raw in enumerate(src.splitlines(), 1):
        if FENCE.match(raw):
            flush()
            fenced = not fenced
            continue
        if fenced:
            continue
        raw = MARKER.sub("", raw)
        s = raw.strip()
        if (not s or s.startswith("#") or s.startswith("|") or re.match(r"^[-*_]{3,}$", s)
                or FOOTER.match(raw) or SESSION_URL.match(raw) or re.match(r"^/[a-z][\w-]*(\s|$)", s)):
            flush()
            continue
        s = re.sub(r"^(>\s?)+", "", s)
        m = ITEM.match(raw)
        if m:
            flush()
            kind, start = "item", n
            cur = [raw[m.end():].strip()]
            last = n
            continue
        if not cur:
            kind, start = "para", n
        cur.append(s)
        last = n
    flush()
    return [b for b in out if b.text]


def plain(text):
    """The text as a reader sees it: links reduced to their label, markup gone."""
    text = LINK.sub(r"\1", text)
    text = URL.sub("link", text)
    return re.sub(r"\*\*|__|(?<!\w)[*_](?=\S)|(?<=\S)[*_](?!\w)", "", text)


def _mask_code(text):
    return CODE_SPAN.sub(lambda m: "C" * len(m.group(0)), text)


def sentences(text):
    """Sentences of a block. Code spans are masked first so a dot inside one
    never ends a sentence."""
    text = plain(text)
    masked = _mask_code(text)
    out, last = [], 0
    for m in SENTENCE_END.finditer(masked):
        out.append(text[last:m.start()])
        last = m.end()
    out.append(text[last:])
    return [s.strip() for s in out if s.strip()]


def _snip(text, n=90):
    text = text.strip()
    return text if len(text) <= n else text[:n].rstrip() + "..."


def is_dense(block):
    # A bold lead-in such as "**Open tabs pick up a new release.**" is a title for
    # the text under it, so it is not counted as running prose.
    body = LEAD_LABEL.sub("", block.text, count=1)
    text = plain(body)
    n, chars = len(sentences(body)), len(text)
    return ((n >= DENSE_SENTENCES and chars >= DENSE_CHARS) or chars >= DENSE_SOLO_CHARS
            or (n >= DENSE_MANY_SENTENCES and chars >= DENSE_MANY_CHARS))


def dense_findings(text, clean_first=True):
    """(block, snippet) for paragraphs and bullets that pack too much into one
    block, plus any run of three long bullets that together make a paragraph
    in disguise."""
    bl = blocks(text, clean_first)
    out = [(b, _snip(plain(b.text))) for b in bl if is_dense(b)]
    run = 0
    for i, b in enumerate(bl):
        run = run + 1 if b.kind == "item" and len(plain(b.text)) >= LONG_ITEM_CHARS and not is_dense(b) else 0
        if run == LONG_ITEM_RUN:
            first = bl[i - LONG_ITEM_RUN + 1]
            out.append((first, _snip(plain(first.text))))
    return out


def dense_blocks(text):
    """Snippets only, for callers that do not need the block."""
    return [snip for _b, snip in dense_findings(text)]


def spliced_findings(text, dashes=True, semicolons=True, dash_re=None, clean_first=True):
    """(kind, snippet, block) for blocks stitched together with an em-dash or,
    when long, a semicolon. Code spans and links do not count. A block with a
    dash is not also counted for its semicolon."""
    rx = dash_re or DASH
    out = []
    for b in blocks(text, clean_first):
        t = plain(CODE_SPAN.sub(" ", b.text))
        if dashes and rx.search(t):
            out.append(("dash", _snip(plain(b.text)), b))
        elif semicolons and ";" in t and len(t) >= SPLICE_MIN_CHARS:
            out.append(("semicolon", _snip(plain(b.text)), b))
    return out


def spliced_lines(text, dashes=True, semicolons=True):
    """(kind, snippet) pairs, for callers that do not need the block."""
    return [(k, s) for k, s, _b in spliced_findings(text, dashes, semicolons)]


def _points(sentence):
    spans = CODE_SPAN.findall(sentence)
    rest = _mask_out_code(sentence)
    pts = 0
    if spans:
        pts += 1
        if any(PATH.search(s) or IDENT.search(s) or re.search(r"\d", s) for s in spans):
            pts += 1
    pts += sum(1 for rx in (PATH, UNIT, IDENT) if rx.search(rest))
    pts += min(2, len({m.group(0).lower() for m in VOCAB.finditer(rest)}))
    return pts


def _mask_out_code(s):
    return CODE_SPAN.sub(" ", s)


def is_mechanism(sentence):
    return _points(sentence) >= 2


def mechanism_findings(text, clean_first=True):
    """(block, snippet) per place where RUN_LENGTH or more sentences in a row
    inside one block are all code names, paths, units and internals."""
    out = []
    for b in blocks(text, clean_first):
        run = []
        for s in sentences(b.text):
            if is_mechanism(s):
                run.append(s)
                if len(run) == RUN_LENGTH:
                    out.append((b, _snip(" ".join(run), 110)))
            else:
                run = []
    return out


def mechanism_runs(text):
    """A snippet per run, for callers that do not need the block."""
    return [snip for _b, snip in mechanism_findings(text)]


def analyze(text, dashes=True):
    """All three checks as {name: [snippets]}; empty lists are dropped."""
    found = {
        "dense": dense_blocks(text),
        "spliced": [f"{k}: {s}" for k, s in spliced_lines(text, dashes=dashes)],
        "mechanism": mechanism_runs(text),
    }
    return {k: v for k, v in found.items() if v}
