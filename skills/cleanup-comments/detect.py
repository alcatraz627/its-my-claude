#!/usr/bin/env python3
"""Comment-hygiene detector for the enhancement-product monorepo.

Scans TS/TSX/JS/Python files for comment-style violations defined in
frontend/docs/tech/conventions/comment-style.md and reports them as JSON.

This script only DETECTS and proposes — it never edits a file. The
/cleanup-comments skill reads its findings, shows a preview, and applies
fixes with human judgment after confirmation. Splitting detection (regex,
deterministic) from application (context-aware, agent-driven) is deliberate:
a blind sed would strip a `[claude@]` tag AND the useful sentence attached
to it; the agent keeps the substance.

Findings are grouped into three tiers:
  - tier1_strip : mechanical, high-confidence noise (tags, plan-refs,
                  banners, archeology). Safe to remove the offending
                  fragment. Whole-line if the line is ONLY noise.
  - tier3_flag  : can't be verified mechanically (TODOs, possibly-stale
                  claims). Reported for human review, never auto-edited.

The judgment tier (tier2: essays, WHAT-comments) is intentionally NOT
detected here — line regex can't tell "essay" from "load-bearing caveat".
The agent handles tier2 by reading the file.

Usage:
  detect.py FILE [FILE ...]        # scan explicit files
  detect.py --changed [BASE]       # scan git-changed files (BASE auto-detected)
  detect.py --all                  # scan all tracked source in the repo
Output: JSON to stdout. Non-source / protected lines are never reported.

Repo-agnostic: works in any git repo. BASE defaults to the repo default
branch (origin/HEAD, else main/master/develop/development, else HEAD~1).
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

SOURCE_EXT = {".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".py"}

# Lines matching ANY of these are load-bearing and must NEVER be touched or
# even reported. They encode deliberate human/tooling decisions.
PROTECTED = re.compile(
    r"""
    NOTE\(by\ human\) | \bHACK\b | \bIMPORTANT\b | \bFIXME\(keep\) |
    eslint-disable | eslint-enable | @ts-(expect-error|ignore|nocheck) |
    biome-ignore | prettier-ignore | c8\ ignore | istanbul\ ignore |
    \bnoqa\b | type:\s*ignore | \bpragma\b | SPDX- | @license | Copyright |
    @param | @returns | @return | @throws | @deprecated | @see | @example |
    @ts-check | /\#\#\#/ | \#!/                         # shebang
    """,
    re.IGNORECASE | re.VERBOSE,
)

# A comment line, conservatively. We only act on lines that are clearly
# comments to avoid matching `//` inside a string literal or a URL.
TS_FULL_COMMENT = re.compile(r"^\s*(//+|/?\*+|\{/\*)")          # // ... or * ... or {/* ...
PY_FULL_COMMENT = re.compile(r"^\s*#")
TS_TRAILING = re.compile(r"\S\s+//\s")                          # code // comment
PY_TRAILING = re.compile(r"\S\s+#\s")                           # code  # comment

# tier1 mechanical patterns
CLAUDE_TAG = re.compile(r"\[claude@[^\]]*\]", re.IGNORECASE)
# Only the planning-doc vocabulary the rubric names (Phase 2.B8, Tier 1,
# Track H, Round 3 #1.2). NOT "Step 1:", since sequential code-step labels are
# legitimate and common in CLI/wizard flows.
PLAN_REF = re.compile(
    r"\b(?:Phase|Track|Round|Tier)\s+"
    r"(?:[0-9]+(?:\.[0-9A-Za-z]+)*|[A-Z]\b|v[0-9])",
)
VERSION_TRACK = re.compile(r"\bv[0-9]+\s+(?:Track|Phase|Round)\b", re.IGNORECASE)
ARCHEOLOGY = re.compile(
    r"\b(?:Pre-fix|Post-fix|used to be|previously was|replaces? (?:the )?backend"
    r"|as discussed on|See PR\s*#?\d+|per (?:our )?(?:chat|discussion))\b",
    re.IGNORECASE,
)
# Decorative banner: a comment whose payload is mostly box/rule characters.
BANNER_CHARS = re.compile(r"[─━═\-=*#~_]{6,}")

# tier2 voice patterns (AI-tells; fix needs judgment)
# Em dash and spaced en dash read as AI-generated prose. Comments should use
# plain punctuation (comma, period, parens) instead.
EM_DASH = re.compile(r"—|\s–\s")
# Real emoji + symbol + dingbat blocks. Arrows (U+2190-21FF) are deliberately
# excluded: `a -> b` "maps to" notation is legit in technical comments.
EMOJI = re.compile(
    "[\U0001f000-\U0001faff\U00002600-\U000026ff\U00002700-\U000027bf\U0001f1e6-\U0001f1ff]"
)

# tier3 flag-only patterns
TODO = re.compile(r"\b(?:TODO|FIXME|XXX|HACK_TEMP|TEMP)\b", re.IGNORECASE)
STALE_CLAIM = re.compile(r"\b(?:currently|for now|at the moment|right now)\b", re.IGNORECASE)


def is_comment_line(line: str, is_py: bool) -> bool:
    if is_py:
        return bool(PY_FULL_COMMENT.match(line) or PY_TRAILING.search(line))
    return bool(TS_FULL_COMMENT.match(line) or TS_TRAILING.search(line))


def comment_is_only_noise(line: str, noise: re.Pattern) -> bool:
    """True if removing the matched noise leaves an empty/markup-only comment."""
    stripped = line.strip()
    # peel comment markers
    body = re.sub(r"^(//+|/?\*+|\{/\*|#+)\s*", "", stripped)
    body = re.sub(r"(\*/|\*/\})\s*$", "", body).strip()
    residue = noise.sub("", body).strip()
    # residue made only of punctuation/markup → whole line is noise
    return residue == "" or re.fullmatch(r"[\W_]+", residue) is not None


def scan_file(path: Path) -> list[dict]:
    is_py = path.suffix == ".py"
    findings: list[dict] = []
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return findings

    for n, line in enumerate(text.splitlines(), start=1):
        if not is_comment_line(line, is_py):
            continue
        if PROTECTED.search(line):
            continue

        def add(category: str, tier: str, action: str, pattern: re.Pattern | None):
            whole = (
                pattern is not None
                and action == "strip"
                and comment_is_only_noise(line, pattern)
            )
            findings.append(
                {
                    "line": n,
                    "tier": tier,
                    "category": category,
                    "action": "delete_line" if whole else action,
                    "text": line.rstrip(),
                }
            )

        if CLAUDE_TAG.search(line):
            add("claude-tag", "tier1_strip", "strip", CLAUDE_TAG)
        if PLAN_REF.search(line) or VERSION_TRACK.search(line):
            pat = PLAN_REF if PLAN_REF.search(line) else VERSION_TRACK
            add("plan-ref", "tier1_strip", "strip", pat)
        if ARCHEOLOGY.search(line):
            add("archeology", "tier1_strip", "strip", ARCHEOLOGY)
        if BANNER_CHARS.search(line):
            # Pure rule line is deleted; a labelled banner keeps its label.
            add("decorative-banner", "tier1_strip", "strip", BANNER_CHARS)
        if EM_DASH.search(line):
            add("em-dash", "tier2_voice", "rewrite", None)
        if EMOJI.search(line):
            add("emoji", "tier2_voice", "rewrite", None)
        if TODO.search(line):
            add("todo", "tier3_flag", "flag", None)
        if STALE_CLAIM.search(line):
            add("possibly-stale", "tier3_flag", "flag", None)

    return findings


def repo_root() -> Path:
    res = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=False
    )
    return Path(res.stdout.strip()) if res.returncode == 0 else Path.cwd()


def resolve_changed(base: str) -> list[Path]:
    root = repo_root()
    out: set[Path] = set()
    cmds = [
        ["git", "diff", "--name-only", "--diff-filter=ACMR"],            # unstaged
        ["git", "diff", "--name-only", "--diff-filter=ACMR", "--cached"],  # staged
        ["git", "diff", "--name-only", "--diff-filter=ACMR", f"{base}...HEAD"],  # branch
    ]
    for cmd in cmds:
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, check=False, cwd=root)
            for f in res.stdout.splitlines():
                out.add(root / f.strip())
        except OSError:
            pass
    return [p for p in out if p.suffix in SOURCE_EXT and p.exists() and not _excluded(p)]


def _excluded(p: Path) -> bool:
    """Config / generated / vendored dirs the skill must never rewrite."""
    parts = set(p.parts)
    return bool(
        parts & {".claude", "node_modules", ".next", "dist", "build", "drizzle", ".git"}
    )


def default_base() -> str:
    """The repo's default branch, for the branch-diff leg of --changed.

    Tries origin/HEAD, then common branch names, then HEAD~1. Repo-agnostic
    so the skill works outside this monorepo.
    """
    root = repo_root()

    def have(ref: str) -> bool:
        return (
            subprocess.run(
                ["git", "rev-parse", "--verify", "--quiet", ref],
                capture_output=True,
                cwd=root,
                check=False,
            ).returncode
            == 0
        )

    head = subprocess.run(
        ["git", "symbolic-ref", "--quiet", "refs/remotes/origin/HEAD"],
        capture_output=True,
        text=True,
        cwd=root,
        check=False,
    ).stdout.strip()
    if head:
        return head.replace("refs/remotes/", "")
    for ref in ("main", "master", "develop", "development"):
        if have(ref):
            return ref
    return "HEAD~1"


def resolve_all() -> list[Path]:
    """All tracked source files in the repo (any SOURCE_EXT), minus excluded dirs."""
    root = repo_root()
    res = subprocess.run(
        ["git", "ls-files"], capture_output=True, text=True, check=False, cwd=root
    )
    paths = []
    for f in res.stdout.splitlines():
        p = root / f.strip()
        if p.suffix in SOURCE_EXT and p.exists() and not _excluded(p):
            paths.append(p)
    return paths


def main(argv: list[str]) -> int:
    if not argv:
        print(__doc__)
        return 2

    if argv[0] == "--changed":
        base = argv[1] if len(argv) > 1 else default_base()
        files = resolve_changed(base)
    elif argv[0] == "--all":
        files = resolve_all()
    else:
        files = [Path(a) for a in argv if Path(a).suffix in SOURCE_EXT]

    report = {
        "files": [],
        "totals": {"tier1_strip": 0, "tier2_voice": 0, "tier3_flag": 0, "files_with_findings": 0},
    }
    for path in sorted(set(files)):
        findings = scan_file(path)
        if not findings:
            continue
        report["files"].append({"path": str(path), "findings": findings})
        report["totals"]["files_with_findings"] += 1
        for f in findings:
            report["totals"][f["tier"]] = report["totals"].get(f["tier"], 0) + 1

    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
