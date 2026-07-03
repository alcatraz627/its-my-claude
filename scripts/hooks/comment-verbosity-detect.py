#!/usr/bin/env python3
"""Finds the over-long comment blocks a reviewer would hand-prune.

The companion detector for guard-comment-verbosity.sh. It reads one source file
(the added slice the agent just wrote), locates every self-contained comment
block, and reports only the ones long enough to read as a "code essay" rather
than a comment. A block is a Python docstring, a JS/TS block comment, or a run of
consecutive full-line comments. Length is measured in non-blank prose lines.

It deliberately does NOT try to judge whether prose "restates the code" — a line
regex cannot tell an essay from a load-bearing caveat, so cleanup-comments/detect.py
leaves that whole tier to the agent, and so do we. Length is the one mechanical
proxy for verbosity that stays high-precision, and even that is tuned to spare the
legitimate long comment: license headers, structured API docs (@param/@returns),
pragma blocks (eslint-disable/@ts-/noqa), decorative banners (owned by
comment-hygiene), and module orientations all get a pass or a higher bar.

Output: JSON {"findings": [...], "worst": {...}|null} to stdout. Empty findings =
nothing to say. Thresholds are env-overridable so the replay can sweep them.

Usage: comment-verbosity-detect.py FILE   (comment syntax keys off the extension)
"""
from __future__ import annotations

import json
import os
import re
import sys

DOC_MAX = int(os.environ.get("COMMENT_VERBOSITY_DOC_MAX", "10"))
# Fire on a run of >10 consecutive full-line comments. Started at 8; corpus replay
# showed 9-line runs are routinely legitimate (a cache-key explanation, a file
# header, a reference table), so tightened to 10 for precision — a genuinely-needed
# long explanation must not fire.
RUN_MAX = int(os.environ.get("COMMENT_VERBOSITY_RUN_MAX", "10"))
# A module/file-header block explaining the whole file is legitimately longer than
# an inline comment, so it earns a higher bar before it reads as an essay.
MODULE_DOC_MAX = int(os.environ.get("COMMENT_VERBOSITY_MODULE_DOC_MAX", "16"))

