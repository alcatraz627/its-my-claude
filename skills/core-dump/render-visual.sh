#!/usr/bin/env bash
# render-visual.sh — Gum-based visual summary renderer for /core-dump
#
# Reads session data from a JSON file and renders a styled terminal
# visual using gum-tui.sh components. Replaces the previous approach
# of having the LLM manually construct fixed-width box-drawing lines.
#
# Usage:
#   bash ~/.claude/skills/core-dump/render-visual.sh /tmp/core-dump-data.json
#
# JSON schema: see bottom of this file for the expected input format.
#
# Requires: gum (brew install gum), jq
# Compatible with macOS /bin/bash (3.2) — no mapfile, no local -a

set -uo pipefail

# Ensure homebrew binaries are on PATH (needed in Claude Code sandbox)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# ─── Dependencies ────────────────────────────────────────────────────

source ~/.claude/skills/shared/gum-tui.sh

if ! command -v jq &>/dev/null; then
  echo "render-visual.sh: jq is required. Install with: brew install jq" >&2
  exit 1
fi

# ─── Input ───────────────────────────────────────────────────────────

data_file="${1:?Usage: render-visual.sh DATA_FILE.json}"

if [[ ! -f "$data_file" ]]; then
  echo "render-visual.sh: file not found: $data_file" >&2
  exit 1
fi

# ─── Extract fields ─────────────────────────────────────────────────

session_id=$(jq -r '.session_id // "unknown"' "$data_file")
timestamp=$(jq -r '.timestamp // "unknown"' "$data_file")
goal=$(jq -r '.goal // "(no goal)"' "$data_file")
status=$(jq -r '.status // "unknown"' "$data_file")
expects=$(jq -r '.expects // "N/A"' "$data_file")
checkpoint_path=$(jq -r '.checkpoint_path // "_checkpoint.claude.md"' "$data_file")

# Arrays — bash 3.2 compatible (no mapfile)
files=()
while IFS= read -r line; do
  [[ -n "$line" ]] && files+=("$line")
done < <(jq -r '.files[]? | "\(.path) .......... [\(.change)]"' "$data_file" 2>/dev/null)

pipeline=()
while IFS= read -r line; do
  [[ -n "$line" ]] && pipeline+=("$line")
done < <(jq -r '.pipeline[]?' "$data_file" 2>/dev/null)

interrupts=()
while IFS= read -r line; do
  [[ -n "$line" ]] && interrupts+=("$line")
done < <(jq -r '.interrupts[]?' "$data_file" 2>/dev/null)

stack_trace=()
while IFS= read -r line; do
  [[ -n "$line" ]] && stack_trace+=("$line")
done < <(jq -r '.stack_trace[]?' "$data_file" 2>/dev/null)

worked=()
while IFS= read -r line; do
  [[ -n "$line" ]] && worked+=("$line")
done < <(jq -r '.coprocessor.worked[]?' "$data_file" 2>/dev/null)

failed=()
while IFS= read -r line; do
  [[ -n "$line" ]] && failed+=("$line")
done < <(jq -r '.coprocessor.failed[]?' "$data_file" 2>/dev/null)

# ─── Helper: build tree lines ───────────────────────────────────────

# Formats args as a tree with ├─ and └─ prefixes
# Usage: build_tree "item1" "item2" "item3"
build_tree() {
  local count=$#
  local i=1

  if [[ $count -eq 0 ]]; then
    echo "└─ (none)"
    return
  fi

  for item in "$@"; do
    if [[ $i -eq $count ]]; then
      echo "└─ $item"
    else
      echo "├─ $item"
    fi
    i=$((i + 1))
  done
}

# ─── Helper: truncate + overflow for file lists ─────────────────────

MAX_FILES=6

build_file_tree() {
  local count=$#

  if [[ $count -eq 0 ]]; then
    echo "└─ (no files modified)"
    return
  fi

  if [[ $count -le $MAX_FILES ]]; then
    build_tree "$@"
    return
  fi

  # Show first MAX_FILES then overflow
  local overflow=$((count - MAX_FILES))
  local display=()
  local i=0
  for item in "$@"; do
    if [[ $i -lt $MAX_FILES ]]; then
      display+=("$item")
    fi
    i=$((i + 1))
  done
  display+=("... and $overflow more")

  build_tree "${display[@]}"
}

# ─── Helper: compress stack trace ────────────────────────────────────

MAX_STACK=8

build_stack_tree() {
  local count=$#

  if [[ $count -eq 0 ]]; then
    echo "└─ (no actions taken)"
    return
  fi

  if [[ $count -le $MAX_STACK ]]; then
    build_tree "$@"
    return
  fi

  # Collect into indexed array for positional access
  local all=("$@")
  local omitted=$((count - 6))
  local display=()
  display+=("${all[0]}")
  display+=("${all[1]}")
  display+=("${all[2]}")
  display+=("... ($omitted more)")
  display+=("${all[$((count - 3))]}")
  display+=("${all[$((count - 2))]}")
  display+=("${all[$((count - 1))]}")

  build_tree "${display[@]}"
}

