#!/usr/bin/env bash
# archive-runtime-notes.sh — keep a runtime-notes.md lean by moving its oldest
# entries into a quarterly archive file that lives next to it.
#
# Mechanical twin of the /archive-notes skill (same split rules, same archive
# naming), built so a scheduled job can run the archival without an LLM session.
# No-ops when the file is already under the keep threshold, so it is safe to
# run on any cadence.
#
#   usage: archive-runtime-notes.sh <notes-file> [--keep N] [--dry-run]
#     <notes-file>  absolute path to a runtime-notes.md
#     --keep N      newest entries to keep in the active file (default 50)
#     --dry-run     report the split, write nothing
#
# Contract (mirrors skills-parked/archive-notes/SKILL.md phases 2-5):
#   - an entry starts at each "## " heading; everything before the first "## "
#     is the file header and always stays
#   - entries are newest-first (prepend-runtime-note.sh order), so "keep N"
#     means the first N entries
#   - archive file: runtime-notes-archive-YYYY-QN.md in the same directory,
#     appended to if it already exists
#   - writes go through skills/shared/lock-file.sh; a held lock aborts the run
#     rather than racing a live session

set -uo pipefail

NOTES=""
KEEP=50
DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep)    KEEP="$2"; shift ;;
    --dry-run) DRY_RUN=1 ;;
    *)         NOTES="$1" ;;
  esac
  shift
done

[[ -n "$NOTES" && -f "$NOTES" ]] || { echo "archive-runtime-notes: notes file not found: '$NOTES'" >&2; exit 2; }
[[ "$KEEP" =~ ^[0-9]+$ ]] || { echo "archive-runtime-notes: --keep must be a number" >&2; exit 2; }

LOCK="$HOME/.claude/skills/shared/lock-file.sh"

if (( ! DRY_RUN )) && [[ -x "$LOCK" ]]; then
  bash "$LOCK" acquire "$NOTES" archive-runtime-notes || {
    echo "archive-runtime-notes: lock held on $NOTES, skipping this run" >&2
    exit 0
  }
fi

DRY_RUN="$DRY_RUN" KEEP="$KEEP" python3 - "$NOTES" <<'PYEOF'
import os, re, sys, datetime

notes_path = sys.argv[1]
keep = int(os.environ["KEEP"])
dry_run = os.environ["DRY_RUN"] == "1"

with open(notes_path, encoding="utf-8") as f:
    text = f.read()

# Header = everything before the first h2; each entry runs to the next h2.
parts = re.split(r"(?m)^(?=## )", text)
header, entries = parts[0], parts[1:]

if len(entries) <= keep:
    print(f"only {len(entries)} entries (keep={keep}); no archival needed")
    sys.exit(0)

kept, archived = entries[:keep], entries[keep:]

now = datetime.datetime.now()
quarter = (now.month - 1) // 3 + 1
archive_path = os.path.join(
    os.path.dirname(notes_path), f"runtime-notes-archive-{now.year}-Q{quarter}.md"
)

print(f"total {len(entries)} entries -> keeping {keep}, archiving {len(archived)} to {os.path.basename(archive_path)}")
if dry_run:
    sys.exit(0)

archived_text = "".join(archived)
if os.path.exists(archive_path):
    with open(archive_path, "a", encoding="utf-8") as f:
        f.write("\n" + archived_text)
else:
    project = os.path.basename(os.path.dirname(os.path.dirname(notes_path))) or "unknown"
    with open(archive_path, "w", encoding="utf-8") as f:
        f.write(
            f"# Runtime Notes Archive — {now.year} Q{quarter}\n\n"
            f"Archived entries from {project}. Original file: runtime-notes.md\n\n---\n\n"
            + archived_text
        )

tmp = notes_path + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    f.write(header + "".join(kept))
os.replace(tmp, notes_path)

# Verify nothing was lost before declaring success.
with open(notes_path, encoding="utf-8") as f:
    kept_count = len(re.split(r"(?m)^(?=## )", f.read())) - 1
with open(archive_path, encoding="utf-8") as f:
    archive_count = len(re.split(r"(?m)^(?=## )", f.read())) - 1
if kept_count != keep:
    print(f"VERIFY FAIL: active file has {kept_count} entries, expected {keep}", file=sys.stderr)
    sys.exit(1)
print(f"ok: active={kept_count} entries, archive now holds {archive_count} entries")
PYEOF
status=$?

if (( ! DRY_RUN )) && [[ -x "$LOCK" ]]; then
  bash "$LOCK" release "$NOTES" archive-runtime-notes >/dev/null 2>&1
fi
exit "$status"
