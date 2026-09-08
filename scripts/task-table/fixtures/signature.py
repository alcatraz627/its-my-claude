#!/usr/bin/env python3
"""What a rendered task table promises, stripped of everything that ages.

A golden made of the render's text would go stale every hour (gate ages, "moved
in the last 6h"). This keeps the parts a regression would change: the header's
counts, which ids reached the screen, and the height.

Usage: signature.py < render.txt      prints the signature, one fact per line
"""
import re
import sys

text = sys.stdin.read()
lines = text.splitlines()
head = lines[0] if lines else ""
out = []
for label, pat in (("goals", r"(\d+) goal tags?, (\d+) met"),
                   ("milestones", r"\U0001F3C1 (\d+) of (\d+)"),
                   ("need_you", r"\U0001F534 (\d+) need you")):
    m = re.search(pat, head)
    out.append(f"{label}={'/'.join(m.groups()) if m else 'none'}")
# a meter that reads 0 of 0 over live rows is the cold read's clearest lie
# (cold-read-P2.md Q2, 2026-09-08); the count of such lines is part of the shape
out.append(f"zero_meters={sum(1 for l in lines if '0 of 0 milestones' in l)}")
# a row's id follows its ASCII state twin, or a CLEAR NOW index at line start
ids = set()
for m in re.finditer(r"(?m)^\s+\d+\s+#(\d+)\s", text):
    ids.add(int(m.group(1)))
for m in re.finditer(r"[!~▶○=z·@x] #(\d+)\s", text):
    ids.add(int(m.group(1)))
ids = sorted(ids)
out.append(f"rows_on_screen={len(ids)}")
out.append(f"ids={','.join(str(i) for i in ids)}")
m = re.search(r"height (\d+)/(\d+)", text)
out.append(f"height={m.group(1) if m else 'none'}")
out.append(f"clear_now={'yes' if 'CLEAR NOW' in text else 'no'}")
print("\n".join(out))
