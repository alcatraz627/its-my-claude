#!/usr/bin/env bash
# list-sessions.sh — Emit one row per past transcript for a given project dir.
#
# Usage:
#   list-sessions.sh                                  # current project (based on $PWD)
#   list-sessions.sh --project <encoded-dir>          # specific project dir
#   list-sessions.sh --all                            # every project
#   list-sessions.sh --since 2026-04-01               # filter by first-message date
#   list-sessions.sh --grep "auth bug"                # full-text match in any message
#
# Output format (TSV):
#   session_id<TAB>start_ts<TAB>end_ts<TAB>msg_count<TAB>first_prompt_preview

set -uo pipefail

ROOT="$HOME/.claude/projects"
PROJECT=""
ALL=0
SINCE=""
GREP_PATTERN=""

while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --all) ALL=1; shift ;;
    --since) SINCE="$2"; shift 2 ;;
    --grep) GREP_PATTERN="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Derive encoded project dir from $PWD if neither --project nor --all given
if [ -z "$PROJECT" ] && [ "$ALL" -eq 0 ]; then
  PROJECT=$(echo "$PWD" | sed 's|/|-|g')
fi

# Decide search scope
if [ "$ALL" -eq 1 ]; then
  SEARCH_PATHS=("$ROOT")
  DEPTH=3
else
  SEARCH_PATHS=("$ROOT/$PROJECT")
  DEPTH=2
fi

# Process each transcript with a while-read loop (portable; no mapfile)
find "${SEARCH_PATHS[@]}" -maxdepth "$DEPTH" -name "*.jsonl" 2>/dev/null | while read -r file; do
  [ -f "$file" ] || continue
  [ -s "$file" ] || continue

  session_id=$(basename "$file" .jsonl)

  if [ -n "$GREP_PATTERN" ]; then
    grep -qiF "$GREP_PATTERN" "$file" || continue
  fi

  first_prompt=$(jq -r '
    select(.type == "user")
    | .message.content
    | if type == "string" then . else (.[0].text // "") end
  ' "$file" 2>/dev/null \
    | grep -v '^<command-' \
    | grep -v '^\[Request interrupted' \
    | head -1 \
    | head -c 120 \
    | tr '\n\t' '  ')

  [ -z "$first_prompt" ] && first_prompt="(empty)"

  start_ts=$(jq -r 'select(.timestamp != null) | .timestamp' "$file" 2>/dev/null | head -1)
  end_ts=$(jq -r 'select(.timestamp != null) | .timestamp' "$file" 2>/dev/null | tail -1)
  msg_count=$(jq -r 'select(.type == "user" or .type == "assistant") | .uuid' "$file" 2>/dev/null | wc -l | tr -d ' ')

  if [ -n "$SINCE" ]; then
    start_date="${start_ts:0:10}"
    [ "$start_date" \< "$SINCE" ] && continue
  fi

  printf '%s\t%s\t%s\t%s\t%s\n' "$session_id" "$start_ts" "$end_ts" "$msg_count" "$first_prompt"
done | sort -k2,2r
