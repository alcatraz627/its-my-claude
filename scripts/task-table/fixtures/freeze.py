#!/usr/bin/env python3
"""Freeze a real task store as a fixture, with the golden its render must keep.

The bundle carries every row plus its file's write time, so a later unpack
reproduces the store as it was. The golden is the structural signature of the
render from the store's own project directory (signature.py), not the text.

Usage: freeze.py <sid8> [<sid8> ...]
"""
import glob
import json
import os
import subprocess
import sys

HOME = os.path.expanduser("~")
FX = os.path.join(HOME, ".claude", "scripts", "task-table", "fixtures")
TABLE = os.path.join(HOME, ".claude", "scripts", "task-table", "task-table.sh")

for sid in sys.argv[1:]:
    store = os.path.join(HOME, ".claude", "tasks", f"session-{sid}")
    rows = []
    for f in sorted(glob.glob(os.path.join(store, "*.json"))):
        rows.append({"name": os.path.basename(f), "mtime": os.stat(f).st_mtime,
                     "row": json.load(open(f))})
    project = ""
    pf = os.path.join(store, ".project")
    if os.path.exists(pf):
        project = open(pf).read().strip()
    bundle = {"sid": sid, "project": project, "rows": rows}
    json.dump(bundle, open(os.path.join(FX, f"session-{sid}.json"), "w"), indent=0)
    render = subprocess.run(["bash", TABLE, "--session", sid], cwd=project or HOME,
                            capture_output=True, text=True).stdout
    sig = subprocess.run(["python3", os.path.join(FX, "signature.py")], input=render,
                         capture_output=True, text=True).stdout
    open(os.path.join(FX, f"session-{sid}.golden.txt"), "w").write(sig)
    print(f"froze session-{sid}: {len(rows)} rows, project={project or '(none)'}")
    print(sig)
