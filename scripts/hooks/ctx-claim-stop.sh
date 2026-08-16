#!/usr/bin/env bash
# ctx-claim-stop.sh — Stop hook: catch a context-capacity claim that no
# measurement supports, and answer it with the number.
#
# Why. rules/communication.md § "Context-load claims need the instrument, not a
# feeling" says the ctx-pressure hook is the only thing that measures, and that
# absent a notice you are under 70 percent. The rule ran advisory-only and was
# broken again on 2026-08-16 (atone mist-20260816-002118-7f, S3, juror
# very-wrong): the agent read the auto-checkpoint notice at tool count 60, which
# says "long session, context may auto-compact soon", as a capacity reading. It
# counts TOOL CALLS. The agent then stopped work the user had explicitly
# authorized, so the cost was not a hedge in prose but a spent round-trip.
#
# What makes this gate cheap to obey: it does not merely say "you did not
# measure". It reads the same instrument ctx-pressure-nudge.sh reads and puts the
# actual figure in the message. A claim of pressure answered by "the instrument
# says 34 percent" needs no further argument.
#
# WARN, NOT BLOCK. The trigger is a phrase in prose, and prose about context is
# ordinary in this account (a session that is BUILDING context tooling discusses
# compaction constantly, this file's own provenance included). features/hook-
# design.md matches consequence to cost-of-false-fire, and a false block on a
# vocabulary match would be expensive and frequent. A miss costs one wrong
# sentence.
#
# Silent when the instrument cannot be read. A gate that cannot measure has no
# standing to correct someone for not measuring.
#
# Mute: touch ~/.claude/.no-ctx-claim-gate (machine-wide until removed).

set -uo pipefail
[ -f "$HOME/.claude/.no-ctx-claim-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v rg >/dev/null 2>&1 || exit 0

HOOK_COMMON="$HOME/.claude/scripts/hooks/hook-common.sh"
[ -r "$HOOK_COMMON" ] || exit 0
. "$HOOK_COMMON"

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0
sid8=$(hook_sid8 "$sid")

# ── read the instrument, by the same ladder ctx-pressure-nudge.sh uses ────────
rem=$(printf '%s' "$input" | jq -r '.context_window.remaining_percentage // empty' 2>/dev/null)
if [ -z "$rem" ] || [ "$rem" = null ]; then
  ctx_file="${CTX_FILE_OVERRIDE:-/tmp/claude-ctx-${PPID}}"
  hook_clear_reset "$sid8" "$ctx_file"
  [ -f "$ctx_file" ] && rem=$(tr -dc '0-9.' < "$ctx_file" 2>/dev/null)
fi
# No reading, no standing. Stay silent rather than guess in the other direction.
[ -n "$rem" ] || exit 0
printf '%s' "$rem" | rg -q '^[0-9]+(\.[0-9]+)?$' || exit 0
used=$(awk -v r="$rem" 'BEGIN { printf "%d", 100 - r }' 2>/dev/null)
[ -n "$used" ] || exit 0

# Genuinely under pressure? Then the claim is TRUE and this hook has no business
# firing. 70 is the same first band ctx-pressure-nudge.sh uses, deliberately, so
# the two hooks cannot disagree about what "pressure" means.
[ "$used" -ge 70 ] 2>/dev/null && exit 0

# ── the final message ────────────────────────────────────────────────────────
tail_json=$(tail -n 400 "$tp" 2>/dev/null) || exit 0
last_asst=$(printf '%s\n' "$tail_json" | jq -rc 'select(.type=="assistant")' 2>/dev/null | tail -n 1)
[ -n "$last_asst" ] || exit 0
text=$(printf '%s' "$last_asst" | jq -r '.message.content[]? | select(.type=="text") | .text' 2>/dev/null)
[ -n "$text" ] || exit 0
prose=$(printf '%s\n' "$text" | awk 'BEGIN{f=0} /^[[:space:]]*```/{f=!f; next} !f{print}')
[ -n "$prose" ] || exit 0

# Meta-discussion exemption. A message naming the instrument or this gate is
# talking ABOUT context machinery, not claiming to be short of room. Without this
# the hook fires on every session that maintains it, including the one that wrote
# it.
printf '%s\n' "$prose" | rg -qi 'ctx-pressure|ctx-claim|context-capacity claim|ctx_pressure' 2>/dev/null && exit 0

# Claim shapes only. NOT the bare word "context", which is ordinary English here
# ("in the context of", "context window", "enough context to decide").
CLAIM='(low on context|running (out|low) on context|context is (getting |nearly )?(full|tight|limited|exhausted)|near(ing)? (the )?(context )?(limit|capacity)|context (budget|pressure)|conserve context|out of context|risk(s|ing)? (a|an) (auto-?)?compact|may auto-?compact|might auto-?compact|before (we|it) (auto-?)?compacts?|compact mid-|mid-edit compact|context may auto-compact)'

hit=$(printf '%s\n' "$prose" | rg -niP "$CLAIM" 2>/dev/null | head -3)

MARK="/tmp/claude-ctxclaim-${sid8}"
if [ -z "$hit" ]; then
  if [ -f "$MARK" ]; then
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook ctx-claim \
      --heed-of "ctx-claim:$sid8" --heeded true >/dev/null 2>&1 || true
    rm -f "$MARK" 2>/dev/null || true
  fi
  exit 0
fi

if ! hook_loop_check "$MARK" "$prose"; then
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook ctx-claim \
    --heed-of "ctx-claim:$sid8" --heeded false >/dev/null 2>&1 || true
  exit 0
fi

msg="⚠ unmeasured context claim — the instrument says context is ~${used}% full, which is below the 70% first band, so no pressure exists to report.

Claim(s) in the final message:
$hit

If this sentence changed what you did (stopped work, handed back, recommended /clear or /compact), reconsider: the auto-checkpoint notice counts TOOL CALLS, not context, and is not a capacity reading. Absent a ctx-pressure notice you are under 70%. Mute: touch ~/.claude/.no-ctx-claim-gate"

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook ctx-claim --action nudge \
  --heeded unknown >/dev/null 2>&1 || true
jq -cn --arg m "$msg" '{systemMessage:$m}' 2>/dev/null || true
exit 0
