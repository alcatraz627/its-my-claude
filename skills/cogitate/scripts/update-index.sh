#!/usr/bin/env bash
# update-index.sh — upserts a file entry in _index.claude.md
# Usage: bash update-index.sh "<filepath>" "<one-liner>" "<topics-dir>"
#
# If the file is already listed: increments interaction count + updates one-liner.
# If not listed: appends a new row to the Files table.

set -euo pipefail

FILEPATH="${1:-}"
ONE_LINER="${2:-}"
TOPICS_DIR="${3:-$HOME/Documents/Claude/Topics}"
INDEX="$TOPICS_DIR/_index.claude.md"

if [[ -z "$FILEPATH" || -z "$ONE_LINER" ]]; then
  echo "Usage: update-index.sh <filepath> <one-liner> [topics-dir]" >&2
  exit 1
fi

FILENAME=$(basename "$FILEPATH")
DATE_STAMP=$(date "+%d %b %y")

# Bootstrap index if absent
if [[ ! -f "$INDEX" ]]; then
cat > "$INDEX" << 'EOF'
# Topics Index
> Auto-maintained by /cogitate. Do not edit the Files table manually.

## Template Registry
| Template file | Use-case | Created |
|---|---|---|
| topic-template.md | Default — general research / Q&A / analysis | — |

## Files
| File | Created | Interactions | Summary |
|---|---|---|---|
EOF
fi

# Check if entry exists
if grep -qF "| $FILENAME |" "$INDEX"; then
  # Increment interaction count (column 3) and update one-liner (column 4)
  # Uses awk to find the matching row and patch it
  awk -v fname="$FILENAME" -v summary="$ONE_LINER" '
    BEGIN { FS="|"; OFS="|" }
    $2 ~ fname {
      # col indices after split: 1=empty, 2=file, 3=created, 4=count, 5=summary, 6=empty
      gsub(/^ +| +$/, "", $4)
      count = $4 + 0
      $4 = " " (count + 1) " "
      $5 = " " summary " "
    }
    { print }
  ' "$INDEX" > "$INDEX.tmp" && mv "$INDEX.tmp" "$INDEX"
else
  # Append new row before the last empty line / EOF
  echo "| $FILENAME | $DATE_STAMP | 1 | $ONE_LINER |" >> "$INDEX"
fi

echo "Index updated: $INDEX"
