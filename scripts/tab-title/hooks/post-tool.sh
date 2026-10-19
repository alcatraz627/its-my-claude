#!/usr/bin/env bash
# tab-title/hooks/post-tool.sh — PostToolUse hook (async).
# Decrements the in-flight tool counter and clears TRANSIENT_FOCUS when no
# tool is running. Manual focus (set via set-focus.sh) is then visible again.
#
# Also derives two slots without any agent action:
#   status  a test/build Bash command that exits non-zero sets error, a later
#           passing one sets ok (other failures are scored at Stop)
#   focus   after TaskCreate/TaskUpdate, the in_progress task's subject cut to
#           three words; cleared when no task is in progress
# A value the agent set by hand is left alone: derivation only replaces a value
# it wrote itself (remembered in /tmp/claude-tab-auto-<slot>-<sid>).

set -uo pipefail
command -v jq &>/dev/null || exit 0
source "${HOME}/.claude/scripts/tab-title/lib.sh"

input=$(cat)
sid=$(echo "$input" | jq -r '.session_id // empty')
[[ -n "$sid" ]] || exit 0
tool=$(echo "$input" | jq -r '.tool_name // empty')

tab_load_state "$sid" || exit 0
TRANSIENT_DEPTH=$(( ${TRANSIENT_DEPTH:-0} - 1 ))
(( TRANSIENT_DEPTH < 0 )) && TRANSIENT_DEPTH=0
if (( TRANSIENT_DEPTH == 0 )); then
  TRANSIENT_FOCUS=""
fi

# Auto-written slots: replace only what we wrote last (or an empty slot).
auto_file() { printf '%s/claude-tab-auto-%s-%s' "$TAB_STATE_DIR" "$1" "$sid"; }
auto_prev() { cat "$(auto_file "$1")" 2>/dev/null || true; }
set_auto() { # set_auto <slot var name> <file key> <value>
  local var="$1" key="$2" val="$3" cur prev
  cur="${!var:-}"; prev=$(auto_prev "$key")
  if [[ -z "$cur" || "$cur" == "$prev" ]]; then
    printf -v "$var" '%s' "$val"
    printf '%s' "$val" > "$(auto_file "$key")"
  fi
}

case "$tool" in
  Bash)
    cmd=$(echo "$input" | jq -r '.tool_input.command // empty')
    # The exit code lives in tool_response when the harness sends it; a failed
    # call may instead carry an "Exit code N" error string.
    code=$(echo "$input" | jq -r '(.tool_response | if type == "object" then (.exit_code // .exitCode // .returncode // empty) else empty end) // empty' 2>/dev/null)
    if [[ -z "$code" ]]; then
      errtxt=$(echo "$input" | jq -r '(.error // (.tool_response | if type == "string" then . else empty end)) // empty' 2>/dev/null)
      [[ "$errtxt" =~ ^Exit\ code\ ([0-9]+) ]] && code="${BASH_REMATCH[1]}"
    fi
    if [[ -n "$code" ]] && tab_is_testbuild_cmd "$cmd"; then
      if [[ "$code" == "0" ]]; then set_auto STATUS status ok; else set_auto STATUS status error; fi
    fi
    ;;
  TaskCreate|TaskUpdate)
    set_auto FOCUS focus "$(tab_focus_from_tasks "$sid")"
    ;;
esac

tab_save_state "$sid"
# No tab_emit — same reason as pre-tool.sh: PreTool/PostTool /dev/tty
# doesn't reach the visible terminal under Claude Code's hook arrangement.
