#!/usr/bin/env bash
# gum-tui.sh — Non-TTY gum wrapper library for Claude Code skills
#
# Source this file in any skill script to get styled TUI output that works
# inside Claude Code's sandboxed Bash tool (no TTY required).
#
# Usage:
#   source ~/.claude/skills/shared/gum-tui.sh
#   gum_header "My Skill"
#   gum_table "Name,Status,Count" "api,running,42" "db,stopped,0"
#   gum_success "All done!"
#
# Run directly for help:
#   bash ~/.claude/skills/shared/gum-tui.sh          # show help
#   bash ~/.claude/skills/shared/gum-tui.sh demo     # run demo
#   bash ~/.claude/skills/shared/gum-tui.sh list     # list all functions
#
# Requires: gum (brew install gum)
# All functions here use ONLY gum components that work without a TTY:
#   gum style, gum format, gum log, gum join, gum table --print

# NOTE: No `set -euo pipefail` here — this file is meant to be sourced,
# and those options would bleed into the caller's shell, causing silent
# failures in interactive sessions.

# ─── Guard ───────────────────────────────────────────────────────────

if ! command -v gum &>/dev/null; then
  echo "gum-tui: gum is required. Install with: brew install gum" >&2
  return 1 2>/dev/null || exit 1
fi

# ─── CLI Entrypoint (when run directly, not sourced) ─────────────────

_gum_tui_help() {
  gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 55 --margin "1 0" --padding "0 2" \
    "gum-tui.sh — TUI Library for Claude Code"

  gum style --foreground 14 --bold "Usage:"
  echo
  echo "  source ~/.claude/skills/shared/gum-tui.sh    # load as library"
  echo "  bash   ~/.claude/skills/shared/gum-tui.sh    # show this help"
  echo
  gum style --foreground 14 --bold "Commands:"
  echo
  echo "  help       Show this help message (default)"
  echo "  list       List all available functions"
  echo "  demo       Run a visual demo of all components"
  echo
  gum style --foreground 14 --bold "Function Categories:"
  echo
  gum style --foreground 8 "  Headers     gum_header  gum_subheader  gum_divider"
  gum style --foreground 8 "  Status      gum_success  gum_error  gum_warn  gum_info  gum_muted"
  gum style --foreground 8 "  Logging     gum_log  gum_log_kv"
  gum style --foreground 8 "  Tables      gum_table  gum_table_file"
  gum style --foreground 8 "  Layouts     gum_columns  gum_panel  gum_stack  gum_dashboard"
  gum style --foreground 8 "  Rendering   gum_markdown  gum_code  gum_emoji"
  gum style --foreground 8 "  Progress    gum_progress  gum_kv  gum_complete"
  echo
  gum style --foreground 8 "  22 functions total · all TTY-safe · zsh compatible"
}

_gum_tui_list() {
  gum style --foreground 14 --bold "gum-tui.sh — All Functions"
  echo
  gum table --print --separator "," < <(printf '%s\n' \
    "Function,Args,Description" \
    "gum_header,TITLE [COLOR],Full-width styled header with double border" \
    "gum_subheader,TITLE [COLOR],Rounded-border subheader" \
    "gum_divider,[LABEL],Thin divider line with optional label" \
    "gum_success,MESSAGE,Green checkmark status line" \
    "gum_error,MESSAGE,Red X status line" \
    "gum_warn,MESSAGE,Yellow warning status line" \
    "gum_info,MESSAGE,Blue info status line" \
    "gum_muted,MESSAGE,Gray dimmed text" \
    "gum_log,LEVEL MESSAGE,Timestamped log line (info/warn/error/debug)" \
    "gum_log_kv,LEVEL MSG K=V...,Timestamped log with key=value pairs" \
    "gum_table,HEADER ROW...,Table from comma-separated rows (--sep to change)" \
    "gum_table_file,FILE [FLAGS],Table from a TSV/CSV file" \
    "gum_columns,LEFT RIGHT [W],Side-by-side bordered panels" \
    "gum_panel,TITLE LINE...,Bordered box with title and content lines" \
    "gum_stack,BLOCK...,Vertical stack of styled blocks" \
    "gum_dashboard,SPEC...,Multi-panel dashboard (TITLE|line|line format)" \
    "gum_markdown,TEXT,Render markdown to styled terminal output" \
    "gum_code,TEXT,Render as a code block" \
    "gum_emoji,TEXT,Render emoji shortcodes (:rocket: etc.)" \
    "gum_progress,CUR TOTAL VERB ITEM,Progress counter [3/10] Verb: item" \
    "gum_kv,KEY VALUE [COLOR],Key-value line with dot alignment" \
    "gum_complete,SKILL K=V...,Skill completion summary block" \
  )
}

