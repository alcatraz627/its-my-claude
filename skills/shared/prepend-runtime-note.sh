#!/usr/bin/env bash
# prepend-runtime-note.sh <skill-name> <entry-file>
#
# Prepends a pre-formatted markdown entry to .claude/skills/runtime-notes.md.
# Handles the full acquire → prepend → release lock cycle so callers don't have to.
#
# Arguments:
#   <skill-name>   Name of the skill writing the note (used for lock ownership)
#   <entry-file>   Path to a file containing the full formatted markdown entry.
#                  The entry must start with a "## Skill: description · YYYY-MM-DD HH:MM"
#                  heading. Do NOT include a trailing "---" — the script adds it.
#
# Usage:
#   cat > /tmp/note.md << 'ENTRY'
#   ## my-skill: what this run did · 2026-02-20 14:30
#   **Purpose:** One sentence.
#
#   **Insights:**
#   1. First insight.
#   2. Second insight.
#   ENTRY
#
#   bash .claude/skills/shared/prepend-runtime-note.sh "my-skill" /tmp/note.md
#
# Exit codes:
#   0  — success
#   1  — lock acquisition failed or file error
#   2  — bad usage (missing arguments)

set -euo pipefail

FORCE_GLOBAL=0
PROJECT_DIR=""
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --global)  FORCE_GLOBAL=1; shift ;;
    --project) PROJECT_DIR="${2:-}"; shift 2 ;;
    *)         ARGS+=("$1"); shift ;;
  esac
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

SKILL_NAME="${1:-}"
ENTRY_FILE="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# The global notes file, and the fallback when no project has opted in. It stays
# a canonical absolute path (no "..") so its lock key matches the one
# inject-dream-insights.sh takes on the same file.
GLOBAL_NOTES="$(cd "$SCRIPT_DIR/.." && pwd)/runtime-notes.md"

# Which runtime-notes file this note belongs in.
#
# The old answer was always the global one, because the path was derived from
# where THIS SCRIPT lives rather than from where the caller is. A project with
# its own .claude/skills/runtime-notes.md never received a note, and the next
# session there read a file nothing had written. Every versable-builder session
# since 2026-08-17 moved its note across by hand instead.
#
# Detection tests for the FILE, never the directory. A project holding a
# .claude/ but no notes file has not opted in, and creating one silently would
# split a skill's history across two files with nothing announcing the split.
resolve_notes_file() {
  if [[ "$FORCE_GLOBAL" == "1" ]]; then echo "$GLOBAL_NOTES"; return; fi
  if [[ -n "$PROJECT_DIR" ]]; then
    echo "$(cd "$PROJECT_DIR" 2>/dev/null && pwd)/.claude/skills/runtime-notes.md"; return
  fi
  local d="$PWD"
  while [[ -n "$d" && "$d" != "/" ]]; do
    if [[ -f "$d/.claude/skills/runtime-notes.md" ]]; then
      echo "$d/.claude/skills/runtime-notes.md"; return
    fi
    [[ "$d" == "$HOME" ]] && break        # never walk above the user's home
    d="$(dirname "$d")"
  done
  echo "$GLOBAL_NOTES"
}

# The lock key is the resolved path, so it stays a deterministic function of the
# file being protected. That is the constraint the original comment asked for;
# what it could not have, while the target was fixed, is two different files
# under two different locks.
NOTES_FILE="$(resolve_notes_file)"

if [[ -z "$SKILL_NAME" || -z "$ENTRY_FILE" ]]; then
  echo "Usage: prepend-runtime-note.sh <skill-name> <entry-file>" >&2
  exit 2
fi

if [[ ! -f "$ENTRY_FILE" ]]; then
  echo "Error: entry file not found: $ENTRY_FILE" >&2
  exit 1
fi

# Acquire write lock — exits 1 with instructions if lock cannot be obtained
bash "$SCRIPT_DIR/lock-file.sh" acquire "$NOTES_FILE" "$SKILL_NAME"

# Create runtime-notes.md with a standard header if it does not exist yet
if [[ ! -f "$NOTES_FILE" ]]; then
  cat > "$NOTES_FILE" << 'HEADER'
# Skill Runtime Notes

Append-only log of post-run insights from every skill execution.
Newest entries appear at the top. Each entry is prepended by the agent after the skill completes.

---
HEADER
fi

# Find the line number of the first "---" separator (marks end of file header)
HEADER_LINE=$(grep -n "^---$" "$NOTES_FILE" | head -1 | cut -d: -f1)

# Build the new file: header block → blank → new entry → separator → rest of entries
TMP_FILE="${NOTES_FILE}.prepend.tmp"
{
  head -n "$HEADER_LINE" "$NOTES_FILE"   # file header (lines 1..first ---)
  echo ""
  cat "$ENTRY_FILE"                      # the new entry
  echo ""
  echo "---"
  echo ""
  # Everything after the header separator, with leading blank lines stripped
  tail -n +"$((HEADER_LINE + 1))" "$NOTES_FILE" | sed '/./,$!d'
} > "$TMP_FILE"

mv "$TMP_FILE" "$NOTES_FILE"

# Release write lock
bash "$SCRIPT_DIR/lock-file.sh" release "$NOTES_FILE" "$SKILL_NAME"

echo "PREPENDED: runtime note for [$SKILL_NAME] written to $NOTES_FILE"
