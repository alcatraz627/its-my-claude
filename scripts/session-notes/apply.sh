#!/usr/bin/env bash
# scripts/session-notes/apply.sh — Apply a proposed diff to the workspace doc.
#
# Same JSON proposal as diff.sh, but actually writes the changes:
#   - todos_done   → flip "- [ ] X" lines to "- [x] X"
#   - todos_new    → append unchecked items at end of ## Todos section
#   - notes_append → append paragraphs to ## Notes
#   - doclinks_new → append bullets to ## Doc Links
#   - decisions_new → append bullets to ## Decisions (with timestamp)
#
# Always preserves the file otherwise — sections it doesn't touch stay intact.

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
[[ -n "$INPUT" ]] || exit 2

python3 - "$DOC" "$INPUT" <<'PY'
import json, sys, re
from datetime import datetime

doc_path, proposal_json = sys.argv[1], sys.argv[2]
p = json.loads(proposal_json)

with open(doc_path) as f:
    body = f.read()

now = datetime.now().strftime("%Y-%m-%d")

def update_section(text, section, transformer):
    """Run transformer on section body lines. Terminator: next H2, '---' separator,
    or end of file. Stopping at '---' prevents the last section from absorbing the
    document footer."""
    pat = re.compile(rf"(^## {re.escape(section)}\s*$\n)(.*?)(?=^## |^---\s*$|\Z)", re.DOTALL | re.MULTILINE)
    def repl(m):
        header, content = m.group(1), m.group(2)
        new_content = transformer(content)
        return header + new_content
    return pat.sub(repl, text, count=1)

# 1. Mark todos done — replace "- [ ] X" with "- [x] X" if X matches case-insensitively
done_set = set(t.lower().strip() for t in p.get("todos_done", []))
def mark_todos_done(content):
    lines = content.splitlines()
    out = []
    for ln in lines:
        m = re.match(r"^(\s*)- \[ \] (.*)$", ln)
        if m and m.group(2).lower().strip() in done_set:
            out.append(f"{m.group(1)}- [x] {m.group(2)}")
        else:
            out.append(ln)
    return "\n".join(out) + ("\n" if not content.endswith("\n") else "")

# 2. Add new todos at end of todos section (before trailing blank lines)
new_todos = p.get("todos_new", [])
def add_new_todos(content):
    if not new_todos: return content
    # Strip the "- [ ] _no todos yet_" placeholder if present (handles the bracket prefix)
    content = re.sub(r"^\s*-\s+\[\s*\]\s+_no todos yet.*?_\s*$\n?", "", content, flags=re.MULTILINE)
    addition = "\n".join(f"- [ ] {t}" for t in new_todos)
    return content.rstrip() + "\n" + addition + "\n\n"

# 3. Append notes
notes_app = p.get("notes_append", [])
def append_notes(content):
    if not notes_app: return content
    content = re.sub(r"^\s*_observations.*?…_\s*$\n?", "", content, flags=re.MULTILINE)
    block = "\n".join(notes_app)
    return content.rstrip() + f"\n\n_[{now}]_\n{block}\n\n"

# 4. Append doc links
dl_new = p.get("doclinks_new", [])
def append_links(content):
    if not dl_new: return content
    content = re.sub(r"^\s*_external URLs.*?…_\s*$\n?", "", content, flags=re.MULTILINE)
    block = "\n".join(f"- {l}" for l in dl_new)
    return content.rstrip() + "\n" + block + "\n\n"

# 5. Append decisions
dec_new = p.get("decisions_new", [])
def append_decisions(content):
    if not dec_new: return content
    content = re.sub(r"^\s*_load-bearing.*?…_\s*$\n?", "", content, flags=re.MULTILINE)
    block = "\n".join(f"- **[{now}]** {d}" for d in dec_new)
    return content.rstrip() + "\n" + block + "\n\n"

body = update_section(body, "Todos",     mark_todos_done)
body = update_section(body, "Todos",     add_new_todos)
body = update_section(body, "Notes",     append_notes)
body = update_section(body, "Doc Links", append_links)
body = update_section(body, "Decisions", append_decisions)

with open(doc_path, "w") as f:
    f.write(body)

total = (len(p.get("todos_done", [])) + len(new_todos) + len(notes_app)
       + len(dl_new) + len(dec_new))
print(f"applied {total} change(s) to {doc_path}")
PY
