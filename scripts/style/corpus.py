#!/usr/bin/env python3
"""Enumerate markdown across the account's repos and label each file by the
audience it was written for and the channel that wrote it.

Destination is the axis the owner cares about: he tolerates agent-only prose
and objects to anything that lands in a repo a person reads.
"""
import os, json, os, subprocess, sys, datetime, re

ROOTS = ["/Users/alcatraz627/Code/Versable", "/Users/alcatraz627/Code/Claude",
         "/Users/alcatraz627/Code"]
SKIP_DIR = re.compile(r"/(node_modules|\.git|\.next|dist|build|venv|\.venv|__pycache__|site-packages)/")

def destination(p, repo):
    rel = os.path.relpath(p, repo)
    base = os.path.basename(p)
    if "/.claude/output/" in p or rel.startswith(".claude/output/"): return "agent-only:output"
    if base.startswith("_") and base.endswith(".claude.md"):        return "agent-only:checkpoint"
    if "/.claude/session-notes/" in p:                              return "agent-only:notes"
    if "/.claude/" in p:                                            return "agent-only:other"
    if base in ("README.md", "CONTRIBUTING.md", "CHANGELOG.md"):    return "repo-visible:readme"
    if base in ("CLAUDE.md", "AGENTS.md"):                          return "agent-only:instructions"
    if rel.startswith("docs/") or "/docs/" in p:                    return "repo-visible:docs"
    return "repo-visible:other"

def repos():
    seen = set()
    for r in ROOTS:
        if not os.path.isdir(r): continue
        for d in sorted(os.listdir(r)):
            p = os.path.join(r, d)
            if os.path.isdir(os.path.join(p, ".git")) and p not in seen:
                seen.add(p); yield p

def main():
    out = []
    for repo in repos():
        for dirpath, dirnames, filenames in os.walk(repo):
            if SKIP_DIR.search(dirpath + "/"): 
                dirnames[:] = []
                continue
            dirnames[:] = [d for d in dirnames if d not in
                           ("node_modules",".git",".next","dist","build","venv",".venv","__pycache__")]
            for fn in filenames:
                if not fn.endswith(".md"): continue
                p = os.path.join(dirpath, fn)
                try: st = os.stat(p)
                except OSError: continue
                if st.st_size == 0 or st.st_size > 900_000: continue
                out.append({
                    "path": p,
                    "repo": os.path.basename(repo),
                    "dest": destination(p, repo),
                    "mtime": datetime.date.fromtimestamp(st.st_mtime).isoformat(),
                    "bytes": st.st_size,
                })
    with open(os.environ.get("DOCCORPUS", "/Users/alcatraz627/.claude/assets/reports/20260831-doc-prose-causes/corpus.jsonl"), "w") as f:
        for r in out: f.write(json.dumps(r) + "\n")
    from collections import Counter
    c = Counter(r["dest"] for r in out)
    print(f"corpus: {len(out)} markdown files across {len(set(r['repo'] for r in out))} repos\n")
    for k, n in sorted(c.items(), key=lambda kv: -kv[1]):
        print(f"  {k:28s} {n:5d}")
    print()
    recent = [r for r in out if r["mtime"] >= "2026-07-28"]
    cr = Counter(r["dest"] for r in recent)
    print(f"written on/after the prose gate landed (2026-07-28): {len(recent)}")
    for k, n in sorted(cr.items(), key=lambda kv: -kv[1]):
        print(f"  {k:28s} {n:5d}")

main()
