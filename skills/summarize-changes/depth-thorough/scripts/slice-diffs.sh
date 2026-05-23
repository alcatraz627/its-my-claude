#!/usr/bin/env bash
# slice-diffs.sh — produce per-chunk diff files from a git range + chunks.json
#
# Usage:
#   slice-diffs.sh <range> [--include-worktree]
# Reads 04-chunks.json, writes diffs/<chunk-id>.diff per chunk.

set -euo pipefail
GIT=/usr/bin/git
range="${1:-}"; shift || true
include_wt=0
[[ "${1:-}" == "--include-worktree" ]] && include_wt=1

[[ -f 04-chunks.json ]] || { echo "no 04-chunks.json"; exit 2; }
mkdir -p diffs

GIT_ROOT=$($GIT rev-parse --show-toplevel)
python3 - <<PY
import json, subprocess, os
with open("04-chunks.json") as f: chunks = json.load(f)
range_ = "$range"
include_wt = bool($include_wt)
git_root = "$GIT_ROOT"
for c in chunks:
    out = f"diffs/{c['id']}.diff"
    files = c["files"]
    parts = []
    if range_:
        r = subprocess.run(["/usr/bin/git", "diff", range_, "--"] + files, capture_output=True, text=True, cwd=git_root)
        parts.append(r.stdout)
    if include_wt:
        r2 = subprocess.run(["/usr/bin/git", "diff", "--"] + files, capture_output=True, text=True, cwd=git_root)
        parts.append(r2.stdout)
        r3 = subprocess.run(["/usr/bin/git", "diff", "--cached", "--"] + files, capture_output=True, text=True, cwd=git_root)
        parts.append(r3.stdout)
    with open(out, "w") as f:
        f.write("\n".join(p for p in parts if p))
    sz = os.path.getsize(out)
    print(f"  {c['id']}: {len(files)} files, {sz//1024} KB diff")
PY
