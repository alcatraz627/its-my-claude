#!/usr/bin/env bash
# scripts/session-notes/diff.sh — Compute a proposed diff between current workspace
# state and synthesized updates from /core-dump, without applying.
#
# Inputs come from /core-dump's synthesized Pending Items + Decisions + Notes,
# passed via JSON on stdin:
#   { "todos_done":    ["text", …],
#     "todos_new":     ["text", …],
#     "notes_append":  ["text", …],
#     "doclinks_new":  ["url-or-ref", …],
#     "decisions_new": ["text", …] }
#
# Output: human-readable diff preview to stdout. Returns 0 if there are changes,
# 2 if no changes proposed.
#
# Apply step is separate: see scripts/session-notes/apply.sh

set -uo pipefail

PROJECT="" SESSION_ID=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)    PROJECT="$2"; shift ;;
    --session-id) SESSION_ID="$2"; shift ;;
  esac
  shift
done

[[ -n "$PROJECT" && -n "$SESSION_ID" ]] || {
  printf 'usage: %s --project PATH --session-id ID (stdin = JSON proposal)\n' "$0" >&2
  exit 2
}

# Edge case: PROJECT == ~/.claude → write under PROJECT/ directly, not nested.
if [[ "$PROJECT" == "$HOME/.claude" ]] || [[ "$PROJECT" == */.claude ]]; then
  DOC="$PROJECT/session-notes/$SESSION_ID.md"
else
  DOC="$PROJECT/.claude/session-notes/$SESSION_ID.md"
fi
[[ -f "$DOC" ]] || { printf 'workspace doc not found: %s\n' "$DOC" >&2; exit 3; }

INPUT=$(cat)
[[ -n "$INPUT" ]] || { printf 'no proposal on stdin\n' >&2; exit 2; }

python3 - "$DOC" "$INPUT" <<'PY'
import json, sys, re

doc_path, proposal_json = sys.argv[1], sys.argv[2]
proposal = json.loads(proposal_json)

with open(doc_path) as f:
    body = f.read()

def section_lines(section_name):
    pat = re.compile(rf"^## {re.escape(section_name)}\s*$(.*?)(?=^## |\Z)", re.DOTALL | re.MULTILINE)
    m = pat.search(body)
    return m.group(1).splitlines() if m else []

todos_section = "\n".join(section_lines("Todos"))
existing_todos_text = todos_section

td_done = proposal.get("todos_done", [])
td_new  = proposal.get("todos_new", [])
nt_app  = proposal.get("notes_append", [])
dl_new  = proposal.get("doclinks_new", [])
dc_new  = proposal.get("decisions_new", [])

print("Proposed updates to .claude/session-notes/<sid>.md:\n")

def emit_section(title, items, marker):
    if not items: return
    print(f"  {title}")
    for it in items:
        text = (it[:80] + "…") if len(it) > 80 else it
        print(f"    [{marker}] {text}")
    print()

emit_section("Todos", [f"Mark complete: {t}" for t in td_done], "-")
emit_section("Todos", [f"Add: {t}" for t in td_new], "+")
emit_section("Notes", [f"Append: {t}" for t in nt_app], "+")
emit_section("Doc Links", [f"Add: {t}" for t in dl_new], "+")
emit_section("Decisions", [f"Append: {t}" for t in dc_new], "+")

total = len(td_done) + len(td_new) + len(nt_app) + len(dl_new) + len(dc_new)
if total == 0:
    print("  (no changes proposed)")
    sys.exit(2)
print(f"  --- {total} total change(s)")
PY
