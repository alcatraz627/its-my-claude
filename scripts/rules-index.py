#!/usr/bin/env python3
"""Writes rules/00-index.md, the menu of every behavioral rule that loads each session.

The menu exists for the rules an agent cannot see. Always-on rules are already
in context, so they get one short line. Scoped rules are not loaded, so each
gets the situations that call for it and what it says, which is the only way an
agent learns the rule exists. Everything is derived from each rule's
frontmatter (`brief`, `gist`, `triggers`, `paths`); fix the rule and re-run.
Called by rules-index.sh, which stays the documented entry point.
"""
import re
import sys
from datetime import datetime
from pathlib import Path

RULES = Path.home() / ".claude/rules"
OUT = RULES / "00-index.md"
SKIP = {"README", "00-index"}
ON_DEMAND = "zz-on-demand--never-autoloads"
DANGLING = {"a", "an", "the", "of", "on", "in", "to", "as", "or", "and", "its", "by", "if", "is",
            "that", "for", "with", "it", "not", "their", "your", "you", "are", "at", "from",
            "every", "any", "when", "before", "after", "then", "so", "but", "which", "who"}


def frontmatter(text):
    """Scalars and simple lists from a rule's YAML header; enough for the four fields used."""
    if not text.startswith("---"):
        return {}
    head = text.split("---", 2)[1]
    out, key = {}, None
    for line in head.splitlines():
        item = re.match(r"\s+-\s+(.*)$", line)
        if item and key:
            out.setdefault(key, []).append(item.group(1).strip().strip("\"'"))
            continue
        m = re.match(r"([A-Za-z_]+):\s*(.*)$", line)
        if m:
            key = m.group(1)
            if m.group(2):
                out[key] = m.group(2).strip()
    return out


def clean(s):
    s = re.sub(r"\s[—–]\s", ", ", s)
    s = re.sub(r"[—–]", "-", s)
    return s.replace("|", "\\|").strip()


def shorten(text, limit):
    """About `limit` words: whole sentences first, then as much of the next one as still reads complete."""
    text = " ".join(text.split())
    if len(text.split()) <= limit:
        return text.rstrip(".")
    sentences = re.split(r"(?<=[.!?])\s+", text)
    kept = []
    while sentences and len(" ".join(kept + [sentences[0]]).split()) <= limit:
        kept.append(sentences.pop(0))
    have = len(" ".join(kept).split())
    # A short opening sentence alone says too little, so spend the rest of the
    # budget on the start of the next one.
    if sentences and have < limit * 0.6:
        cut = sentences[0].split()[: limit - have]
        # The cut lands mid-sentence, so back up to the last pause when that
        # costs under half of it: a clause that ends reads better than a
        # longer one that trails off.
        for i in range(len(cut) - 2, int(len(cut) * 0.5), -1):
            if cut[i][-1] in ",;:":
                cut = cut[: i + 1]
                break
        while cut and cut[-1].strip(",;:").lower() in DANGLING:
            cut.pop()
        tail = " ".join(cut).rstrip(",;:.")
        # Never leave a bracket open: drop the unfinished aside.
        if tail.count("(") > tail.count(")"):
            tail = tail[: tail.rindex("(")].rstrip(" ,;:")
            while tail.split() and tail.split()[-1].lower() in DANGLING:
                tail = tail.rsplit(" ", 1)[0]
        if len(tail.split()) >= 4:
            kept.append(tail)
    return " ".join(kept).rstrip(".")


def when(name, fm):
    """The situations that call for a scoped rule, from its triggers and file globs."""
    topics, phrases, tools = [], [], []
    for t in fm.get("triggers", []) if isinstance(fm.get("triggers"), list) else []:
        kind, _, val = t.partition(":")
        val = val.strip().strip("\"'")
        if not val:
            continue
        if kind == "topic":
            if val != name and val.replace("-", " ") not in topics:
                topics.append(val.replace("-", " "))
        elif kind == "phrase":
            phrases.append(f'"{val}"')
        elif kind in ("tool", "skill", "mcp"):
            tools.append(f"`{val}`")
    parts = (topics + tools + phrases)[:7]
    globs = [g.strip("\"'") for g in fm.get("paths", []) if isinstance(fm.get("paths"), list)]
    globs = [g for g in globs if g != ON_DEMAND]
    if globs:
        exts = []
        for g in globs:
            e = g.rsplit("/", 1)[-1]
            if e not in exts:
                exts.append(e)
        more = f" +{len(exts) - 5}" if len(exts) > 5 else ""
        parts.append("autoloads on " + " ".join(exts[:5]) + more)
    return clean(" · ".join(parts)) or "(no triggers; add them to the rule)"


def main():
    always, scoped = [], []
    for f in sorted(RULES.glob("*.md")):
        if f.stem in SKIP:
            continue
        fm = frontmatter(f.read_text())
        brief = fm.get("brief", "") if isinstance(fm.get("brief"), str) else ""
        gist = fm.get("gist", "") if isinstance(fm.get("gist"), str) else ""
        if "paths" in fm:
            says = clean(shorten(brief or gist, 28)) or "(no brief; add frontmatter)"
            scoped.append(f"| `{f.stem}` | {when(f.stem, fm)} | {says} |")
        else:
            says = clean(gist or shorten(brief, 26)) or "(no brief; add frontmatter)"
            always.append(f"| `{f.stem}` | {says} |")

    now = datetime.now()
    lines = [
        "---",
        "brief: Menu of every behavioral rule. Scoped rules get the situations that call for them and what they say; always-on rules get one line. DERIVED from each rule's frontmatter via scripts/rules-index.sh.",
        "triggers:",
        "  - topic:rules-index",
        '  - phrase:"which rule applies"',
        "related:",
        "  - PLACEMENT.md",
        "  - rules/README.md",
        "tier: 0",
        "category: rules",
        f"updated: {now:%Y-%m-%d}",
        "stale_after_days: 365",
        "---",
        "",
        "# Rules index",
        "",
        f"{len(always) + len(scoped)} rules in `rules/`: {len(scoped)} scoped, {len(always)} always-on.",
        "DERIVED from each rule's frontmatter; regenerate with `bash ~/.claude/scripts/rules-index.sh`.",
        f"Regenerated {now:%Y-%m-%d %H:%M}.",
        "",
        "## Scoped rules: not in your context",
        "",
        "This table is the only place these rules appear. When the middle column matches",
        "what you are about to do, Read `rules/<name>.md` first. \"autoloads on\" means the",
        "rule also loads by itself when you touch a matching file; the rest never load unasked.",
        "",
        "| Rule | Read it when the work involves | What it says |",
        "|------|--------------------------------|--------------|",
        *scoped,
        "",
        "## Always-on rules: already loaded in full",
        "",
        "| Rule | Gist |",
        "|------|------|",
        *always,
        "",
    ]
    OUT.write_text("\n".join(lines))
    rows = len(always) + len(scoped)
    print(f"rules index regenerated: {OUT} ({rows} rules, {len(scoped)} scoped, {OUT.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
