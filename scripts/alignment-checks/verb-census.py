#!/usr/bin/env python3
"""Count which task, board and goal verbs agents actually reach for.

Reads every Bash tool call in the last N days of transcripts and tallies the
verb used on task.sh, task-table.sh, kanban.sh and goal.sh, by call and by
session. The census decides which verbs become one keystroke and which get a
flag (owner ruling 2026-09-08, d).

Usage: verb-census.py [--days 14] [--out FILE]
"""
import collections
import glob
import json
import os
import re
import sys
import time

days = 14; out = None
a = sys.argv[1:]
i = 0
while i < len(a):
    if a[i] == "--days": days = int(a[i + 1]); i += 2
    elif a[i] == "--out": out = a[i + 1]; i += 2
    else: i += 1
cut = time.time() - days * 86400
pat = re.compile(r"(task\.sh|task-table\.sh|kanban\.sh|goal\.sh)\s+((?:--?[a-z-]+\s+)*)([a-z-]+)")
calls = collections.Counter(); sessions = collections.defaultdict(set); flags = collections.Counter()
for f in glob.glob(os.path.expanduser("~/.claude/projects/*/*.jsonl")):
    if os.stat(f).st_mtime < cut:
        continue
    sid = os.path.basename(f)[:8]
    for line in open(f, errors="ignore"):
        if "tool_use" not in line or ".sh" not in line:
            continue
        try:
            o = json.loads(line)
        except Exception:
            continue
        if o.get("type") != "assistant":
            continue
        for b in o.get("message", {}).get("content") or []:
            if b.get("type") != "tool_use" or b.get("name") != "Bash":
                continue
            cmd = (b.get("input") or {}).get("command", "")
            for tool, pre, verb in pat.findall(cmd):
                key = f"{tool} {verb}" if not verb.startswith("-") else f"{tool} {verb}"
                calls[key] += 1; sessions[key].add(sid)
                for fl in re.findall(r"--[a-z-]+", cmd):
                    flags[f"{tool} {fl}"] += 1
lines = [f"# Verb census, last {days} days", "", "| verb | calls | sessions |", "|---|---:|---:|"]
for k, n in calls.most_common():
    lines.append(f"| `{k}` | {n} | {len(sessions[k])} |")
lines += ["", "| flag | uses |", "|---|---:|"]
for k, n in flags.most_common(25):
    lines.append(f"| `{k}` | {n} |")
s = "\n".join(lines)
print(s)
if out:
    open(out, "w").write(s + "\n")
