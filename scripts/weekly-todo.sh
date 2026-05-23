#!/usr/bin/env bash
# weekly-todo.sh — CLI for managing ~/.claude/weekly-todos.md
#
# Usage:
#   weekly-todo list [week]              List items (default: current week)
#   weekly-todo add <week> <cat> <text>  Add item to a week
#   weekly-todo done <text-match>        Mark matching item as done
#   weekly-todo rm <text-match>          Remove matching item entirely
#   weekly-todo weeks                    List all week headers
#   weekly-todo ensure <date>            Ensure a week section exists for date
#   weekly-todo archive                  Move completed items to archive
#
# <week> format: YYYY-MM-DD (Monday of that week) or "next", "this", "+2", "+3"...
# <cat> values: build, review, explore (maps to ### To Build, ### To Review, ### Ideas to Explore)
#
set -euo pipefail

TODO_FILE="$HOME/.claude/weekly-todos.md"

if [[ ! -f "$TODO_FILE" ]]; then
  echo "ERROR: $TODO_FILE not found" >&2
  exit 1
fi

# ── Helpers ──

# shellcheck source=/dev/null
source ~/.claude/skills/shared/gum-tui.sh

# Get Monday of the week containing a date
get_monday() {
  local d="${1:-$(date +%Y-%m-%d)}"
  # macOS date: get day of week (1=Mon..7=Sun), subtract to get Monday
  local dow
  dow=$(date -j -f "%Y-%m-%d" "$d" "+%u" 2>/dev/null)
  local offset=$(( dow - 1 ))
  date -j -v-"${offset}d" -f "%Y-%m-%d" "$d" "+%Y-%m-%d"
}

# Resolve week shorthand to YYYY-MM-DD Monday
resolve_week() {
  local w="$1"
  local today
  today=$(date +%Y-%m-%d)
  local this_monday
  this_monday=$(get_monday "$today")

  case "$w" in
    this)
      echo "$this_monday"
      ;;
    next)
      date -j -v+7d -f "%Y-%m-%d" "$this_monday" "+%Y-%m-%d"
      ;;
    +[0-9]|+[0-9][0-9])
      local n="${w#+}"
      local days=$(( n * 7 ))
      date -j -v+"${days}d" -f "%Y-%m-%d" "$this_monday" "+%Y-%m-%d"
      ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      get_monday "$w"
      ;;
    *)
      echo "ERROR: Invalid week '$w'. Use: this, next, +N, or YYYY-MM-DD" >&2
      exit 1
      ;;
  esac
}

# Map category shorthand to section header
resolve_cat() {
  local lc
  lc=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  case "$lc" in
    build|b)   echo "### To Build" ;;
    review|r)  echo "### To Review" ;;
    explore|e|ideas) echo "### Ideas to Explore" ;;
    *)
      echo "ERROR: Invalid category '$1'. Use: build, review, explore" >&2
      exit 1
      ;;
  esac
}

# ── Commands ──

cmd_weeks() {
  grep -n "^## Week of " "$TODO_FILE" | sed 's/:.*//' | while read -r line_num; do
    sed -n "${line_num}p" "$TODO_FILE"
  done
}

