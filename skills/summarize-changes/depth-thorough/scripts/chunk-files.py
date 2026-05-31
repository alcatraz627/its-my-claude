#!/usr/bin/env python3
"""chunk-files.py — group files into semantic chunks for sub-agent fan-out.

Strategy:
  1. Drop binary/asset files (images, fonts, archives) — they bloat byte counts
     without inventory value.
  2. Group by 2-3 segment path prefix (e.g., backend/lib, frontend/src/app/jobs).
  3. Split groups >MAX_FILES into sub-chunks, but cap sub-chunks per prefix so one
     giant directory cannot blow the whole budget.
  4. Merge groups <MIN_FILES into _misc buckets per top-level area; split a _misc
     bucket if it overflows MAX_FILES_PER_MISC.
  5. Flat fallback ONLY when the count of *substantive* semantic chunks exceeds
     MAX_CHUNKS — not when many tiny groups exist (those collapse into _misc).

Output: 04-chunks.json with [{id, files, total_bytes, index}, ...]
"""
import sys, os, json, argparse
from collections import defaultdict

# Binary / asset extensions — inventoried as a single summary line, not file-by-file.
BINARY_EXTS = {
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico", ".bmp", ".tiff",
    ".pdf", ".woff", ".woff2", ".ttf", ".otf", ".eot",
    ".zip", ".gz", ".tar", ".mp4", ".mov", ".mp3", ".wav",
    ".sqlite", ".db", ".bin", ".wasm",
}

ap = argparse.ArgumentParser()
ap.add_argument("--input", default="03-files-relevant.txt")
ap.add_argument("--output", default="04-chunks.json")
ap.add_argument("--target-files", type=int, default=40)
ap.add_argument("--max-files", type=int, default=60)
ap.add_argument("--min-files", type=int, default=8)
ap.add_argument("--max-files-per-misc", type=int, default=200)
ap.add_argument("--max-subchunks-per-prefix", type=int, default=4)
ap.add_argument("--max-chunks", type=int, default=30)
args = ap.parse_args()

with open(args.input) as f:
    paths = [l.strip() for l in f if l.strip()]

def file_bytes(p):
    try: return os.path.getsize(p)
    except OSError: return 0

def is_binary(p):
    _, ext = os.path.splitext(p)
    return ext.lower() in BINARY_EXTS

def prefix_key(p, depth=3):
    parts = p.split("/")
    return "/".join(parts[:min(depth, len(parts))])

# 1. Partition binary assets out of the inventory stream.
binary_files = [p for p in paths if is_binary(p)]
code_files = [p for p in paths if not is_binary(p)]

# 2. Group code files by prefix.
groups = defaultdict(list)
for p in code_files:
    groups[prefix_key(p, 3)].append(p)

# 3/4. Split / merge into semantic chunks.
semantic_chunks = []   # substantive — counts toward the cap
misc_by_top = defaultdict(list)
for key, files in sorted(groups.items()):
    if len(files) < args.min_files:
        top = key.split("/")[0] if "/" in key else "_root"
        misc_by_top[top].extend(files)
    elif len(files) > args.max_files:
        # Split, but cap sub-chunks so a giant dir can't dominate.
        per = max(args.target_files, (len(files) // args.max_subchunks_per_prefix) + 1)
        for i in range(0, len(files), per):
            sub = files[i:i+per]
            sub_id = f"{key.replace('/', '-')}-p{i//per+1}"
            semantic_chunks.append({"id": sub_id, "files": sub})
    else:
        semantic_chunks.append({"id": key.replace("/", "-"), "files": files})

# _misc buckets (split if oversized).
misc_chunks = []
for top, files in misc_by_top.items():
    if not files:
        continue
    if len(files) > args.max_files_per_misc:
        per = args.target_files
        for i in range(0, len(files), per):
            misc_chunks.append({"id": f"_misc-{top}-p{i//per+1}", "files": files[i:i+per]})
    else:
        misc_chunks.append({"id": f"_misc-{top}", "files": files})

# 5. Flat fallback ONLY if substantive semantic chunks alone exceed the cap.
if len(semantic_chunks) > args.max_chunks:
    all_code = sorted({f for c in semantic_chunks for f in c["files"]})
    target = max(args.target_files, (len(all_code) // args.max_chunks) + 1)
    semantic_chunks = []
    for i in range(0, len(all_code), target):
        semantic_chunks.append({"id": f"flat-{i//target+1:02d}", "files": all_code[i:i+target]})

chunks = semantic_chunks + misc_chunks

# Binary assets get one summary chunk (inventoried as a count, not file-by-file).
if binary_files:
    chunks.append({"id": "_assets-binary", "files": binary_files, "binary_summary": True})

# Byte sizes + sort + index.
for c in chunks:
    c["total_bytes"] = sum(file_bytes(f) for f in c["files"])
chunks.sort(key=lambda c: (-int(c.get("binary_summary", False) is False), -c["total_bytes"]))
for i, c in enumerate(chunks, 1):
    c["index"] = i
    c["id"] = f"{i:02d}-{c['id']}"

with open(args.output, "w") as f:
    json.dump(chunks, f, indent=2)

total_files = sum(len(c["files"]) for c in chunks)
total_bytes = sum(c["total_bytes"] for c in chunks)
semantic_n = sum(1 for c in chunks if not c.get("binary_summary"))
print(f"chunked: {len(chunks)} chunks ({semantic_n} semantic + "
      f"{len(chunks)-semantic_n} binary-summary), {total_files} files, "
      f"{total_bytes//1024} KB total; dropped {len(binary_files)} binary files from inventory")
