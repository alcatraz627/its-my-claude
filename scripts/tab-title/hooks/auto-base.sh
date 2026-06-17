#!/usr/bin/env bash
# tab-title/hooks/auto-base.sh — UserPromptSubmit hook (async).
# Gives a session a tab-title base automatically: the first real prompt is
# summarized into a 2-5 word title by the local `q title` companion
# (~/Code/local-models), fire-and-forget, so the prompt is never delayed.
#
# Deliberately skips when: a base is already set (manual always wins), the
# warm model is not resident (no-idle rule — never cold-load a model for a
# nicety; `warm on` makes this feature live), q is missing, or the prompt is
# too short to be worth titling.
set -uo pipefail
command -v jq &>/dev/null || exit 0
Q="${HOME}/.local/bin/q"
[[ -x "$Q" ]] || exit 0
LM_DIR="${HOME}/Code/local-models"
[[ -f "$LM_DIR/config.sh" && -f "$LM_DIR/bin/_lib.sh" ]] || exit 0
source "${HOME}/.claude/scripts/tab-title/lib.sh"
# Pure assignments + helper functions — gives us WARM_MODEL and ollama_resident
# so the gate tracks config changes instead of a hardcoded model name.
# shellcheck source=/dev/null
source "$LM_DIR/config.sh"
# shellcheck source=/dev/null
source "$LM_DIR/bin/_lib.sh"

input=$(cat)
sid=$(echo "$input" | jq -r '.session_id // empty')
prompt=$(echo "$input" | jq -r '.prompt // empty')
[[ -n "$sid" ]] || exit 0
(( ${#prompt} >= 20 )) || exit 0

tab_load_state "$sid" || true
[[ -z "${BASE:-}" ]] || exit 0

# Warm-gated: only generate when the companion model is already resident.
ollama_resident "${WARM_MODEL:-gemma4-e4b-warm}" || exit 0

(
  title=$(printf '%s' "${prompt:0:2000}" | "$Q" title 2>/dev/null </dev/stdin) || exit 0
  title=$(printf '%s' "$title" | head -1 | tr -d '"'"'" | cut -c1-40)
  [[ -n "$title" ]] || exit 0
  # Re-load right before saving to shrink the load-modify-save clobber window
  # (lib state has no lock; pre/post-tool hooks rewrite it mid-turn).
  tab_load_state "$sid" || true
  [[ -z "${BASE:-}" ]] || exit 0
  BASE="$title"
  tab_save_state "$sid"
) &>/dev/null &
disown
exit 0
