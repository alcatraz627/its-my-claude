#!/usr/bin/env bash
# api-recovery-nudge.sh — UserPromptSubmit hook that turns a terse "keep going"
# after an API outage into a context-aware resume.
#
# When an interactive turn dies on a transient API error, Claude Code emits no
# Stop and no Notification — but the user's NEXT prompt always fires
# UserPromptSubmit. That is the only foothold for recovery. This hook checks
# whether the last real assistant turn was a synthetic "API Error" abort; if so,
# it injects a short directive telling the resuming agent to re-orient (goal,
# what's done, the interrupted step) before continuing — per
# rules/api-error-recovery.md.
#
# Advisory only: prints {additionalContext} when it fires, nothing otherwise,
# and always exits 0 (a UserPromptSubmit hook must never block the prompt).
# Self-limiting: once the agent produces one real turn, the last assistant entry
# is no longer synthetic, so it stops firing without needing a state file.

set -uo pipefail
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null) || exit 0
tx=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$tx" ] && [ -f "$tx" ] || exit 0

# Last assistant entry in the tail: its model + concatenated text. The abort
# tail is short (ERR, system, snapshot), so 120 lines is ample headroom.
read -r model errtext < <(
  tail -n 120 "$tx" 2>/dev/null | jq -rs '
    [ .[] | select(.type=="assistant") ] | last // empty
    | ( (.message.model // "") ) as $m
    | ( (.message.content) |
        if type=="array" then ([ .[] | select(.type=="text") | .text ] | join(" "))
        else (.//"" | tostring) end ) as $t
    | "\($m)\t\($t)"
  ' 2>/dev/null | tr '\n' ' '
)

# Fire only when the prior turn was a synthetic API-error abort.
case "$model" in
  "<synthetic>") : ;;
  *) exit 0 ;;
esac
# Match the error signature on the (short) text — rg if present, grep otherwise.
if command -v rg >/dev/null 2>&1; then match() { rg -qi "$1"; }; else match() { grep -qiE "$1"; }; fi
printf '%s' "$errtext" | match 'api error|rate limit|overloaded|temporarily limiting' || exit 0

# Keyword gist only — the full 4-step ritual is the single source of truth in
# rules/api-error-recovery.md (keep them from drifting by not duplicating it).
msg="[api-recovery] The previous turn died on a transient API error (not your usage limit) and produced nothing. Re-orient before continuing — don't trust pre-abort memory: restate the goal · verify what's actually done (Task list, git status/diff, recent files) · find the in-flight step and check it on disk, rolling back if half-done · then resume. Fleet died? → ~/.claude/scripts/fleet-triage.py (reuse finished, re-dispatch only the dead). Starting a NEW task instead? note the abort and proceed. Full ritual: rules/api-error-recovery.md."

jq -nc --arg m "$msg" '{additionalContext:$m}'
exit 0
