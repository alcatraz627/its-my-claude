#!/usr/bin/env bash
# scripts/session-notes/create.sh — Initialize a session workspace doc.
#
# Creates <project>/.claude/session-notes/<session-id>.md with the canonical
# section template, plus updates the _active.md symlink to point at it.
#
# Usage:
#   create.sh --session-id ID --project PATH [--name NAME]
#
# Idempotent: if the file already exists, just refresh the _active.md symlink.

set -uo pipefail

SESSION_ID="" PROJECT="" NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id) SESSION_ID="$2"; shift ;;
    --project)    PROJECT="$2"; shift ;;
    --name)       NAME="$2"; shift ;;
  esac
  shift
done

[[ -n "$SESSION_ID" && -n "$PROJECT" ]] || {
  printf 'usage: %s --session-id ID --project PATH [--name NAME]\n' "$0" >&2
  exit 2
}

NAME="${NAME:-$SESSION_ID}"

# Edge case: if PROJECT *is* ~/.claude (the global config tree itself),
# writing to $PROJECT/.claude/session-notes/ produces a nested-claude path
# (~/.claude/.claude/...) that the block-nested-claude hook rejects. Collapse
# to $PROJECT/session-notes/ in that case.
if [[ "$PROJECT" == "$HOME/.claude" ]] || [[ "$PROJECT" == */.claude ]]; then
  NOTES_DIR="$PROJECT/session-notes"
else
  NOTES_DIR="$PROJECT/.claude/session-notes"
fi
mkdir -p "$NOTES_DIR"
DOC="$NOTES_DIR/$SESSION_ID.md"
ACTIVE="$NOTES_DIR/_active.md"

if [[ ! -f "$DOC" ]]; then
  cat > "$DOC" <<EOF
# Session: $NAME — $(date "+%Y-%m-%d")

<!-- session: $SESSION_ID -->

> Per-session workspace doc. Sections: Todos, Notes, Doc Links, Decisions.
> Updated by /core-dump (with diff confirmation) and /catchup (read-only).
> Cross-session pattern detection reads the Todos section into ~/.claude/subconscious/.

## Todos

- [ ] _no todos yet — add as you work_

## Notes

_observations, open questions, decisions in flight…_

## Doc Links

_external URLs, file refs, ADRs the session is working against…_

## Decisions

_load-bearing choices made + reasons (additive log)…_

---

_Created by /workspace. Updated by /core-dump (proposed diffs)._
EOF
  printf 'created: %s\n' "$DOC"
else
  printf 'exists: %s\n' "$DOC"
fi

# Refresh _active.md symlink (relative target so it survives project moves).
ln -sf "$(basename "$DOC")" "$ACTIVE"
printf 'active: %s → %s\n' "$ACTIVE" "$(basename "$DOC")"
