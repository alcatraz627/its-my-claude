#!/usr/bin/env python3
"""apply-filters.py — filter 02-files.txt to 03-files-relevant.txt.

Default excludes (per FINAL-PLAN.md C6 fix — no docs):
  .claude/, *.lock, package-lock.json, uv.lock, node_modules/,
  dist/, .next/, .turbo/, *.svg, *.min.js, *.min.css

Usage:
  apply-filters.py [--exclude PATTERN ...] [--include PATTERN ...] [--max-size BYTES]
"""
import sys, os, argparse, fnmatch

DEFAULT_EXCLUDES = [
    ".claude/*", "*/.claude/*",
    "*.lock", "package-lock.json", "uv.lock", "poetry.lock", "yarn.lock",
    "node_modules/*", "*/node_modules/*",
    "dist/*", "*/dist/*", ".next/*", "*/.next/*", ".turbo/*", "*/.turbo/*",
    "*.svg", "*.min.js", "*.min.css",
]

ap = argparse.ArgumentParser()
ap.add_argument("--exclude", action="append", default=[])
ap.add_argument("--include", action="append", default=[])
ap.add_argument("--max-size", type=int, default=0, help="max file size in bytes (0=no cap)")
ap.add_argument("--input", default="02-files.txt")
ap.add_argument("--output", default="03-files-relevant.txt")
ap.add_argument("--excludes-file", default=None,
                help="path to a .discover-excludes file (one glob per line); "
                     "auto-detected at repo root if not given")
args = ap.parse_args()

# Per-repo excludes (W5): a `.discover-excludes` file at the repo root lets a
# project opt into excluding paths the global defaults keep (e.g. docs-as-code
# repos exclude `frontend/docs/**`). One glob per line; `#` comments allowed.
def load_repo_excludes(explicit):
    candidates = []
    if explicit:
        candidates.append(explicit)
    else:
        # Walk up from CWD looking for a repo-root marker + the excludes file.
        d = os.getcwd()
        for _ in range(6):
            candidates.append(os.path.join(d, ".discover-excludes"))
            if os.path.isdir(os.path.join(d, ".git")):
                break
            parent = os.path.dirname(d)
            if parent == d:
                break
            d = parent
    for path in candidates:
        if os.path.exists(path):
            with open(path) as f:
                pats = [l.strip() for l in f
                        if l.strip() and not l.strip().startswith("#")]
            if pats:
                print(f"loaded {len(pats)} repo excludes from {path}")
                return pats
    return []

repo_excludes = load_repo_excludes(args.excludes_file)
excludes = DEFAULT_EXCLUDES + repo_excludes + args.exclude
includes = args.include  # if set, file must match at least one

with open(args.input) as f:
    paths = [l.strip() for l in f if l.strip()]

kept, dropped = [], 0
for p in paths:
    if any(fnmatch.fnmatch(p, pat) for pat in excludes):
        dropped += 1; continue
    if includes and not any(fnmatch.fnmatch(p, pat) for pat in includes):
        dropped += 1; continue
    if args.max_size and os.path.exists(p) and os.path.getsize(p) > args.max_size:
        dropped += 1; continue
    kept.append(p)

with open(args.output, "w") as f:
    f.write("\n".join(kept) + ("\n" if kept else ""))

print(f"filtered: {len(kept)} kept, {dropped} dropped")