cmd_list() {
  local target_week
  if [[ -n "${1:-}" ]]; then
    target_week=$(resolve_week "$1")
  else
    target_week=$(resolve_week "this")
  fi

  local header="## Week of $target_week"
  local in_section=false
  local found=false

  while IFS= read -r line; do
    if [[ "$line" == "$header" ]]; then
      in_section=true
      found=true
      echo "$line"
      continue
    fi
    if $in_section; then
      # Stop at next week header or archive
      if [[ "$line" =~ ^##\  ]] && [[ "$line" != "$header" ]]; then
        break
      fi
      echo "$line"
    fi
  done < "$TODO_FILE"

  if ! $found; then
    echo "No entries for week of $target_week"
  fi
}

cmd_ensure() {
  local target_week
  target_week=$(resolve_week "$1")
  local header="## Week of $target_week"

  if grep -qF "$header" "$TODO_FILE"; then
    echo "Week $target_week already exists"
    return 0
  fi

  # Find the right insertion point (keep weeks sorted)
  # Insert before the first week that comes AFTER this one, or before Archive
  local insert_before=""
  local line_num=0

  while IFS= read -r line; do
    line_num=$((line_num + 1))
    if [[ "$line" =~ ^##\ Week\ of\ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
      local existing_week="${BASH_REMATCH[1]}"
      if [[ "$existing_week" > "$target_week" ]]; then
        insert_before=$line_num
        break
      fi
    elif [[ "$line" == "## Archive" ]]; then
      insert_before=$line_num
      break
    fi
  done < "$TODO_FILE"

  local block
  block=$(cat <<EOF

## Week of $target_week

### To Build

### To Review

### Ideas to Explore

---
EOF
)

  if [[ -n "$insert_before" ]]; then
    # Insert before the found line
    local tmp
    tmp=$(mktemp)
    head -n $((insert_before - 1)) "$TODO_FILE" > "$tmp"
    echo "$block" >> "$tmp"
    echo "" >> "$tmp"
    tail -n +$insert_before "$TODO_FILE" >> "$tmp"
    mv -f "$tmp" "$TODO_FILE"
  else
    # Append before archive (shouldn't happen if Archive exists, but safety)
    echo "$block" >> "$TODO_FILE"
  fi

  gum_success "Created week: $target_week"
}

cmd_add() {
  local week_input="$1"
  local cat_input="$2"
  shift 2
  local text="$*"

  local target_week
  target_week=$(resolve_week "$week_input")
  local cat_header
  cat_header=$(resolve_cat "$cat_input")
  local week_header="## Week of $target_week"

  # Ensure week exists
  if ! grep -qF "$week_header" "$TODO_FILE"; then
    cmd_ensure "$target_week" >/dev/null
  fi

  # Find the category line within that week and append after it
  local in_week=false
  local found_cat=false
  local insert_line=0
  local line_num=0

  while IFS= read -r line; do
    line_num=$((line_num + 1))
    if [[ "$line" == "$week_header" ]]; then
      in_week=true
      continue
    fi
    if $in_week; then
      if [[ "$line" =~ ^##\  ]] && [[ "$line" != "###"* ]]; then
        # Hit next week section — stop
        break
      fi
      if [[ "$line" == "$cat_header" ]]; then
        found_cat=true
        insert_line=$line_num
        continue
      fi
      if $found_cat; then
        # Keep advancing past existing items in this category
        if [[ "$line" == "- ["* ]] || [[ -z "$line" ]]; then
          insert_line=$line_num
        else
          break
        fi
      fi
    fi
  done < "$TODO_FILE"

  if ! $found_cat; then
    echo "ERROR: Category '$cat_header' not found in week $target_week" >&2
    exit 1
  fi

  # Insert the new item after insert_line
  local tmp
  tmp=$(mktemp)
  head -n "$insert_line" "$TODO_FILE" > "$tmp"
  echo "- [ ] $text" >> "$tmp"
  tail -n +$((insert_line + 1)) "$TODO_FILE" >> "$tmp"
  mv -f "$tmp" "$TODO_FILE"

  gum_success "Added to $target_week ($cat_input): $text"
}

cmd_done() {
  local pattern="$*"
  if grep -q "\- \[ \].*$pattern" "$TODO_FILE"; then
    # Use sed to check the first matching unchecked item
    sed -i '' "0,/- \[ \].*${pattern}/s/- \[ \]/- [x]/" "$TODO_FILE"
    gum_success "Marked done: $pattern"
  else
    echo "No unchecked item matching '$pattern'" >&2
    exit 1
  fi
}

cmd_rm() {
  local pattern="$*"
  if grep -q "\- \[.\].*$pattern" "$TODO_FILE"; then
    # Remove the first matching line
    local tmp
    tmp=$(mktemp)
    local removed=false
    while IFS= read -r line; do
      if ! $removed && [[ "$line" =~ \-\ \[.\].*$pattern ]]; then
        removed=true
        continue
      fi
      echo "$line"
    done < "$TODO_FILE" > "$tmp"
    mv -f "$tmp" "$TODO_FILE"
    gum_success "Removed: $pattern"
  else
    echo "No item matching '$pattern'" >&2
    exit 1
  fi
}

cmd_archive() {
  local moved=0
  local tmp
  tmp=$(mktemp)
  local archive_items=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^-\ \[x\]\ (.+)$ ]]; then
      archive_items+="- [x] ${BASH_REMATCH[1]} _(archived $(date +%Y-%m-%d))_"$'\n'
      moved=$((moved + 1))
    else
      echo "$line"
    fi
  done < "$TODO_FILE" > "$tmp"

  if [[ $moved -eq 0 ]]; then
    rm -f "$tmp"
    gum_info "No completed items to archive"
    return 0
  fi

  # Append archived items before the last line of the archive section
  # (just append to end of file since Archive is last)
  echo "$archive_items" >> "$tmp"
  mv -f "$tmp" "$TODO_FILE"
  gum_success "Archived $moved items"
}

# ── Dispatch ──

case "${1:-help}" in
  list)    shift; cmd_list "${1:-}" ;;
  add)     shift; cmd_add "$@" ;;
  done)    shift; cmd_done "$@" ;;
  rm)      shift; cmd_rm "$@" ;;
  weeks)   cmd_weeks ;;
  ensure)  shift; cmd_ensure "$1" ;;
  archive) cmd_archive ;;
  help|-h|--help)
    echo "Usage: weekly-todo <command> [args]"
    echo ""
    echo "Commands:"
    echo "  list [week]              List items (default: current week)"
    echo "  add <week> <cat> <text>  Add item (week: this/next/+N/YYYY-MM-DD)"
    echo "  done <text-match>        Mark matching item as [x]"
    echo "  rm <text-match>          Remove matching item"
    echo "  weeks                    List all week headers"
    echo "  ensure <date>            Create week section if missing"
    echo "  archive                  Move [x] items to archive"
    echo ""
    echo "Categories: build (b), review (r), explore (e)"
    echo "Week shortcuts: this, next, +2, +3, ... or YYYY-MM-DD"
    ;;
  *)
    echo "Unknown command: $1 (try: weekly-todo help)" >&2
    exit 1
    ;;
esac