# ─── Render ──────────────────────────────────────────────────────────

echo

# ── Title ──
gum style \
  --foreground 212 --border-foreground 212 --border double \
  --align center --width 60 --margin "0 0" --padding "0 2" \
  "⊕ CORE DUMP ⊕" \
  "$session_id  ·  $timestamp"

echo

# ── REGISTERS ──
reg_goal="$(gum style --foreground 14 --bold "Goal")      $goal"
reg_status="$(gum style --foreground 14 --bold "Status")    $status"
reg_expects="$(gum style --foreground 14 --bold "Expects")   $expects"
registers_content="$reg_goal
$reg_status
$reg_expects"

gum style --border rounded --border-foreground 4 --width 60 --padding "0 1" \
  "$(gum style --bold --foreground 212 "◆ REGISTERS")" \
  "$registers_content"

echo

# ── CACHE ──
if [[ ${#files[@]} -eq 0 ]]; then
  file_tree="└─ (no files modified)"
else
  file_tree=$(build_file_tree "${files[@]}")
fi
gum style --border rounded --border-foreground 4 --width 60 --padding "0 1" \
  "$(gum style --bold --foreground 212 "◇ CACHE")" \
  "$file_tree"

echo

# ── PIPELINE ──
pipeline_numbered=()
for ((i = 0; i < ${#pipeline[@]}; i++)); do
  pipeline_numbered+=("$((i + 1)). ${pipeline[$i]}")
done
if [[ ${#pipeline_numbered[@]} -eq 0 ]]; then
  pipeline_tree="└─ (no pending actions)"
else
  pipeline_tree=$(build_tree "${pipeline_numbered[@]}")
fi
gum style --border rounded --border-foreground 4 --width 60 --padding "0 1" \
  "$(gum style --bold --foreground 212 "▶ PIPELINE")" \
  "$pipeline_tree"

echo

# ── INTERRUPTS ──
if [[ ${#interrupts[@]} -eq 0 ]]; then
  interrupt_tree="└─ (none)"
else
  interrupt_tree=$(build_tree "${interrupts[@]}")
fi

# Color the border red if there are active interrupts
int_border_color=4
[[ ${#interrupts[@]} -gt 0 ]] && int_border_color=1

gum style --border rounded --border-foreground "$int_border_color" --width 60 --padding "0 1" \
  "$(gum style --bold --foreground 212 "△ INTERRUPTS")" \
  "$interrupt_tree"

echo

# ── STACK TRACE ──
if [[ ${#stack_trace[@]} -eq 0 ]]; then
  stack_tree="└─ (no actions taken)"
else
  stack_tree=$(build_stack_tree "${stack_trace[@]}")
fi
gum style --border rounded --border-foreground 4 --width 60 --padding "0 1" \
  "$(gum style --bold --foreground 212 "◎ STACK TRACE")" \
  "$stack_tree"

echo

# ── COPROCESSOR ──
copro_lines=""
for w in "${worked[@]+"${worked[@]}"}"; do
  [[ -n "$w" ]] && copro_lines+="$(gum style --foreground 2 "✓") $w"$'\n'
done
for f in "${failed[@]+"${failed[@]}"}"; do
  [[ -n "$f" ]] && copro_lines+="$(gum style --foreground 1 "✗") $f"$'\n'
done
# Remove trailing newline
copro_lines="${copro_lines%$'\n'}"

if [[ -z "$copro_lines" ]]; then
  copro_lines="└─ (no insights)"
fi

gum style --border rounded --border-foreground 4 --width 60 --padding "0 1" \
  "$(gum style --bold --foreground 212 "⊕ COPROCESSOR")" \
  "$copro_lines"

echo

# ── Footer ──
gum style \
  --foreground 8 --border-foreground 8 --border double \
  --width 60 --padding "0 2" \
  "⊙ $checkpoint_path" \
  "Resume: /catchup"

echo

# ─── JSON Input Schema Reference ────────────────────────────────────
# {
#   "session_id": "fix-auth-3b",
#   "timestamp": "2026-04-06T14:30+05:30",
#   "goal": "Fix authentication bug in login flow",
#   "status": "complete",
#   "expects": "User to test login manually",
#   "files": [
#     {"path": "src/auth/login.ts", "change": "+12 / -3 lines"},
#     {"path": "src/auth/middleware.ts", "change": "+5 / -2 lines"}
#   ],
#   "pipeline": ["Run full test suite", "Deploy to staging"],
#   "interrupts": [],
#   "stack_trace": ["Read auth module", "Fixed JWT logic", "Wrote test"],
#   "coprocessor": {
#     "worked": ["Pre-read all files before editing"],
#     "failed": ["First fix missed edge case"]
#   },
#   "checkpoint_path": "_20260406-fix-auth-3b.claude.md"
# }
