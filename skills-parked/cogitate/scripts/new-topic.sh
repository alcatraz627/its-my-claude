#!/usr/bin/env bash
# new-topic.sh — creates a dated topic file from a template
# Usage: bash new-topic.sh "<title>" "<category>" "<template-path>" "<topics-dir>"
#
# Outputs the path to the created file on stdout.
# Exits 1 if file already exists or required args are missing.

set -euo pipefail

TITLE="${1:-}"
CATEGORY="${2:-General}"
TEMPLATE="${3:-}"
TOPICS_DIR="${4:-$HOME/Documents/Claude/Topics}"

if [[ -z "$TITLE" || -z "$TEMPLATE" ]]; then
  echo "Usage: new-topic.sh <title> <category> <template-path> [topics-dir]" >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Template not found: $TEMPLATE" >&2
  exit 1
fi

mkdir -p "$TOPICS_DIR"

DATE_STAMP=$(date "+%d %b %y")         # e.g. 18 Mar 26
DATE_ISO=$(date "+%Y-%m-%d %H:%M")

# Sanitise title for filename (keep alphanumeric, spaces, hyphens)
SAFE_TITLE=$(echo "$TITLE" | tr -s ' ' | sed 's/[^a-zA-Z0-9 _-]//g' | sed 's/  */ /g')
FILENAME="${DATE_STAMP} - ${SAFE_TITLE}.md"
FILEPATH="$TOPICS_DIR/$FILENAME"

if [[ -f "$FILEPATH" ]]; then
  echo "File already exists: $FILEPATH" >&2
  # Return the path anyway — caller can decide to append instead of create
  echo "$FILEPATH"
  exit 0
fi

# Substitute placeholders in template
sed \
  -e "s|<!-- DATE -->|$DATE_ISO|g" \
  -e "s|<!-- TITLE -->|$TITLE|g" \
  -e "s|<!-- DD MMM YY -->|$DATE_STAMP|g" \
  -e "s|<!-- e.g. Current Events \/ Tech Research \/ How-To \/ Analysis -->|$CATEGORY|g" \
  "$TEMPLATE" > "$FILEPATH"

echo "$FILEPATH"