JS_EXT = {".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".mts", ".cts"}

# A long block carrying any of these is load-bearing, not verbose. Skip it whole.
LICENSE_RE = re.compile(
    r"copyright|SPDX-|@license|@preserve|licensed under|MIT License|Apache License"
    r"|BSD License|GNU |GPLv?|LGPL|MPL|permission is hereby granted"
    r"|all rights reserved|redistribution and use",
    re.IGNORECASE,
)
PROTECTED_RE = re.compile(
    r"eslint-disable|eslint-enable|@ts-(expect-error|ignore|nocheck|check)"
    r"|biome-ignore|prettier-ignore|istanbul ignore|c8 ignore|\bnoqa\b"
    r"|type:\s*ignore|coverage:\s*ignore|pyright:\s*ignore",
    re.IGNORECASE,
)
# A real API doc documents a contract; its length is earned. Presence of any of
# these structured tags means "hands off".
JSDOC_STRUCT_TAG = re.compile(
    r"@(param|returns?|throws|template|typeParam|typedef|callback|prop|property"
    r"|arg|argument|yields?|type|enum|namespace|interface)\b",
    re.IGNORECASE,
)
BANNER_RUN = re.compile(r"[-=*#~_+─━═]{6,}")


def is_banner_body(body: str) -> bool:
    """True if a comment's payload is mostly rule/box characters (a divider)."""
    if not BANNER_RUN.search(body):
        return False
    residue = re.sub(r"[-=*#~_+─━═\s]", "", body)
    return len(residue) <= 3


def banner_dominated(inner: list[str]) -> bool:
    """True if most non-blank lines of a block are decorative dividers."""
    nb = [x for x in inner if x.strip()]
    if not nb:
        return False
    banners = sum(1 for x in nb if is_banner_body(x))
    return banners * 2 >= len(nb)


def first_prose(inner: list[str], is_py: bool) -> str:
    """A short human-readable sample line from the block, for the nudge message."""
    for x in inner:
        s = x.strip()
        if is_py:
            s = s.lstrip("#").strip()
        else:
            s = re.sub(r"^(///?|/\*\*?|\*/|\*)\s?", "", s).strip()
        if s and not is_banner_body(s):
            return s[:80]
    return ""


def excluded(block_text: str) -> bool:
    return bool(LICENSE_RE.search(block_text) or PROTECTED_RE.search(block_text))


def find_triple_strings(text: str):
    """Pair every triple-quoted string in the file (docstring OR data), so a
    closing delimiter is never mistaken for a fresh opening.

    Yields (start_line, end_line, is_doc) 1-based. is_doc is True only when the
    string opens a bare expression statement (nothing but an optional r/b/f prefix
    precedes it on its line) — a real docstring, not an assignment (x = triple)
    or a call argument (foo(triple)). Consuming assignment/argument strings too is
    the whole point: it stops their CLOSING delimiter from being read as a new
    docstring open — the bug that swallowed 24 lines of code as prose in
    PartTypeClassifierAgent.py.
    """
    out = []
    i, L = 0, len(text)
    while True:
        d, s = text.find('"""', i), text.find("'''", i)
        cands = [x for x in (d, s) if x != -1]
        if not cands:
            break
        idx = min(cands)
        delim = text[idx:idx + 3]
        line_start = text.rfind("\n", 0, idx) + 1
        prefix = text[line_start:idx]
        is_doc = re.fullmatch(r"[rbufRBUF]{0,2}", prefix.strip()) is not None
        close = text.find(delim, idx + 3)
        start_line = text.count("\n", 0, idx) + 1
        if close == -1:  # unterminated (partial edit slice) — runs to EOF
            end_line = text.count("\n", 0, L) + 1
            out.append((start_line, end_line, is_doc))
            break
        end_line = text.count("\n", 0, close) + 1
        out.append((start_line, end_line, is_doc))
        i = close + 3
    return out


def scan_py(lines: list[str]) -> list[dict]:
    findings: list[dict] = []
    n = len(lines)
    # Index (0-based) of the first real content line (past shebang / coding decl).
    first_stmt = 0
    while first_stmt < n:
        s = lines[first_stmt].strip()
        if not s or s.startswith("#!") or s.startswith("# -*-") or "coding:" in s:
            first_stmt += 1
            continue
        break

    text = "\n".join(lines)
    inside: set[int] = set()  # 1-based lines that live inside ANY triple string
    for start_line, end_line, is_doc in find_triple_strings(text):
        for ln in range(start_line, end_line + 1):
            inside.add(ln)
        if not is_doc:
            continue
        inner = lines[start_line:end_line - 1]  # strictly between the delimiters
        block_text = "\n".join(lines[start_line - 1:end_line])
        if excluded(block_text) or banner_dominated(inner):
            continue
        nonblank = [x for x in inner if x.strip()]
        is_module = (start_line - 1) == first_stmt
        thr = MODULE_DOC_MAX if is_module else DOC_MAX
        if len(nonblank) > thr:
            findings.append({
                "kind": "module-docstring" if is_module else "docstring",
                "lines": len(nonblank), "start": start_line,
                "threshold": thr, "sample": first_prose(inner, True),
            })

    findings += scan_line_runs(lines, "#", is_py=True, exclude=inside)
    return findings


def scan_js(lines: list[str]) -> list[dict]:
    findings: list[dict] = []
    n = len(lines)
    first_stmt = 0
    while first_stmt < n and not lines[first_stmt].strip():
        first_stmt += 1

    i = 0
    while i < n:
        s = lines[i].lstrip()
        # A block comment that OPENS the line (not a trailing `code; /* x */`).
        if s.startswith("/*"):
            start = i
            inner: list[str] = []
            # single-line /* ... */
            if "*/" in s[2:]:
                i += 1
                continue
            j = i + 1
            closed = False
            while j < n:
                if "*/" in lines[j]:
                    closed = True
                    break
                inner.append(lines[j])
                j += 1
            if not closed:
                j = n - 1
            block_text = "\n".join(lines[start:j + 1])
            skip = (
                excluded(block_text)
                or JSDOC_STRUCT_TAG.search(block_text)
                or banner_dominated(inner)
            )
            if not skip:
                nonblank = [x for x in inner if x.strip()]
                is_header = start <= first_stmt
                thr = MODULE_DOC_MAX if is_header else DOC_MAX
                if len(nonblank) > thr:
                    findings.append({
                        "kind": "block-comment", "lines": len(nonblank),
                        "start": start + 1, "threshold": thr,
                        "sample": first_prose(inner, False),
                    })
            i = j + 1
            continue
        i += 1

    findings += scan_line_runs(lines, "//", is_py=False)
    return findings


def scan_line_runs(lines: list[str], marker: str, is_py: bool,
                   exclude: set[int] | None = None) -> list[dict]:
    """Runs of consecutive FULL-LINE comments (trailing `code # x` never counts).

    `exclude` is a set of 1-based line numbers to treat as non-comment — used to
    skip `#`-lines that actually live inside a triple-quoted string, so a docstring
    full of `# example` lines is not double-counted as a comment run.
    """
    exclude = exclude or set()
    findings: list[dict] = []
    run: list[str] = []
    run_start = 0
    n = len(lines)

    def flush(end_idx: int):
        if len(run) <= RUN_MAX:
            return
        block_text = "\n".join(run)
        if excluded(block_text) or banner_dominated(run):
            return
        nonblank = [x for x in run if x.strip()]
        if len(nonblank) > RUN_MAX:
            findings.append({
                "kind": "comment-run", "lines": len(nonblank),
                "start": run_start + 1, "threshold": RUN_MAX,
                "sample": first_prose(run, is_py),
            })

    for idx in range(n):
        s = lines[idx].strip()
        is_cmt = (idx + 1) not in exclude and (
            (is_py and s.startswith("#") and not s.startswith("#!"))
            or (not is_py and (s.startswith("//")))
        )
        if is_cmt:
            if not run:
                run_start = idx
            run.append(lines[idx])
        else:
            flush(idx)
            run = []
    flush(n)
    return findings


def main(argv: list[str]) -> int:
    if not argv:
        print(json.dumps({"findings": [], "worst": None}))
        return 0
    path = argv[0]
    ext = os.path.splitext(path)[1].lower()
    try:
        text = open(path, "r", encoding="utf-8", errors="replace").read()
    except OSError:
        print(json.dumps({"findings": [], "worst": None}))
        return 0
    lines = text.splitlines()

    if ext == ".py":
        findings = scan_py(lines)
    elif ext in JS_EXT:
        findings = scan_js(lines)
    else:
        findings = []

    worst = max(findings, key=lambda f: f["lines"]) if findings else None
    print(json.dumps({"findings": findings, "worst": worst}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
