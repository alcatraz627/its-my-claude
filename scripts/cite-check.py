#!/usr/bin/env python3
"""Do a document's code citations still point at what they claim? Check, per pair.

A doc that cites `path:line` (or path:line-range) drifts silently the moment the
cited file moves under it; the only pair that had a guard (COPY-INVENTORY.md
against app.py) caught 24 drifted citations in one edit while every other doc had
nothing (automation-d8ff1149, 2026-08-20). This generalizes that guard: point it
at any doc, it finds every citation, resolves the path (relative to the doc's dir,
then the repo root), and checks three things — the file exists, the line exists,
and, when the citation sits in a sentence with a backticked snippet, that the
snippet appears within a few lines of the cited spot.

    python3 cite-check.py DOC.md [DOC2.md ...] [--root DIR] [--near N] [--json]

Exit 0 all citations hold, 1 drift found, 2 usage error. One line per drifted
citation, with what to fix. Snippet matching is advisory (a `note:` not a fail)
unless --strict-snippets.
"""
import argparse
import json
import re
import sys
from pathlib import Path

CITE = re.compile(r'(?<![\w/])((?:~?/?[\w.\-]+/)*[\w.\-]+\.(?:py|sh|ts|tsx|js|jsx|rs|go|md|json|jsonl|toml|yaml|yml|lua|swift|c|h|cpp)):(\d+)(?:-(\d+))?')
SNIPPET = re.compile(r'`([^`]{3,60})`')


def resolve(path_str, doc_dir, root):
    p = Path(path_str.replace('~', str(Path.home())))
    for base in (None, doc_dir, root):
        cand = p if base is None and p.is_absolute() else (base / p if base else None)
        if cand and cand.exists():
            return cand
    return None


def check_doc(doc, root, near, strict):
    text = Path(doc).read_text(encoding='utf-8', errors='replace')
    doc_dir = Path(doc).resolve().parent
    findings = []
    for m in CITE.finditer(text):
        raw, line_no = m.group(1), int(m.group(2))
        line_end = int(m.group(3)) if m.group(3) else line_no
        target = resolve(raw, doc_dir, root)
        cite_line = text.count('\n', 0, m.start()) + 1
        if target is None:
            findings.append(('fail', cite_line, f"{raw}:{line_no} — file not found (tried absolute, doc-relative, root-relative)"))
            continue
        try:
            lines = target.read_text(encoding='utf-8', errors='replace').splitlines()
        except OSError as e:
            findings.append(('fail', cite_line, f"{raw}:{line_no} — unreadable: {e}"))
            continue
        if line_end > len(lines):
            findings.append(('fail', cite_line, f"{raw}:{line_no} — file has only {len(lines)} lines"))
            continue
        # advisory: a backticked snippet in the citing sentence should appear near the spot
        sent_start = max(text.rfind('.', 0, m.start()), text.rfind('\n', 0, m.start()))
        sentence = text[sent_start + 1: m.end() + 120]
        for snip in SNIPPET.findall(sentence):
            if '/' in snip or snip.endswith(('.md', '.sh', '.py')):
                continue  # that's a path, not a content snippet
            lo, hi = max(0, line_no - 1 - near), min(len(lines), line_end + near)
            if not any(snip in l for l in lines[lo:hi]):
                level = 'fail' if strict else 'note'
                findings.append((level, cite_line, f"{raw}:{line_no} — snippet `{snip}` not within {near} lines of the cited spot"))
            break
    return findings


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('docs', nargs='+')
    ap.add_argument('--root', default='.')
    ap.add_argument('--near', type=int, default=5)
    ap.add_argument('--strict-snippets', action='store_true')
    ap.add_argument('--json', action='store_true')
    a = ap.parse_args(argv)
    root = Path(a.root).resolve()
    worst = 0
    out = []
    for doc in a.docs:
        if not Path(doc).exists():
            print(f"{doc}: not found", file=sys.stderr)
            return 2
        fs = check_doc(doc, root, a.near, a.strict_snippets)
        fails = [f for f in fs if f[0] == 'fail']
        worst = max(worst, 1 if fails else 0)
        if a.json:
            out += [{'doc': doc, 'line': l, 'level': lv, 'msg': m} for lv, l, m in fs]
        else:
            for lv, l, msg in fs:
                print(f"{doc}:{l}  {lv:4}  {msg}")
            n_cites = len(list(CITE.finditer(Path(doc).read_text(errors='replace'))))
            print(f"{doc}: {n_cites} citation(s), {len(fails)} drifted, {len(fs)-len(fails)} advisory")
    if a.json:
        print(json.dumps(out))
    return worst


if __name__ == '__main__':
    sys.exit(main())
