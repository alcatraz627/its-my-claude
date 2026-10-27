#!/usr/bin/env python3
"""Rewrite em-dashes out of the gcc's markdown, so the zero budget holds in every file.

Owner ruling D4a (2026-10-27): zero em-dashes irrespective of usage. This tool
handles prose in tracked markdown. It never touches fenced code blocks, inline
code or append-only ledgers, and it reports every rewrite it makes.

Runtime contract: `emdash-sweep.py [--apply] [--sample N] [paths...]`. With no
paths it walks every tracked .md file. Without --apply it writes nothing and
prints a per-rule count plus a unified diff for the first N files (default 3).
With --apply it rewrites in place and prints the heading renames, so the links
that point at them can be updated in the same pass.

Rules, applied per prose segment (text outside backticks). DASH below stands
for the em-dash character, which this file never writes literally:
  heading     "## A DASH B"                    -> "## A: B"
  label       "**X** DASH desc" at a list or table start -> "**X**: desc"
  pair        "a DASH b DASH c" in one sentence -> "a (b) c"
  clause      any other spaced DASH             -> ": "
  bare        "aDASHb" with no spaces           -> "a: b"
Fenced blocks are skipped; a dash inside inline code is left for the code
owners, and counted.
"""
import argparse, difflib, os, re, subprocess, sys

ROOT = os.path.expanduser("~/.claude")
DASH = chr(0x2014)
SKIP = re.compile(r"^(skills/synced/|atone/|affirm/)|\.jsonl$|runtime-notes-archive|^mistake-patterns\.md$")
HEADING = re.compile(r"^(#{1,6}\s+.*?)\s+" + DASH + r"\s+(.*)$")
LABEL = re.compile(r"^(\s*(?:[-*+]|\d+\.|\|)?\s*(?:\*\*[^*]+\*\*|`[^`]+`|[^\s" + DASH + r"][^" + DASH + r"]{0,40}?))\s+" + DASH + r"\s+")
PAIR = re.compile(r"\s+" + DASH + r"\s+([^" + DASH + r".!?]{1,80}?)\s+" + DASH + r"\s+")
CLAUSE = re.compile(r"\s+" + DASH + r"\s+(\S)")
BARE = re.compile(r"(\w)" + DASH + r"(\w)")
counts = {k: 0 for k in ("quoted", "frontmatter", "placeholder", "leading", "heading", "label", "pair", "clause", "bare", "in-code", "in-fence")}
renames = []


def fix_prose(seg, at_line_start):
    if at_line_start:
        seg, n = LABEL.subn(lambda m: m.group(1) + ": ", seg, count=1)
        counts["label"] += n
    seg, n = PAIR.subn(lambda m: " (" + m.group(1) + ") ", seg)
    counts["pair"] += n

    def clause(m):
        return ": " + m.group(1)
    seg, n = CLAUSE.subn(clause, seg)
    counts["clause"] += n
    seg, n = BARE.subn(r"\1: \2", seg)
    counts["bare"] += n
    seg = seg.replace(" " + DASH, ":").replace(DASH + " ", ": ")
    return seg


EMPTY_CELL = re.compile(r"\|\s*" + DASH + r"\s*(?=\|)")
LEADING = re.compile(r"^(\s*(?:>\s*)?(?:[-*+]\s+)?)" + DASH + r"\s+")


def fix_line(line):
    if DASH not in line:
        return line
    # A cell holding only a dash is a placeholder: an ASCII hyphen says the same.
    line, n = EMPTY_CELL.subn("| - ", line)
    counts["placeholder"] += n
    # A dash that opens a line (an attribution, a lead-in) is dropped.
    line, n = LEADING.subn(r"\1", line)
    counts["leading"] += n
    if DASH not in line:
        return line
    m = HEADING.match(line)
    if m:
        new = f"{m.group(1)}: {m.group(2)}"
        counts["heading"] += 1
        renames.append((line.strip(), new.strip()))
        line = new
        if DASH not in line:
            return line
    parts = re.split(r"(`[^`]*`)", line)
    out = []
    for i, p in enumerate(parts):
        if p.startswith("`") and p.endswith("`") and len(p) > 1:
            counts["in-code"] += p.count(DASH)
            out.append(p)
        else:
            out.append(fix_prose(p, i == 0))
    return "".join(out)


