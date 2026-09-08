#!/usr/bin/env python3
"""Stamp every store with more than N open rows with the project it belongs to.

A store without a .project stamp loses its project's grouping ruling whenever
the shell sits in another repo (alignment check 1). The project is read from
the transcript that created the store: the projects/ folder name encodes the
cwd. Usage: stamp-stores.py [--min-open 20] [--apply]
"""
import glob, json, os, sys

HOME = os.path.expanduser("~")
TASKS = os.path.join(HOME, ".claude", "tasks")
PROJECTS = os.path.join(HOME, ".claude", "projects")
min_open = 20; apply = "--apply" in sys.argv
if "--min-open" in sys.argv:
    min_open = int(sys.argv[sys.argv.index("--min-open") + 1])

def decode(folder):
    """projects folder name -> path; dashes stood for slashes and dots."""
    if not folder.startswith("-"):
        return None
    p = folder[1:].replace("-", "/")
    # the only dotted segment on this machine is .claude
    p = "/" + p.replace("/claude/", "/.claude/").replace("Users/alcatraz627//claude", "Users/alcatraz627/.claude")
    return p if os.path.isdir(p) else None

for d in sorted(glob.glob(os.path.join(TASKS, "session-*"))):
    if os.path.exists(os.path.join(d, ".project")):
        continue
    sid8 = os.path.basename(d)[len("session-"):]
    open_rows = 0
    for f in glob.glob(os.path.join(d, "*.json")):
        try:
            t = json.load(open(f))
        except Exception:
            continue
        if isinstance(t, dict) and t.get("status") != "completed":
            open_rows += 1
    if open_rows <= min_open:
        continue
    hits = glob.glob(os.path.join(PROJECTS, "*", f"{sid8}*.jsonl"))
    proj = decode(os.path.basename(os.path.dirname(hits[0]))) if hits else None
    if not proj:
        print(f"{sid8}: {open_rows} open, no transcript found, left unstamped")
        continue
    print(f"{sid8}: {open_rows} open -> {proj}{'' if apply else ' (dry run)'}")
    if apply:
        open(os.path.join(d, ".project"), "w").write(proj)
