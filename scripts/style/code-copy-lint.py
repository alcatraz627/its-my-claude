#!/usr/bin/env python3
"""Find banned language tells in the user-facing string copy of a code file.

Extracts single-line string literals from code (js/ts/jsx/tsx/vue/svelte/py),
keeps the ones that read as prose copy, and judges them with prose-lint's own
regexes: connective em/en-dashes, unverified-claim futures, jargon/marketing
words. Placeholder glyphs, classNames, paths, URLs, and comment text are out
of scope by construction. CLI: FILE... | stdin '-'; --json for records; exit 0
always (callers gate).
"""
import importlib.util, json, os, re, sys

_spec = importlib.util.spec_from_file_location(
    "prose_lint", os.path.join(os.path.dirname(os.path.abspath(__file__)), "prose-lint.py"))
_pl = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(_pl)

STRING_RE = re.compile(r'"((?:[^"\\\n]|\\.){8,300})"'
                       r"|'((?:[^'\\\n]|\\.){8,300})'"
                       r"|`((?:[^`\\\n]|\\.){8,300})`")
COMMENT_LINE = re.compile(r"^\s*(//|#|\*|/\*|\{\s*/\*)")
NOT_COPY = re.compile(r"^https?://|^[./~]|\{.*\}.*\{.*\}")   # urls, paths, dense templating

def _token_soup(s):
    """True for className-style strings: every token is css-ish, none reads as a word."""
    toks = s.split()
    return bool(toks) and all(re.search(r"[-/0-9_:.]", t) or len(re.sub(r"[^A-Za-z]", "", t)) < 3 for t in toks)
WORDISH = re.compile(r"[A-Za-z]{3,}\s+[A-Za-z]{3,}")

def copy_strings(source):
    """Yield (line_no, text) for string literals that read as prose copy."""
    for i, line in enumerate(source.split("\n"), 1):
        if COMMENT_LINE.match(line):
            continue
        for m in STRING_RE.finditer(line):
            s = next(g for g in m.groups() if g is not None)
            if NOT_COPY.match(s) or _token_soup(s) or not WORDISH.search(s):
                continue
            yield i, s

def judge(source):
    findings = []
    for ln, s in copy_strings(source):
        tells = []
        if _pl.DASH.search(s):
            tells.append("connective-dash")
        if any(re.search(r"(?<![a-z])" + re.escape(p) + r"(?![a-z])", s.lower())
               for p in _pl.UNVERIFIED):
            tells.append("unverified-claim")
        jargon = [w for w in _pl.JARGON
                  if re.search(r"(?<![a-z])" + re.escape(w) + r"(?![a-z])", s.lower())]
        if jargon:
            tells.append("jargon:" + ",".join(jargon[:2]))
        if tells:
            findings.append({"line": ln, "tells": tells, "text": s[:140]})
    return findings

def main(argv):
    as_json = "--json" in argv
    files = [a for a in argv if a not in ("--json", "-")]
    sources = [("stdin", sys.stdin.read())] if not files else \
              [(f, open(f, errors="replace").read()) for f in files if os.path.exists(f)]
    total = 0
    for name, src in sources:
        f = judge(src)
        total += len(f)
        if as_json:
            print(json.dumps({"file": name, "findings": f}))
        else:
            for r in f:
                print(f"{os.path.basename(name)}:{r['line']}  [{'|'.join(r['tells'])}]  {r['text'][:90]}")
    if not as_json and total == 0:
        print("no copy findings")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