def fix_text(text):
    lines, out, fenced = text.split("\n"), [], False
    # YAML frontmatter: a ": " inside a plain value breaks parsing, so a dash
    # there becomes a comma instead.
    if lines and lines[0] == "---" and "---" in lines[1:]:
        end = lines.index("---", 1)
        for i in range(1, end):
            n = lines[i].count(DASH)
            if n:
                counts["frontmatter"] += n
                lines[i] = re.sub(r"\s*" + DASH + r"\s*", ", ", lines[i])
        out, lines = lines[:end + 1], lines[end + 1:]
    for line in lines:
        if line.lstrip().startswith("```"):
            fenced = not fenced
            out.append(line)
            continue
        if fenced:
            counts["in-fence"] += line.count(DASH)
            out.append(line)
        else:
            out.append(fix_line(line))
    return "\n".join(out)


COMMENT = re.compile(r"^(\s*(?:#(?!!)|//)\s?)(.*)$")
CODE_EXT = (".sh", ".zsh", ".py", ".ts", ".js", ".mjs", ".cjs", ".swift", ".rs", ".toml")


def fix_comments(text):
    """Rewrites only full-line comments; code and strings are left for a later pass."""
    out = []
    for line in text.split("\n"):
        m = COMMENT.match(line)
        if m and DASH in m.group(2):
            # A dash inside quotes documents the literal character a detector
            # matches, so it keeps its meaning as an escape instead of prose.
            body = re.sub(r"([\"'])([^\"']*)\1",
                          lambda q: q.group(1) + q.group(2).replace(DASH, "\\u2014") + q.group(1), m.group(2))
            counts["quoted"] += m.group(2).count(DASH) - body.count(DASH)
            line = m.group(1) + fix_prose(body, True)
        out.append(line)
    return "\n".join(out)


def tracked_code():
    files = subprocess.run(["git", "-C", ROOT, "ls-files"], capture_output=True, text=True).stdout.split()
    return [f for f in files if f.endswith(CODE_EXT) and not SKIP.search(f) and not re.search(r"^(i-dream|subconscious)/", f)]


def tracked_md():
    files = subprocess.run(["git", "-C", ROOT, "ls-files", "*.md"], capture_output=True, text=True).stdout.split()
    return [f for f in files if not SKIP.search(f)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--sample", type=int, default=3)
    ap.add_argument("--comments", action="store_true",
                    help="code files instead of markdown: rewrite only full-line # and // comments")
    ap.add_argument("paths", nargs="*")
    a = ap.parse_args()
    paths = a.paths or (tracked_code() if a.comments else tracked_md())
    global fix_text
    if a.comments:
        fix_text = fix_comments
    changed, shown = 0, 0
    for rel in paths:
        p = rel if os.path.isabs(rel) else os.path.join(ROOT, rel)
        try:
            old = open(p, encoding="utf-8").read()
        except OSError:
            continue
        if DASH not in old:
            continue
        new = fix_text(old)
        if new == old:
            continue
        changed += 1
        if a.apply:
            open(p, "w", encoding="utf-8").write(new)
        elif shown < a.sample:
            shown += 1
            sys.stdout.writelines(difflib.unified_diff(old.splitlines(True), new.splitlines(True), rel, rel, n=0))
    print(f"\nfiles changed: {changed}  ({'applied' if a.apply else 'dry run'})")
    print("rewrites by rule:", counts)
    if renames:
        print(f"heading renames: {len(renames)} (links to them need updating)")
        for old, new in renames[:20]:
            print(f"  {old}  ->  {new}")


if __name__ == "__main__":
    main()
