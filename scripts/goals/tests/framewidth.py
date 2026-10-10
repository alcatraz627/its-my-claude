#!/usr/bin/env python3
"""Print the distinct display widths of every framed line in a render, one per line.
A square frame prints exactly one number."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from render import dwidth
ws = set()
for ln in open(sys.argv[1], encoding="utf-8"):
    ln = ln.rstrip("\n")
    if ln and ln[0] in "┌│└": ws.add(dwidth(ln))
for w in sorted(ws): print(w)
