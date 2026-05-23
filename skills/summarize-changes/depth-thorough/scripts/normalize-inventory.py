#!/usr/bin/env python3
"""normalize-inventory.py — defensive fixer for sub-agent inventory outputs.

Catches the "render-saved-as-source" pattern documented in
~/.claude/rules/sub-agent-outputs.md — sub-agents pipe output through TTY
renderers (gum, glow), producing markdown that's leading-space indented and
trailing-space padded. Renders fine in glow but breaks downstream parsing.

Strips:
  - Leading 2-space indent on every line (if >50% of non-blank lines have it)
  - Trailing whitespace on every line

Usage:
  normalize-inventory.py <file-or-dir>...
"""
import sys, os, re

def normalize(text):
    lines = text.split("\n")
    non_blank = [l for l in lines if l.strip()]
    if not non_blank:
        return text
    indented = sum(1 for l in non_blank if l.startswith("  "))
    if indented / len(non_blank) > 0.5:
        lines = [re.sub(r"^  ", "", l) for l in lines]
    lines = [l.rstrip() for l in lines]
    return "\n".join(lines)

def process(path):
    if os.path.isdir(path):
        n = 0
        for fn in sorted(os.listdir(path)):
            if fn.endswith(".md"):
                n += process(os.path.join(path, fn))
        return n
    with open(path) as f:
        orig = f.read()
    fixed = normalize(orig)
    if fixed != orig:
        with open(path, "w") as f: f.write(fixed)
        print(f"normalized: {path}")
        return 1
    return 0

total = sum(process(p) for p in sys.argv[1:])
print(f"normalized {total} file(s)")
