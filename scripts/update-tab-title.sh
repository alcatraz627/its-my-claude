#!/usr/bin/env bash
# update-tab-title.sh — Stop-hook entry point. Composes the Ghostty tab title
# as: ✻ <decorators> <base> [:<focus>]
#
# Composition / decorator / focus details:    ~/.claude/scripts/tab-title/lib.sh
# Add or edit icon decorators (ssh, docker…): ~/.claude/scripts/tab-title/decorators.sh
# Set/clear the [:focus] suffix from Claude:  ~/.claude/scripts/tab-title/set-focus.sh

set -uo pipefail

EVERY_N=5
LIB="${HOME}/.claude/scripts/tab-title/lib.sh"
# shellcheck disable=SC1090
source "$LIB"

command -v jq &>/dev/null || exit 0

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // "default"')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')
perm_mode=$(echo "$input" | jq -r '.permission_mode // empty')
[[ -n "$perm_mode" ]] && printf '%s' "$perm_mode" > "/tmp/claude-tab-perm-${session_id}"
TAB_SESSION_ID="$session_id"
TAB_CWD="$cwd"

counter_file="/tmp/claude-tab-counter-${session_id}"
topic_file="/tmp/claude-tab-topic-${session_id}"

count=$(cat "$counter_file" 2>/dev/null || echo 0)
count=$((count + 1))
echo "$count" > "$counter_file"

# ── Extract base title (LLM topic > recent msg > cwd+branch fallback) ────────
extract_user_text() {
  local file="$1" n="${2:-5}"
  rg --no-ignore --hidden '"type":"user"' "$file" 2>/dev/null \
    | rg -v '"tool_result"' \
    | jq -r '
        .message.content |
        (if type == "array" then map(select(.type == "text") | .text) | join(" ")
         elif type == "string" then .
         else empty end) |
        select(length > 0 and length < 500) |
        select(startswith("<") | not)
      ' 2>/dev/null \
    | tail -"$n" || true
}

# ── Load prior state to preserve FOCUS + previous BASE across turns ─────────
tab_load_state "$session_id" || true
prior_focus="${FOCUS:-}"
prior_base="${BASE:-}"

# Base resolution:
#   1. Cached LLM topic (overall focus, refreshed turn 1 + every Nth turn)
#   2. Existing BASE in state (don't churn between LLM refreshes)
#   3. Dir + git branch fallback
# Deliberately NOT falling back to "last user message" — that turned the
# title into a recency diary instead of an overall-focus indicator.
cached_topic=$(cat "$topic_file" 2>/dev/null || true)
new_base=""
if [[ -n "$cached_topic" ]]; then
  new_base="$cached_topic"
elif [[ -n "$prior_base" ]]; then
  new_base="$prior_base"
fi
if [[ -z "$new_base" ]]; then
  dir=$(basename "${cwd:-$(pwd)}")
  branch=$(cd "${cwd:-.}" 2>/dev/null && git -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null || true)
  new_base="Claude: $dir"
  [[ -n "$branch" ]] && new_base="$new_base ($branch)"
fi

# Session name (from `claude --name X` at launch). When set, PREFIX the base so
# the explicit name dominates while CWD context remains visible.
#   ~/.claude/sessions/<pid>.json carries `name` field per Claude Code.
# IDEMPOTENCY: prior turn's state may already have the prefix; strip it first,
# then re-prepend. Prevents "name · name · name · base" runaway.
session_name=""
for sf in "$HOME/.claude/sessions"/*.json; do
  [[ -f "$sf" ]] || continue
  sid_in_file=$(jq -r '.sessionId // empty' "$sf" 2>/dev/null)
  if [[ "$sid_in_file" == "$session_id" ]]; then
    session_name=$(jq -r '.name // empty' "$sf" 2>/dev/null)
    break
  fi
done
if [[ -n "$session_name" && "$session_name" != "null" ]]; then
  # Strip any prior "$session_name · " prefixes (handles N-deep accumulation)
  while [[ "$new_base" == "$session_name · "* ]]; do
    new_base="${new_base#${session_name} · }"
  done
  new_base="$session_name · $new_base"
fi

# End-of-turn implies no tools in flight — auto-heal any drift in the
# transient runtime state (missed PostToolUse hooks accumulate over time).
TRANSIENT_FOCUS=""
TRANSIENT_DEPTH=0

# ── Normalise + recompose ────────────────────────────────────────────────────
tab_normalise_base "$new_base"
BASE="$TAB_NORMALISED_BASE"
# If LLM embedded a [:focus] in the base, treat it as a focus update only when
# we don't already have one (don't clobber an explicit one set by Claude).
[[ -n "${TAB_EMBEDDED_FOCUS:-}" && -z "$prior_focus" ]] && prior_focus="$TAB_EMBEDDED_FOCUS"

STAR="$TAB_STAR"
FOCUS="$prior_focus"
tab_run_decorators
tab_save_state "$session_id"
tab_emit "$(tab_compose)"

# LLM topic refresh DISABLED. mini-core.sh --local opens a bubbletea TUI that
# tries to grab /dev/tty mid-hook and sets the title to "title" as a placeholder
# before erroring out. Until that's fixed at the mini-core level, the base
# stays stable across turns (set manually via `tab-title.sh set base="..."`
# if a specific topic is wanted; otherwise dir+branch fallback applies).
