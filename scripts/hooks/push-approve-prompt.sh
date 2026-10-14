#!/usr/bin/env bash
# push-approve-prompt.sh — the owner approves a gated push by typing one line.
#
# guard-git-push.sh blocks a push to main and records a nonce for the session.
# The owner then types, as an ordinary message from any client (terminal, web,
# mobile):  approve push <nonce>  . This UserPromptSubmit hook sees that message
# on the Mac where the session runs and writes the single-use sentinel the gate
# consumes. Nothing waits: the agent keeps working. Owner, 2026-09-08: "Let the
# agent nag me over and over, but don't let it be halted on this either." The
# nag is the agent's, in conversation; this hook does not repeat it (2026-10-14).
#
# Why the agent cannot actuate this channel: only a human types a prompt, so a
# message carrying the nonce is the owner's act. The nonce never expires here; a
# pending push stays pending until it is approved, or the owner types
# `cancel push`, or the push goes through and the gate clears both files.
#
# Runs as UserPromptSubmit. Silent when no push is pending for this session.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0
# Claude Code sends the typed text as .prompt; the other names cover Codex,
# whose UserPromptSubmit payload runs this same hook through its adapter.
prompt=$(printf '%s' "$input" | jq -r '.prompt // .user_prompt // .message // .input // empty | if type == "string" then . else tostring end' 2>/dev/null)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
sid_safe=$(printf '%s' "$sid" | tr -c 'A-Za-z0-9._-' '_')
[ -n "$sid_safe" ] || sid_safe="nosession"
NONCE_FILE="$HOME/.claude/.push-nonce-${sid_safe}"
SENTINEL="$HOME/.claude/.push-approved-${sid_safe}"

[ -f "$NONCE_FILE" ] || exit 0   # no push is waiting on this session

# Machine-generated "user" turns are not the owner typing.
case "$prompt" in "<system-reminder>"*|"<command-name>"*|"<local-command"*|"Caveat:"*|"Base directory for this skill:"*|"Stop hook feedback:"*|"<task-notification>"*|"Another Claude session sent"*) exit 0;; esac

nonce=$(jq -r '.nonce // empty' "$NONCE_FILE" 2>/dev/null)
target=$(jq -r '.target // empty' "$NONCE_FILE" 2>/dev/null)
[ -n "$nonce" ] || { rm -f "$NONCE_FILE"; exit 0; }

say() { jq -cn --arg m "$1" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$m}}'; }
lower=$(printf '%s' "$prompt" | tr 'A-Z' 'a-z')

case "$lower" in
  *"cancel push"*)
    rm -f "$NONCE_FILE" "$SENTINEL"
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook push-gate --action prompt-cancelled --heeded yes >/dev/null 2>&1 || true
    say "[push-gate] the owner cancelled the pending push of $target; the nonce and any sentinel are gone. Do not push."
    exit 0 ;;
  *"approve push ${nonce}"*)
    : > "$SENTINEL" 2>/dev/null || exit 0
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook push-gate --action prompt-approved --heeded yes >/dev/null 2>&1 || true
    say "[push-gate] the owner typed \"approve push $nonce\"; the single-use sentinel is written for $target. Re-run the same push now; it is consumed by that one push."
    exit 0 ;;
  *"approve push"*)
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook push-gate --action prompt-refused --heeded unknown --detail "wrong nonce" >/dev/null 2>&1 || true
    say "[push-gate] the owner typed an approval whose nonce is not the pending one ($nonce). No sentinel written. Show him the line again, bare:  approve push $nonce"
    exit 0 ;;
esac

if [ -f "$SENTINEL" ]; then
  say "[push-gate] a push of $target is approved (sentinel present) and not yet run. Run the same git push now, before other work."
fi
# No mechanical nag while the push waits. Holding the owner to it is the agent's
# job, in its own words when it talks to him (owner, 2026-10-14); a hook re-nag
# fired on every cron wake and kept the agent bouncing.
exit 0
