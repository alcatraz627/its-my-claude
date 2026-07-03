#!/usr/bin/env python3
"""ta tags — list the bookmarks recorded by `ta tag`.

Reads the bookmarks ledger (TA_BOOKMARKS_STORE, else ~/.claude/ledger/
bookmarks.jsonl) and prints them newest-first, optionally filtered to one label.
The ledger CLI (`ledger list --src bookmarks`, `ledger show <id>`) reads the same
stream; this is the tool-local convenience view.
"""

import argparse
import json
import os
import sys


def store_path():
    return os.environ.get(
        "TA_BOOKMARKS_STORE",
        os.path.join(os.path.expanduser("~"), ".claude", "ledger", "bookmarks.jsonl"),
    )


def load(path, label=None):
    rows = []
    if not os.path.isfile(path):
        return rows
    with open(path, encoding="utf-8") as fh:
        for ln in fh:
            ln = ln.strip()
            if not ln:
                continue
            try:
                r = json.loads(ln)
            except Exception:
                continue
            if label and r.get("label") != label:
                continue
            rows.append(r)
    rows.sort(key=lambda r: r.get("ts", ""), reverse=True)
    return rows


def main(argv=None):
    ap = argparse.ArgumentParser(prog="ta tags", description="list transcript bookmarks")
    ap.add_argument("--label", help="only bookmarks with this label")
    ap.add_argument("--format", choices=["table", "jsonl"], default="table")
    a = ap.parse_args(argv)

    path = store_path()
    rows = load(path, a.label)

    if a.format == "jsonl":
        for r in rows:
            print(json.dumps(r, ensure_ascii=False))
        return 0

    if not rows:
        print("(no bookmarks in %s)" % path)
        return 0
    print("  %-24s %-16s %-4s %-16s %s" % ("ID", "LABEL", "TURN", "WHEN", "NOTE / TRANSCRIPT"))
    for r in rows:
        when = (r.get("ts", "") or "")[:16].replace("T", " ")
        note = r.get("note") or os.path.basename(r.get("transcript", ""))
        if len(note) > 44:
            note = note[:43] + "…"
        print("  %-24s %-16s %-4s %-16s %s" % (
            r.get("id", "?"), (r.get("label", "") or "")[:16],
            r.get("turn_index", ""), when, note))
    return 0


if __name__ == "__main__":
    sys.exit(main())
