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

# The base is the session's identity. A session you named with `claude --name X`
# shows that name; an un-named one shows "Am❓ <folder>" — the ❓ is a visible
# "this session has no name" flag, and the folder is the only identity hint we
# have for it. The old "Claude: <folder> (<branch>)" form is dropped: "Claude:"
# is constant noise, and the folder/branch already live in the statusline.
#
# The name lives in ~/.claude/sessions/<pid>.json, keyed by sessionId.
session_name=""
for sf in "$HOME/.claude/sessions"/*.json; do
  [[ -f "$sf" ]] || continue
  if [[ "$(jq -r '.sessionId // empty' "$sf" 2>/dev/null)" == "$session_id" ]]; then
    session_name=$(jq -r '.name // empty' "$sf" 2>/dev/null)
    break
  fi
done
[[ "$session_name" == "null" ]] && session_name=""

# Branch only when it carries signal: on main/master the branch is redundant
# with the statusline, so it just wastes the tab's ~20 chars.
dir=$(basename "${cwd:-$(pwd)}")
branch=$(cd "${cwd:-.}" 2>/dev/null && git -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null || true)
branch_suffix=""
[[ -n "$branch" && "$branch" != "main" && "$branch" != "master" ]] && branch_suffix=" ($branch)"

# The auto base is recomputed from name + branch each turn, so a rename or a
# branch switch shows up. A base somebody else stored (tab-title.sh set base=...,
# or auto-base.sh's local title) is not ours to overwrite: we remember the last
# value we wrote in a sidecar, and a stored base that differs from it is kept.
# "Am❓ " bases predate the sidecar and are always ours.
if [[ -n "$session_name" ]]; then
  auto_base="${session_name}${branch_suffix}"
else
  auto_base="Am❓ ${dir}${branch_suffix}"
fi
base_auto_file="${TAB_STATE_DIR}/claude-tab-auto-base-${session_id}"
last_auto=$(cat "$base_auto_file" 2>/dev/null || true)
if [[ -n "$prior_base" && "$prior_base" != "$last_auto" && "$prior_base" != "Am❓ "* ]]; then
  new_base="$prior_base"
else
  new_base="$auto_base"
  printf '%s' "$auto_base" > "$base_auto_file"
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

# Status for the turn that just ended, derived from its tool results. It only
# replaces a status we derived ourselves (or an empty one), never one the agent set.
status_auto_file="${TAB_STATE_DIR}/claude-tab-auto-status-${session_id}"
if [[ -n "$transcript" && -f "$transcript" ]]; then
  derived_status=$(python3 -I "${HOME}/.claude/scripts/tab-title/derive-status.py" "$transcript" 2>/dev/null || true)
  prev_auto_status=$(cat "$status_auto_file" 2>/dev/null || true)
  if [[ -z "${STATUS:-}" || "${STATUS:-}" == "$prev_auto_status" ]]; then
    STATUS="$derived_status"
    printf '%s' "$derived_status" > "$status_auto_file"
  fi
fi
tab_run_decorators
tab_save_state "$session_id"
tab_emit "$(tab_compose)"

# LLM topic refresh DISABLED. mini-core.sh --local opens a bubbletea TUI that
# tries to grab /dev/tty mid-hook and sets the title to "title" as a placeholder
# before erroring out. Until that's fixed at the mini-core level, the base
# stays stable across turns (set manually via `tab-title.sh set base="..."`
# if a specific topic is wanted; otherwise dir+branch fallback applies).
