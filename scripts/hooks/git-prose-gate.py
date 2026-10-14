#!/usr/bin/env python3
"""Refuse a commit that adds AI-slop prose to this repo's markdown docs.

The write-time gate (guard-prose-quality.sh) only sees the Edit and Write
tools, so text added through sed, python or a heredoc skipped it. This runs
the same scoring engine (scripts/style/prose-lint.py) at commit time over the
lines the commit ADDS, and refuses on an em/en-dash, a verdict-first opener,
a contrast list, or a block-level score. Run from a pre-commit hook inside the repo.

Scope: rules/, features/, conventions/, personas/, skills/ (not skills/synced/)
and CLAUDE.md, markdown only. Exempt, like the write-time gate: style/, atone/,
i-dream/, sweep/, derived/, checkpoints (_*.claude.md), test/fixture paths and
the style docs that quote defects. Fenced blocks, blockquotes and table rows
never count (prose-lint strips them; fences opened before the hunk are tracked
here too).

One-shot bypass for the owner: PROSE_GATE_BYPASS=1 git commit ...
Exit 0 = commit may proceed, 1 = refused.
"""
import importlib.util, os, re, subprocess, sys

BLOCK_SCORE = 8.0
BYPASS_VAR = "PROSE_GATE_BYPASS"
IN_SCOPE = re.compile(r"^(?:rules|features|conventions|personas)/.+\.md$|^skills/(?!synced/).+\.md$|^CLAUDE\.md$")
EXEMPT = re.compile(r"(?:^|/)(?:style|atone|i-dream|sweep|derived|node_modules|ste-writing)/|language-quality|thesaurus"
                    r"|(?:^|/)_[^/]*\.claude\.md$|test|spec|fixture|mock")
HUNK = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")


def git(*args):
    r = subprocess.run(["git", *args], capture_output=True, text=True, errors="replace")
    return r.stdout if r.returncode == 0 else ""


def load_lint():
    here = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(here, "..", "style", "prose-lint.py")
    spec = importlib.util.spec_from_file_location("prose_lint", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def fenced_flags(lines):
    """True for every line inside a ``` fence (the fence lines included)."""
    flags, inside = [], False
    for ln in lines:
        if ln.lstrip().startswith("```"):
            flags.append(True)
            inside = not inside
        else:
            flags.append(inside)
    return flags


def added_prose(path):
    new = git("show", f":{path}").split("\n")
    old = set(git("show", f"HEAD:{path}").split("\n"))
    fenced = fenced_flags(new)
    diff = git("diff", "--cached", "--unified=0", "--no-color", "--", path)
    out = []
    for ln in diff.split("\n"):
        m = HUNK.match(ln)
        if not m:
            continue
        start = int(m.group(1))
        count = 1 if m.group(2) is None else int(m.group(2))
        for i in range(start - 1, start - 1 + count):
            if 0 <= i < len(new) and not fenced[i] and new[i] not in old:
                out.append((i + 1, new[i]))
    return out


def main():
    if os.environ.get(BYPASS_VAR) == "1":
        print(f"prose-gate: bypassed ({BYPASS_VAR}=1)", file=sys.stderr)
        return 0
    names = git("diff", "--cached", "--name-only", "--diff-filter=AM").split("\n")
    files = [n for n in names if n and IN_SCOPE.match(n) and not EXEMPT.search(n)]
    if not files:
        return 0
    lint = load_lint()
    refusals = []
    for f in files:
        rows = added_prose(f)
        if not rows:
            continue
        r = lint.lint("\n".join(t for _, t in rows))
        if "skipped" in r:
            continue
        v = r.get("violations", {})
        why = []
        if v.get("two_split_dash"):
            why.append(f"{v['two_split_dash']} em/en-dash(es) in earnest prose (budget: zero)")
        if v.get("verdict_first_opener"):
            why.append("verdict-first opener")
        if v.get("contrast_list"):
            why.append(f"{v['contrast_list']} contrast list(s) (\"not X, not Y, but Z\")")
        if r.get("score", 0) > BLOCK_SCORE:
            why.append(f"prose-lint score {r['score']}/100w (block line {BLOCK_SCORE:g})")
        if why:
            first = next((n for n, t in rows if re.search(r"[—–]", t)), rows[0][0])
            refusals.append(f"  {f} (e.g. line {first}): " + "; ".join(why))
    if not refusals:
        return 0
    print("COMMIT REFUSED: added doc lines carry banned prose tells:", file=sys.stderr)
    print("\n".join(refusals), file=sys.stderr)
    print("Rewrite per conventions/language-quality.md (comma, colon or period for a dash; "
          "check with: python3 ~/.claude/scripts/style/prose-lint.py FILE).", file=sys.stderr)
    print(f"Owner one-shot bypass: {BYPASS_VAR}=1 git commit ...", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
