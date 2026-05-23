#!/usr/bin/env bash
# md-table.sh — emit WELL-FORMED markdown from row data.
#
# The fix for mangled tables (unescaped `|` in cells, paragraph-sized cells):
# feed structured rows in, get valid markdown out. Auto-escapes `|`. And — the
# real fix — when cells are code-heavy or oversized, it emits per-row SECTIONS
# instead of a doomed-wide table (a 5-col table with a 600-char code cell is a
# misuse of the table primitive; escaping pipes just makes it render, badly).
#
# Usage:
#   printf 'h1\th2\nval1\tval2\n' | md-table.sh           # TSV on stdin (1st row = header)
#   md-table.sh --json '[{"a":1,"b":2}]'                  # JSON array of objects
#   md-table.sh --max-cell 80 ...                         # cell-width threshold (default 120)
#   md-table.sh --sections ...                            # force sections mode
#
# Auto picks sections when any cell exceeds --max-cell OR contains a code span
# with a pipe. Output is valid CommonMark; pipe a clean table OR a section list.

set -uo pipefail

MODE="tsv" JSON="" MAX_CELL=120 FORCE_SECTIONS=0
while [ $# -gt 0 ]; do
  case "$1" in
    --json)     MODE="json"; JSON="$2"; shift 2 ;;
    --max-cell) MAX_CELL="$2"; shift 2 ;;
    --sections) FORCE_SECTIONS=1; shift ;;
    *) shift ;;
  esac
done

INPUT=""
[ "$MODE" = "tsv" ] && INPUT=$(cat)

MODE="$MODE" JSON="$JSON" MAX_CELL="$MAX_CELL" FORCE_SECTIONS="$FORCE_SECTIONS" \
INPUT="$INPUT" python3 <<'PY'
import os, sys, json, re

mode = os.environ["MODE"]
max_cell = int(os.environ["MAX_CELL"])
force_sections = os.environ["FORCE_SECTIONS"] == "1"

# Build (header, rows) from TSV or JSON.
if mode == "json":
    try:
        data = json.loads(os.environ["JSON"])
    except Exception as e:
        print(f"<!-- md-table: bad JSON: {e} -->"); sys.exit(0)
    if not isinstance(data, list) or not data:
        print("<!-- md-table: JSON must be a non-empty array of objects -->"); sys.exit(0)
    header = list(data[0].keys())
    rows = [[str(d.get(k, "")) for k in header] for d in data]
else:
    lines = [l for l in os.environ["INPUT"].split("\n") if l.strip() != ""]
    if not lines:
        sys.exit(0)
    header = lines[0].split("\t")
    rows = [l.split("\t") for l in lines[1:]]

def clean(s):
    return s.replace("\r", "").strip()

def cell_inline(s):
    # safe for a table cell: escape pipes, collapse newlines
    return clean(s).replace("\n", " ").replace("|", "\\|")

# Decide table vs sections.
def has_codepipe(s):
    return any("|" in m for m in re.findall(r"`[^`]*`", s))

oversized = force_sections or any(
    len(clean(c)) > max_cell or "\n" in c or has_codepipe(c)
    for r in rows for c in r
)

if not oversized:
    # clean pipe table
    print("| " + " | ".join(cell_inline(h) for h in header) + " |")
    print("|" + "|".join("---" for _ in header) + "|")
    for r in rows:
        r = (r + [""] * len(header))[:len(header)]
        print("| " + " | ".join(cell_inline(c) for c in r) + " |")
else:
    # per-row sections: first column is the heading, rest are labelled lines.
    # code-heavy / long values render as fenced blocks, not table cells.
    for r in rows:
        r = (r + [""] * len(header))[:len(header)]
        title = clean(r[0]) or "(row)"
        print(f"### {title}\n")
        for k, v in zip(header[1:], r[1:]):
            v = clean(v)
            if not v:
                continue
            if "\n" in v or len(v) > max_cell or has_codepipe(v):
                print(f"**{clean(k)}:**\n")
                print("```")
                print(v)
                print("```\n")
            else:
                print(f"- **{clean(k)}:** {v}")
        print()
PY
