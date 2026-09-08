#!/usr/bin/env bash
# push-approve-prompt.sh — the owner approves a gated push by typing one line.
#
# guard-git-push.sh blocks a push to main and records a nonce for the session.
# The owner then types, as an ordinary message from any client (terminal, web,
# mobile):  approve push <nonce>  . This UserPromptSubmit hook sees that message
# on the Mac where the session runs and writes the single-use sentinel the gate
# consumes. Nothing waits: the agent keeps working, and this hook nags on every
# later message while the push is still pending. Owner, 2026-09-08: "Let the
# agent nag me over and over, but don't let it be halted on this either."
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
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)
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
  exit 0
fi
say "[push-gate] a push of $target is still waiting on the owner. Print this line to him, bare on its own line, then keep working on other things; never call AskUserQuestion for it (that halts the turn, owner 2026-09-08):  approve push $nonce   (he can also type: cancel push)"
exit 0
