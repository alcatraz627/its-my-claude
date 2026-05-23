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
args = ap.parse_args()

excludes = DEFAULT_EXCLUDES + args.exclude
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
