#!/usr/bin/env bash
# push-approve-ask.sh — the owner approves a gated push by answering a question.
#
# guard-git-push.sh blocks a push to main (or in a protected repo) and prints a
# nonce. The agent then asks through AskUserQuestion with one option labelled
# exactly "Approve push <nonce>". This hook runs after the answer lands and
# writes the single-use sentinel the gate consumes, so the owner never has to
# leave the conversation to type a shell command (he cannot, from Claude Code
# web; before this he pushed from a real shell hours later, 2026-09-08).
#
# Why the agent cannot actuate this channel: it writes the question, but the
# harness writes the answer from a real human pick, and this hook reads ONLY
# tool_response.answers. The option labels echoed back in tool_response.questions
# are agent-authored and are never consulted for the match. Two options carrying
# the nonce (a stacked deck) refuse. A nonce older than the gate's TTL refuses.
# The sentinel path stays as the fallback for any shell.
#
# Runs as PostToolUse on AskUserQuestion. Silent on every question that is not
# an answer to a pending push nonce; on a decline it tells the agent so.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
[ "$tool" = "AskUserQuestion" ] || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
sid_safe=$(printf '%s' "$sid" | tr -c 'A-Za-z0-9._-' '_')
[ -n "$sid_safe" ] || sid_safe="nosession"
NONCE_FILE="$HOME/.claude/.push-nonce-${sid_safe}"
SENTINEL="$HOME/.claude/.push-approved-${sid_safe}"
NONCE_TTL=1800

[ -f "$NONCE_FILE" ] || exit 0   # no push is waiting on this session

nonce=$(jq -r '.nonce // empty' "$NONCE_FILE" 2>/dev/null)
n_ts=$(jq -r '.ts // 0' "$NONCE_FILE" 2>/dev/null); n_ts=${n_ts:-0}
if [ -z "$nonce" ] || [ $(( $(date +%s) - n_ts )) -gt "$NONCE_TTL" ]; then
  rm -f "$NONCE_FILE"   # expired: the next gated push mints a fresh one
  exit 0
fi
token="Approve push ${nonce}"

# How many options the agent labelled with the token. Zero is fine (the owner
# may type it under Other); one is the documented shape; more is a stacked deck.
n_opt=$(printf '%s' "$input" | jq --arg t "$token" \
  '[.tool_input.questions[]?.options[]?.label // empty | select(. == $t)] | length' 2>/dev/null)
n_opt=${n_opt:-0}

# The answers alone decide. tool_response may arrive as an object or a JSON string.
chosen=$(printf '%s' "$input" | jq --arg t "$token" '
  .tool_response
  | (if type == "string" then (fromjson? // {}) else . end)
  | (.answers // {})
  | [ .[] | strings | gsub("^\\s+|\\s+$"; "") | select(. == $t) ]
  | length' 2>/dev/null)
chosen=${chosen:-0}

if [ "$n_opt" -gt 1 ]; then
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook push-gate --action ask-refused --heeded unknown --detail "nonce on $n_opt options" >/dev/null 2>&1 || true
  jq -cn --arg m "[push-gate] $n_opt options carried \"$token\"; an approval question offers it on exactly one. No sentinel written. Ask again with one option carrying the nonce, or the owner runs: ! touch $SENTINEL" \
    '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'
  exit 0
fi

if [ "$chosen" -ge 1 ]; then
  : > "$SENTINEL" 2>/dev/null || exit 0
  rm -f "$NONCE_FILE"
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook push-gate --action ask-approved --heeded yes >/dev/null 2>&1 || true
  jq -cn --arg m "[push-gate] the owner picked \"$token\"; the single-use sentinel is written. Re-run the same push now; it is consumed by that one push." \
    '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'
  exit 0
fi

if [ "$n_opt" -eq 1 ]; then
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook push-gate --action ask-declined --heeded unknown >/dev/null 2>&1 || true
  jq -cn --arg m "[push-gate] the owner did not pick \"$token\"; no sentinel written, do not push. The nonce stays valid for a fresh ask until it expires." \
    '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'
fi
exit 0
