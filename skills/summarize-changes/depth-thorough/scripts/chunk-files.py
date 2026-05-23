#!/usr/bin/env python3
"""chunk-files.py — group files into semantic chunks for sub-agent fan-out.

Strategy (per FINAL-PLAN.md C5 fix):
  1. Group by 2-3 segment path prefix (e.g., backend/lib, frontend/src/app/jobs).
  2. Split groups >MAX_FILES into sub-chunks.
  3. Merge groups <MIN_FILES into a _misc bucket per top-level area.
  4. If resulting chunks > MAX_CHUNKS, fall back to size-balanced flat chunking.

Output: 04-chunks.json with [{id, files, total_bytes}, ...]
"""
import sys, os, json, argparse
from collections import defaultdict

ap = argparse.ArgumentParser()
ap.add_argument("--input", default="03-files-relevant.txt")
ap.add_argument("--output", default="04-chunks.json")
ap.add_argument("--target-files", type=int, default=40)
ap.add_argument("--max-files", type=int, default=60)
ap.add_argument("--min-files", type=int, default=8)
ap.add_argument("--max-chunks", type=int, default=30)  # hard cap from voter-1 mitigation
args = ap.parse_args()

with open(args.input) as f:
    paths = [l.strip() for l in f if l.strip()]

def file_bytes(p):
    try: return os.path.getsize(p)
    except OSError: return 0

def prefix_key(p, depth=3):
    parts = p.split("/")
    return "/".join(parts[:min(depth, len(parts))])

# Group by prefix
groups = defaultdict(list)
for p in paths:
    groups[prefix_key(p, 3)].append(p)

# Split / merge
chunks = []
misc_by_top = defaultdict(list)
for key, files in sorted(groups.items()):
    if len(files) < args.min_files:
        top = key.split("/")[0] if "/" in key else "_root"
        misc_by_top[top].extend(files)
    elif len(files) > args.max_files:
        for i in range(0, len(files), args.target_files):
            sub = files[i:i+args.target_files]
            sub_id = f"{key.replace('/', '-')}-p{i//args.target_files+1}"
            chunks.append({"id": sub_id, "files": sub})
    else:
        chunks.append({"id": key.replace("/", "-"), "files": files})

for top, files in misc_by_top.items():
    if files:
        chunks.append({"id": f"_misc-{top}", "files": files})

# Hard chunk cap fallback
if len(chunks) > args.max_chunks:
    # Flatten and re-bucket by size
    all_files = sorted({f for c in chunks for f in c["files"]})
    target = max(args.target_files, (len(all_files) // args.max_chunks) + 1)
    chunks = []
    for i in range(0, len(all_files), target):
        chunks.append({"id": f"flat-{i//target+1:02d}", "files": all_files[i:i+target]})

# Add byte sizes + sort by size desc
for c in chunks:
    c["total_bytes"] = sum(file_bytes(f) for f in c["files"])
chunks.sort(key=lambda c: -c["total_bytes"])
for i, c in enumerate(chunks, 1):
    c["index"] = i
    c["id"] = f"{i:02d}-{c['id']}"

with open(args.output, "w") as f:
    json.dump(chunks, f, indent=2)

total_files = sum(len(c["files"]) for c in chunks)
total_bytes = sum(c["total_bytes"] for c in chunks)
print(f"chunked: {len(chunks)} chunks, {total_files} files, {total_bytes//1024} KB total")
