#!/usr/bin/env python3
"""verify-coverage.py — count `## File:` headers per inventory chunk vs expected.

Flags under-reported chunks for V2 themes agent to cross-check.

Usage:
  verify-coverage.py <inventory-dir> <chunks-json>
Writes: <inventory-dir>/_coverage.json with per-chunk {expected, found, dropped_files}
"""
import sys, os, json, re

inv_dir, chunks_path = sys.argv[1], sys.argv[2]
with open(chunks_path) as f:
    chunks = json.load(f)

report = {}
for c in chunks:
    chunk_id = c["id"]
    expected = len(c["files"])
    path = os.path.join(inv_dir, f"{chunk_id}.md")
    if not os.path.exists(path):
        report[chunk_id] = {"expected": expected, "found": 0, "status": "MISSING_FILE"}
        continue
    with open(path) as f: content = f.read()
    # Match `## File: <path>` headers
    found_paths = set(re.findall(r"^##\s+File:\s*(\S+)", content, re.MULTILINE))
    found = len(found_paths)
    expected_set = set(c["files"])
    dropped = sorted(expected_set - found_paths)
    extra = sorted(found_paths - expected_set)
    status = "OK" if found >= expected * 0.9 else ("UNDER" if found > 0 else "EMPTY")
    report[chunk_id] = {
        "expected": expected, "found": found, "status": status,
        "dropped_files": dropped[:20], "extra_files": extra[:5],
    }

out_path = os.path.join(inv_dir, "_coverage.json")
with open(out_path, "w") as f: json.dump(report, f, indent=2)

under = [k for k, v in report.items() if v["status"] != "OK"]
print(f"coverage: {len(report)} chunks, {len(under)} under-reported")
for k in under:
    v = report[k]
    print(f"  {k}: {v['found']}/{v['expected']} ({v['status']})")