_gum_tui_demo() {
  gum_header "gum-tui.sh — Component Demo"

  gum_divider "Status Messages"
  gum_success "Build passed — 0 errors"
  gum_error "Connection refused on port 5432"
  gum_warn "Deprecated API detected in auth.ts"
  gum_info "Processing 42 files..."
  gum_muted "(skipping empty directory)"

  echo
  gum_divider "Structured Logging"
  gum_log info "Server started successfully"
  gum_log warn "Rate limit approaching threshold"
  gum_log_kv info "Request handled" status=200 duration=45ms

  echo
  gum_divider "Tables"
  gum_table "Service,Status,Port" \
    "api-gateway,✓ running,3010" \
    "auth-service,✓ running,3011" \
    "worker,⚠ degraded,3012"

  echo
  gum_divider "Panels & Layouts"
  gum_panel "Recommendations" \
    "1. Update Node.js to v22 LTS" \
    "2. Run npm audit fix for 3 vulnerabilities" \
    "3. Enable strict TypeScript checks"

  echo
  gum_columns "Before" "After"

  echo
  gum_divider "Dashboard"
  gum_dashboard \
    "Health|✓ All passing|✓ No warnings" \
    "Metrics|Files: 14|Skills: 12" \
    "Deploy|Env: prod|Region: us-east-1"

  echo
  gum_divider "Progress & KV"
  gum_progress 7 10 "Analyzing" "auth-middleware.ts"
  gum_kv "Duration" "2.3s" "$GUM_GREEN"
  gum_kv "Files modified" "14" "$GUM_CYAN"

  echo
  gum_complete "demo" "Functions shown=22" "Errors=0" "Status=all working"
}

