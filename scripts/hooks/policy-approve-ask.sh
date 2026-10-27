#!/usr/bin/env bash
# policy-approve-ask.sh: the owner approves a policy change by answering a question.
#
# An agent cannot change the owner's policy, by design. It can ask: `pol.sh request
# <key> <value>` records the change under a one-use code and prints the option to
# offer, "Approve policy <code>: …". This hook runs after the AskUserQuestion answer
# lands and, when the owner picked that option, applies the change itself through
# pol.sh with the agent markers removed, so the owner can grant a change without
# opening the menu bar panel.
#
# Same trust model as push-approve-ask.sh: only tool_response.answers decide, never
# the agent-written option labels; two options carrying the code refuse; a code
# older than 30 minutes refuses. The agent never gets a write path of its own.
#
# PostToolUse on AskUserQuestion. Silent on every question that answers no pending
# policy request. Test: policy-approve-ask.test.sh
set -uo pipefail
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0
[ "$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)" = "AskUserQuestion" ] || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
REQ="${POL_REQUEST_DIR:-$HOME/.claude}/.policy-request-$(printf '%s' "${sid:-nosession}" | tr -c 'A-Za-z0-9._-' '_')"
TTL=1800
POL="${POL_SH:-$HOME/.claude/scripts/pol/pol.sh}"
[ -f "$REQ" ] || exit 0

say() { jq -cn --arg m "[policy] $1" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'; }

nonce=$(jq -r '.nonce // empty' "$REQ" 2>/dev/null)
ts=$(jq -r '.ts // 0' "$REQ" 2>/dev/null)
if [ -z "$nonce" ] || [ $(( $(date +%s) - ${ts:-0} )) -gt "$TTL" ]; then
  rm -f "$REQ"; exit 0
fi
token=$(printf 'approve policy %s' "$nonce")

# How many options the agent labelled with the code: one is the documented shape.
n_opt=$(printf '%s' "$input" | jq --arg t "$token" \
  '[.tool_input.questions[]?.options[]?.label // empty | ascii_downcase | select(startswith($t))] | length' 2>/dev/null)
chosen=$(printf '%s' "$input" | jq --arg t "$token" '
  .tool_response | (if type == "string" then (fromjson? // {}) else . end) | (.answers // {})
  | [ .[] | strings | gsub("^\\s+"; "") | ascii_downcase | select(startswith($t)) ] | length' 2>/dev/null)

if [ "${n_opt:-0}" -gt 1 ]; then
  say "$n_opt options carried the code; a policy question offers it on exactly one. Nothing changed; ask again."
  exit 0
fi
[ "${n_opt:-0}" -eq 1 ] || exit 0   # this question was about something else
if [ "${chosen:-0}" -lt 1 ]; then
  rm -f "$REQ"
  say "the owner did not approve the policy change; nothing changed. Do not ask again for the same change this session."
  exit 0
fi

key=$(jq -r '.key' "$REQ"); val=$(jq -r '.value' "$REQ"); scope=$(jq -r '.scope' "$REQ")
if [ "$scope" = "global" ]; then flag=(--global); else flag=(--project "$scope"); fi
if out=$(env -u CLAUDECODE -u AI_AGENT -u CODEX_SANDBOX -u CODEX_THREAD_ID -u GCC_DISPATCH \
         bash "$POL" set "$key" "$val" "${flag[@]}" 2>&1); then
  rm -f "$REQ"
  say "the owner approved: $out. Every session sees it on its next check."
else
  say "the owner approved, but applying it failed: $out. Tell the owner; nothing changed."
fi
exit 0
