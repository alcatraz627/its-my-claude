#!/usr/bin/env bash
# folders-index.sh — Regenerate the auto-generated census section of
# ~/.claude/FOLDERS.md without disturbing the hand-written policy above.
#
# The doc has a marker line that splits hand-written policy from the
# auto-generated census. Everything above the marker is preserved; the
# census below is rebuilt from a fresh scan of ~/.claude/*/.
#
# Run with no args: rewrites FOLDERS.md in place.
# Run with --stdout: prints the new doc to stdout without writing.

set -uo pipefail

DOC="${HOME}/.claude/FOLDERS.md"
MARKER='<!-- AUTO-GENERATED BELOW'

[[ -f "$DOC" ]] || { echo "FOLDERS.md not found at $DOC" >&2; exit 1; }

# Capture everything up to and including the marker line.
head=$(awk -v m="$MARKER" '{print} index($0, m){exit}' "$DOC")

# Build the census table.
census=$(cd "$HOME/.claude" && for d in */; do
  name="${d%/}"
  size=$(du -sh "$d" 2>/dev/null | cut -f1 | tr -d ' ')
  files=$(find "$d" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
  subdirs=$(find "$d" -maxdepth 1 -type d 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
  newest=$(find "$d" -type f -exec stat -f "%m" {} \; 2>/dev/null | sort -rn | head -1)
  if [[ -n "$newest" ]]; then
    newest_date=$(date -r "$newest" "+%Y-%m-%d" 2>/dev/null)
  else
    newest_date="empty"
  fi
  printf "| \`%s/\` | %s | %s | %s | %s |\n" "$name" "$size" "$files" "$subdirs" "$newest_date"
done)

stamp=$(date "+%Y-%m-%d %H:%M")

new_doc=$(cat <<EOF
$head

## Census (auto-generated $stamp)

| Folder | Size | Files | Subdirs | Last touched |
|---|---|---|---|---|
$census
EOF
)

if [[ "${1:-}" == "--stdout" ]]; then
  printf '%s\n' "$new_doc"
else
  printf '%s\n' "$new_doc" > "$DOC"
  echo "FOLDERS.md regenerated ($stamp)"
fi
