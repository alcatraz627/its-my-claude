#!/usr/bin/env bash
# PostToolUse hook: show colored diff preview after Edit/Write
# Output goes to stderr (visible to user, not injected into context)
set -uo pipefail

input=$(cat)

# Respect detail level — skip in minimal mode
DETAIL_FILE="/tmp/claude-detail-${PPID}"
detail="normal"
[[ -f "$DETAIL_FILE" ]] && detail=$(cat "$DETAIL_FILE" 2>/dev/null | tr -d '[:space:]') || true
[[ "$detail" == "minimal" ]] && exit 0

tool_name=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null) || exit 0

# Colors
dim="\033[2m"  rst="\033[0m"  red="\033[31m"  grn="\033[32m"
cyn="\033[36m" bld="\033[1m"

MAX_LINES=12

if [[ "$tool_name" == "Edit" ]]; then
  file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
  old_str=$(echo "$input" | jq -r '.tool_input.old_string // empty' 2>/dev/null)
  new_str=$(echo "$input" | jq -r '.tool_input.new_string // empty' 2>/dev/null)
  replace_all=$(echo "$input" | jq -r '.tool_input.replace_all // false' 2>/dev/null)

  [[ -z "$file_path" || -z "$old_str" ]] && exit 0

  # Shorten path for display
  short_path="${file_path/#$HOME/~}"
  if (( ${#short_path} > 50 )); then
    short_path="...${short_path: -47}"
  fi

  # Count lines
  old_lines=$(echo "$old_str" | wc -l | tr -d ' ')
  new_lines=$(echo "$new_str" | wc -l | tr -d ' ')
  total_lines=$((old_lines + new_lines))
  ra_tag=""
  [[ "$replace_all" == "true" ]] && ra_tag=" (all)"

  {
    printf "${dim}╭─ edit: ${cyn}%s${dim}%s ─${rst}\n" "$short_path" "$ra_tag"

    # Show old lines (red)
    line_count=0
    while IFS= read -r line; do
      (( line_count >= MAX_LINES / 2 )) && { printf "${dim}│ ${red}  ... +%d more removals${rst}\n" "$((old_lines - line_count))"; break; }
      printf "${dim}│ ${red}- %s${rst}\n" "$line"
      ((line_count++))
    done <<< "$old_str"

    # Show new lines (green)
    line_count=0
    while IFS= read -r line; do
      (( line_count >= MAX_LINES / 2 )) && { printf "${dim}│ ${grn}  ... +%d more additions${rst}\n" "$((new_lines - line_count))"; break; }
      printf "${dim}│ ${grn}+ %s${rst}\n" "$line"
      ((line_count++))
    done <<< "$new_str"

    printf "${dim}╰─────────────────────────────────────${rst}\n"
  } >&2

elif [[ "$tool_name" == "Write" ]]; then
  file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
  content=$(echo "$input" | jq -r '.tool_input.content // empty' 2>/dev/null)

  [[ -z "$file_path" || -z "$content" ]] && exit 0

  short_path="${file_path/#$HOME/~}"
  if (( ${#short_path} > 50 )); then
    short_path="...${short_path: -47}"
  fi

  total_lines=$(echo "$content" | wc -l | tr -d ' ')
  # Determine if new file or overwrite
  # Note: the file already exists by the time PostToolUse fires, so -f is unreliable.
  # Instead, check tool_result for "Created new file" which the Write tool emits.
  tool_result=$(echo "$input" | jq -r '.tool_result // empty' 2>/dev/null) || true
  if echo "$tool_result" | grep -qi "created\|new file" 2>/dev/null; then
    action="new file"
  else
    action="overwrite"
  fi

  {
    printf "${dim}╭─ write: ${cyn}%s${dim} (%s, %d lines) ─${rst}\n" "$short_path" "$action" "$total_lines"

    # Show first 5 lines
    line_count=0
    while IFS= read -r line; do
      (( line_count >= 5 )) && break
      printf "${dim}│ ${grn}  %s${rst}\n" "$line"
      ((line_count++))
    done <<< "$content"

    if (( total_lines > 10 )); then
      printf "${dim}│   ... %d lines ...${rst}\n" "$((total_lines - 10))"
      # Show last 5 lines
      echo "$content" | tail -5 | while IFS= read -r line; do
        printf "${dim}│ ${grn}  %s${rst}\n" "$line"
      done
    elif (( total_lines > 5 )); then
      echo "$content" | tail -$((total_lines - 5)) | while IFS= read -r line; do
        printf "${dim}│ ${grn}  %s${rst}\n" "$line"
      done
    fi

    printf "${dim}╰─────────────────────────────────────${rst}\n"
  } >&2
fi
