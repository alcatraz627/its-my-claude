#!/usr/bin/env python3
"""The short form of an adversarial-review indictment, for pasting into a reply.

The full findings table runs to six columns of proof and does not survive a
terminal. This prints what the owner reads first: the report's own verdict
lines, then one row per finding in the prosecutor's order, each holding the
claim numbers it refutes and the opening sentences of its "what is actually
broken" cell, cut at a word if long.
Every word is lifted from the report, so the summary cannot soften or drop a
finding; the full table stays in the file, linked on the last line.

Usage: digest.py <indictment.md>
"""
import os
import re
import sys

MAX = 200
MIN = 60


def cells(line):
    parts = line.strip().strip("|").split("|")
    return [p.strip() for p in parts]


def lead(text):
    """The prosecutor's opening sentences, enough to stand alone, cut at a word if long."""
    text = re.sub(r"\*\*|(?<!\w)\*(?!\s)|(?<!\s)\*(?!\w)", "", text)
    ends = [m.start() for m in re.finditer(r"(?<=[a-z0-9)`\"'%])\.\s+(?=[A-Z`\"*(])", text)]
    s = text.rstrip(".")
    for e in ends:
        # A short opener ("A3 targets the wrong place") needs the sentence that says why.
        if e >= MIN:
            s = text[:e]
            break
    if len(s) > MAX:
        s = s[:MAX].rsplit(" ", 1)[0].rstrip(",;:.") + " …"
    return s.replace("|", "\\|")


def claim_ids(text):
    m = re.match(r"\s*((?:#\d+[,\s]*)+)", text)
    return m.group(1).strip(" ,") if m else "-"


def main():
    if len(sys.argv) != 2:
        print("usage: digest.py <indictment.md>", file=sys.stderr)
        return 2
    path = os.path.abspath(sys.argv[1])
    lines = open(path, encoding="utf-8").read().splitlines()
    head = [l for l in lines[:12] if l.startswith("**Prior:**") or l.startswith("**Claims ledger:**")]

    header, rows, section = None, [], ""
    failed = unconfirmed = 0
    for l in lines:
        if l.startswith("## "):
            section = l.lower()
            continue
        if "findings" in section and l.startswith("|"):
            c = cells(l)
            if header is None:
                header = [h.lower() for h in c]
                continue
            if set(l.replace("|", "").strip()) <= set("-: "):
                continue
            rows.append(dict(zip(header, c)))
        elif "failed attacks" in section and l.startswith("- "):
            failed += 1
            unconfirmed += "UNCONFIRMED" in l

    broken_key = next((h for h in (header or []) if "broken" in h), None)
    out = list(head)
    if rows and broken_key:
        claim_key = next((h for h in header if "claim" in h), None)
        out += ["", "| # | evidence | refutes | what is broken |", "|---|---|---|---|"]
        for r in rows:
            ids = claim_ids(r.get(claim_key, "")) if claim_key else "-"
            out.append(f"| {r.get('rank', '?')} | {r.get('evidence', '?')} | {ids} | {lead(r.get(broken_key, ''))} |")
    elif not rows:
        out += ["", "No findings in the main table."]
    if failed:
        held = failed - unconfirmed
        out += ["", f"{held} attack(s) did not land; {unconfirmed} could not be checked (UNCONFIRMED)."]
    out += ["", "Full findings with proof:", path]
    print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
