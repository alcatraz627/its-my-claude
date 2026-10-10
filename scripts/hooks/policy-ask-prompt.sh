#!/usr/bin/env bash
# policy-ask-prompt.sh — the owner answers an "ask" policy by typing one line.
#
# guard-policy.sh blocks a call whose policy is "ask" and records a token for
# this session and key in ~/.claude/.policy-ask/. The owner then types, as an
# ordinary message from any client:  approve <key> <token>  (or: deny <key>).
# This UserPromptSubmit hook sees that message and writes the single-use
# approval the guard consumes on the retried call. Only a human types a prompt,
# so the agent cannot approve itself. Same shape as push-approve-prompt.sh.
#
# Runs as UserPromptSubmit. Silent when nothing is waiting on this session.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0
prompt=$(printf '%s' "$input" | jq -r '.prompt // .user_prompt // .message // .input // empty | if type == "string" then . else tostring end' 2>/dev/null)
sid_raw=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
sid=$(printf '%s' "$sid_raw" | tr -c 'A-Za-z0-9._-' '_'); [ -n "$sid" ] || sid="nosession"
ask_dir="$HOME/.claude/.policy-ask"

shopt -s nullglob
pending=("$ask_dir/${sid}--"*.nonce)
[ ${#pending[@]} -gt 0 ] || exit 0

# Machine-generated "user" turns are not the owner typing.
case "$prompt" in "<system-reminder>"*|"<command-name>"*|"<local-command"*|"Caveat:"*|"Base directory for this skill:"*|"Stop hook feedback:"*|"<task-notification>"*|"Another Claude session sent"*) exit 0;; esac

lower=$(printf '%s' "$prompt" | tr 'A-Z' 'a-z')
notes=()
for f in "${pending[@]}"; do
  base="${f%.nonce}"
  key=$(jq -r '.key // empty' "$f" 2>/dev/null)
  nonce=$(jq -r '.nonce // empty' "$f" 2>/dev/null)
  what=$(jq -r '.what // empty' "$f" 2>/dev/null)
  [ -n "$key" ] && [ -n "$nonce" ] || { rm -f "$f"; continue; }
  case "$lower" in
    *"approve ${key} ${nonce}"*)
      : > "$base.approved"
      bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook policy-ask --action prompt-approved --heeded yes --detail "$key" >/dev/null 2>&1 || true
      notes+=("[policy-ask] the owner approved $what (approve $key $nonce). Run the same call again now; the approval covers that one call.")
      continue ;;
    *"deny ${key}"*)
      rm -f "$f" "$base.approved"
      bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook policy-ask --action prompt-denied --heeded yes --detail "$key" >/dev/null 2>&1 || true
      notes+=("[policy-ask] the owner denied $what. Do not retry it; carry on with the rest of the work.")
      continue ;;
    *"approve ${key}"*)
      notes+=("[policy-ask] the owner's approval for $key does not carry the pending token ($nonce). Nothing was approved. Show the line again, bare:  approve $key $nonce")
      continue ;;
  esac
  if [ -f "$base.approved" ]; then
    notes+=("[policy-ask] $what is approved and not yet run. Run it now, before other work.")
  else
    notes+=("[policy-ask] $what is still waiting on the owner. Print this line to him, bare on its own line, then keep working; never call AskUserQuestion for it:  approve $key $nonce   (he can also type: deny $key)")
  fi
done

[ ${#notes[@]} -gt 0 ] || exit 0
msg=$(printf '%s\n' "${notes[@]}")
jq -cn --arg m "$msg" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$m}}'
exit 0