# Detect if script is being run directly (not sourced)
# BASH_SOURCE[0] != $0 means sourced in bash; in zsh we check ZSH_EVAL_CONTEXT
_gum_tui_is_sourced() {
  if [[ -n "${ZSH_EVAL_CONTEXT:-}" ]]; then
    # zsh: contains "file" when sourced, "toplevel" when run directly
    [[ "$ZSH_EVAL_CONTEXT" == *":file:"* || "$ZSH_EVAL_CONTEXT" == "file" ]]
  elif [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    [[ "${BASH_SOURCE[0]}" != "$0" ]]
  else
    return 1  # can't determine — assume not sourced
  fi
}

# ─── Color Constants ─────────────────────────────────────────────────

GUM_RED=1
GUM_GREEN=2
GUM_YELLOW=3
GUM_BLUE=4
GUM_GRAY=8
GUM_PINK=212
GUM_CYAN=14
GUM_ORANGE=208
GUM_WHITE=15

# ─── Headers & Banners ──────────────────────────────────────────────

# Full-width styled header with double border
# Usage: gum_header "Title Text"
gum_header() {
  local title="${1:?Usage: gum_header TITLE}"
  local color="${2:-$GUM_PINK}"
  gum style \
    --foreground "$color" --border-foreground "$color" --border double \
    --align center --width 55 --margin "1 0" --padding "0 2" \
    "$title"
}

# Subheader — single border, subdued color
# Usage: gum_subheader "Section Name"
gum_subheader() {
  local title="${1:?Usage: gum_subheader TITLE}"
  local color="${2:-$GUM_BLUE}"
  gum style \
    --foreground "$color" --border-foreground "$color" --border rounded \
    --align center --width 50 --padding "0 1" \
    "$title"
}

# Section divider — thin line with label
# Usage: gum_divider "Phase 2"
gum_divider() {
  local label="${1:-}"
  if [[ -n "$label" ]]; then
    gum style --foreground "$GUM_GRAY" "─── $label ───────────────────────────────────────"
  else
    gum style --foreground "$GUM_GRAY" "─────────────────────────────────────────────────"
  fi
}

# ─── Status Messages ────────────────────────────────────────────────

# Success message (green checkmark)
# Usage: gum_success "All tests passed"
gum_success() {
  gum style --foreground "$GUM_GREEN" --bold "✓ $*"
}

# Error message (red X)
# Usage: gum_error "Build failed"
gum_error() {
  gum style --foreground "$GUM_RED" --bold "✗ $*"
}

# Warning message (yellow triangle)
# Usage: gum_warn "Deprecated API detected"
gum_warn() {
  gum style --foreground "$GUM_YELLOW" --bold "⚠ $*"
}

# Info message (blue dot)
# Usage: gum_info "Processing 42 files..."
gum_info() {
  gum style --foreground "$GUM_BLUE" "● $*"
}

# Muted/dim text
# Usage: gum_muted "skipping empty directory"
gum_muted() {
  gum style --foreground "$GUM_GRAY" "  $*"
}

# ─── Structured Logging ─────────────────────────────────────────────

# Leveled log line with timestamp
# Usage: gum_log info "Server started on port 3010"
#        gum_log error "Connection refused"
#        gum_log warn "Rate limit approaching"
#        gum_log debug "Cache miss for key: user.42"
gum_log() {
  local level="${1:?Usage: gum_log LEVEL MESSAGE}"
  shift
  gum log --time datetime --level "$level" "$*"
}

# Structured log with key=value pairs
# Usage: gum_log_kv info "Request processed" status=200 duration=45ms path=/api/users
gum_log_kv() {
  local level="${1:?Usage: gum_log_kv LEVEL MESSAGE KEY=VALUE...}"
  shift
  local msg="${1:?}"
  shift
  # Build key=value suffix manually (gum --structured has quirky quoting)
  local kvs=""
  for kv in "$@"; do
    kvs="$kvs $kv"
  done
  gum log --time datetime --level "$level" "$msg$kvs"
}

# ─── Tables ──────────────────────────────────────────────────────────

# Static table from comma-separated rows (first row = header)
# Usage: gum_table "Name,Status,Port" "api,running,3010" "db,stopped,5432"
#        gum_table --sep $'\t' "Name\tPort" "api\t3010"
gum_table() {
  local sep=","

  # Check for --sep flag (must be first arg if present)
  if [[ "${1:-}" == "--sep" ]]; then
    sep="$2"
    shift 2
  fi

  if [[ $# -eq 0 ]]; then
    echo "gum_table: at least one row required (first row = header)" >&2
    return 1
  fi

  # Use process substitution to avoid temp file leaking to stdout
  gum table --print --separator "$sep" < <(printf '%s\n' "$@")
}

# Table from a file (defaults to tab-separated)
# Usage: gum_table_file /path/to/data.tsv
#        gum_table_file /path/to/data.csv --separator ","
gum_table_file() {
  local file="${1:?Usage: gum_table_file FILE [GUM_FLAGS...]}"
  shift
  gum table --print --separator "$(printf '\t')" "$@" < "$file"
}

# ─── Layouts ─────────────────────────────────────────────────────────

# Side-by-side panels
# Usage: gum_columns "Left content" "Right content"
gum_columns() {
  local left="${1:?Usage: gum_columns LEFT RIGHT}"
  local right="${2:?}"
  local width="${3:-30}"
  gum join --horizontal \
    "$(gum style --border rounded --padding '0 1' --width "$width" "$left")" \
    "  " \
    "$(gum style --border rounded --padding '0 1' --width "$width" "$right")"
}

# Labeled panel — bordered box with a title line
# Usage: gum_panel "Title" "Content line 1" "Content line 2"
gum_panel() {
  local title="${1:?Usage: gum_panel TITLE CONTENT...}"
  shift
  local content
  content=$(printf '%s\n' "$@")
  gum style --border rounded --border-foreground "$GUM_BLUE" \
    --padding '0 1' --width 50 \
    "$(gum style --bold --foreground "$GUM_BLUE" "$title")" \
    "$content"
}

# Vertical stack of styled blocks
# Usage: gum_stack "Block 1" "Block 2" "Block 3"
gum_stack() {
  local -a styled=()
  for block in "$@"; do
    styled+=("$(gum style --padding '0 1' "$block")")
  done
  gum join --vertical "${styled[@]}"
}

# ─── Markdown Rendering ─────────────────────────────────────────────

# Render markdown text to styled terminal output
# Usage: gum_markdown "# Hello World"
#        echo "**bold** and _italic_" | gum_markdown
gum_markdown() {
  if [[ $# -gt 0 ]]; then
    echo "$*" | gum format --type markdown
  else
    gum format --type markdown
  fi
}

# Render a code block with syntax hints
# Usage: gum_code "const x = 42;"
gum_code() {
  echo "$*" | gum format --type code
}

# Render emoji shortcodes
# Usage: gum_emoji ":rocket: Deploy complete"
gum_emoji() {
  echo "$*" | gum format --type emoji
}

# ─── Progress & Status ───────────────────────────────────────────────

# Progress counter — "[3/10] Processing: filename"
# Usage: gum_progress 3 10 "Processing" "auth-middleware.ts"
gum_progress() {
  local current="${1:?}" total="${2:?}" verb="${3:-Processing}" item="${4:-}"
  gum style --foreground "$GUM_BLUE" "[$current/$total] $verb: $item"
}

# Key-value status line
# Usage: gum_kv "Duration" "2.3s"
#        gum_kv "Files modified" "14" green
gum_kv() {
  local key="${1:?}" value="${2:?}" color="${3:-$GUM_WHITE}"
  local styled_val
  styled_val=$(gum style --foreground "$color" "$value")
  # gum style adds a trailing newline; strip it for inline use
  printf '  %-20s %s\n' "$key:" "${styled_val%$'\n'}"
}

# ─── Completion Block ────────────────────────────────────────────────

# Standard skill completion summary
# Usage: gum_complete "skill-name" "key1=val1" "key2=val2" ...
gum_complete() {
  local skill="${1:?Usage: gum_complete SKILL_NAME KEY=VALUE...}"
  shift

  gum_divider
  gum_success "$skill complete"
  gum_divider
  echo

  while [[ $# -gt 0 ]]; do
    local key="${1%%=*}"
    local val="${1#*=}"
    gum_kv "$key" "$val"
    shift
  done

  echo
  gum_divider
}

# ─── Dashboard ───────────────────────────────────────────────────────

# Multi-panel dashboard — combines panels side by side
# Usage: gum_dashboard \
#          "Status|✓ All passing|✓ No warnings" \
#          "Metrics|Files: 14|Skills: 12|Lines: 2847"
gum_dashboard() {
  local panels=()
  local spec title content
  for spec in "$@"; do
    # Extract title (before first |) and content (after first |, with | → newline)
    title="${spec%%|*}"
    content="$(echo "${spec#*|}" | tr '|' '\n')"
    panels+=("$(gum style --border double --padding '0 2' --width 24 \
      "$(gum style --bold --foreground "$GUM_CYAN" "$title")" \
      "$content")")
  done

  if [[ ${#panels[@]} -ge 2 ]]; then
    gum join --horizontal "${panels[@]}"
  else
    echo "${panels[0]}"
  fi
}

# ─── CLI Dispatch (only when run directly) ────────────────────────────

if ! _gum_tui_is_sourced; then
  case "${1:-help}" in
    help|--help|-h)  _gum_tui_help ;;
    list|--list|-l)  _gum_tui_list ;;
    demo|--demo|-d)  _gum_tui_demo ;;
    *)
      echo "gum-tui: unknown command '$1'" >&2
      echo "Run 'bash $0 help' for usage." >&2
      exit 1
      ;;
  esac
  exit 0
fi
