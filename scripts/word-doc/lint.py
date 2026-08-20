#!/usr/bin/env python3
"""The document's prose gate: a fixed list of mechanical checks over DOC.md.

Enough to catch the things that make a Word document read like a machine wrote
it, never a review. One line per finding with the source line, and a count. The
skill codifies the loop: more than two findings on the first run means fix,
re-run, fix again, until clean or each leftover carries a one-line reason.

Checks (body prose only; code, diagrams, tables, frontmatter are skipped):
  em-dash       an em-dash anywhere (house rule, conventions/language-quality.md)
  weasel        a size claim without a number: many / significant / huge /
                massive / robust / seamless / numerous / substantial
  triad         a rule-of-three adjective list ("fast, simple, and reliable")
  sentence      a sentence over 30 words
  wall          a paragraph over 120 words with no list, table, or code near it
  bullet        a bullet over 160 characters (that is a paragraph wearing a dash)
  labels        three or more consecutive "**Label:** fragment" lines (a form,
                not prose; write sentences or make it a table)
  empty         a heading followed directly by another heading, no body between
  orphan        a top-level section with a single sub-heading (a level that
                exists to hold one thing is a level too many)

Exit 0 when clean, 1 when findings; --json for machines.
"""
import json
import re
import sys

WEASEL = re.compile(r"\b(many|significant(ly)?|huge|dramatic(ally)?|massive(ly)?|robust|seamless(ly)?|numerous|substantial(ly)?|countless)\b", re.I)
TRIAD = re.compile(r"\b\w+, \w+,? and \w+\b")
LABEL = re.compile(r"^\s*(?:[-*]\s+)?\*\*[^*]{1,40}:\*\*\s+\S")


def body_lines(src):
    """Yield (lineno, text, kind) for prose lines; kind in para|bullet|heading."""
    fence, front, i = False, False, 0
    lines = src.splitlines()
    if lines and lines[0].strip() == "---":
        front = True
    for i, ln in enumerate(lines, 1):
        if front:
            if i > 1 and ln.strip() == "---":
                front = False
            continue
        if ln.startswith("```") or ln.startswith("~~~"):
            fence = not fence
            continue
        if fence:
            continue
        s = ln.strip()
        if not s or s.startswith("|") or s.startswith("<!--") or s == "\\newpage":
            yield i, "", "blank"
            continue
        if re.match(r"^#{1,6}\s", s):
            yield i, s, "heading"
        elif re.match(r"^(\s*[-*+]\s+|\s*\d+[.)]\s+)", ln):
            yield i, s, "bullet"
        elif s.startswith(">"):
            yield i, s.lstrip("> ").strip(), "quote"
        else:
            yield i, s, "para"


def lint(src):
    out = []
    rows = list(body_lines(src))

    # paragraphs: join consecutive para lines
    paras, cur, start = [], [], None
    for i, s, kind in rows:
        if kind == "para":
            if not cur:
                start = i
            cur.append(s)
        else:
            if cur:
                paras.append((start, " ".join(cur)))
                cur = []
    if cur:
        paras.append((start, " ".join(cur)))

    for i, s, kind in rows:
        if kind in ("para", "bullet", "quote", "heading"):
            if "—" in s:
                out.append((i, "em-dash", "replace with a comma, a period, or parentheses"))
            if kind != "heading":
                m = WEASEL.search(s)
                if m:
                    out.append((i, "weasel", f'"{m.group(0)}" is a size with no number'))
                m = TRIAD.search(s)
                if m and kind != "bullet":
                    out.append((i, "triad", f'"{m.group(0)}": three adjectives where one would do'))
        if kind == "bullet" and len(s) > 160:
            out.append((i, "bullet", f"{len(s)} characters; a bullet is one thought, make it a paragraph or split it"))

    for start, text in paras:
        words = len(text.split())
        if words > 120:
            out.append((start, "wall", f"{words}-word paragraph; break it, or pull the list or table out of it"))
        for sent in re.split(r"(?<=[.!?])\s+", text):
            n = len(sent.split())
            if n > 30:
                out.append((start, "sentence", f"{n} words: \"{sent[:60]}...\""))

    # label runs
    run, run_start = 0, None
    for i, s, kind in rows:
        if kind in ("bullet", "para") and LABEL.match(s):
            run += 1
            run_start = run_start or i
        else:
            if run >= 3:
                out.append((run_start, "labels", f"{run} Label: fragment lines in a row; write sentences or make a table"))
            run, run_start = 0, None
    if run >= 3:
        out.append((run_start, "labels", f"{run} Label: fragment lines in a row; write sentences or make a table"))

    # headings: empty sections and single-child levels
    heads = [(i, len(s.split()[0]), s.lstrip("#").strip()) for i, s, k in rows if k == "heading"]
    idx = {i: n for n, (i, _, _) in enumerate(heads)}
    for n, (i, lvl, title) in enumerate(heads):
        nxt = heads[n + 1] if n + 1 < len(heads) else None
        if nxt:
            between = [s for j, s, k in rows if i < j < nxt[0] and k not in ("blank", "heading") and s]
            # a section may legitimately hold only a table or a diagram; those rows
            # are "blank" here, so look at the raw source too
            raw_between = [ln for ln in src.splitlines()[i:nxt[0] - 1] if ln.strip()]
            if not between and not raw_between and nxt[1] > lvl:
                out.append((i, "empty", f'"{title}" has no text before its first sub-heading; say what it is for'))
    for n, (i, lvl, title) in enumerate(heads):
        kids = 0
        for j, l2, _ in heads[n + 1:]:
            if l2 <= lvl:
                break
            if l2 == lvl + 1:
                kids += 1
        if kids == 1:
            out.append((i, "orphan", f'"{title}" has exactly one sub-heading; fold it in or find the second'))

    out.sort()
    return out


def main(argv):
    as_json = "--json" in argv
    paths = [a for a in argv if not a.startswith("--")]
    if not paths:
        print(__doc__)
        return 2
    total = 0
    for p in paths:
        findings = lint(open(p, encoding="utf-8").read())
        total += len(findings)
        if as_json:
            print(json.dumps([{"file": p, "line": i, "check": c, "detail": d} for i, c, d in findings]))
            continue
        for i, c, d in findings:
            print(f"{p}:{i}  {c:9} {d}")
        print(f"{p}: {len(findings)} finding(s)")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
