#!/usr/bin/env bash
# named-next-work-stop.sh: Stop hook: a "Doing now" section is a claim, not a plan.
#
# The account's second most-fired slug, named-the-next-work-then-stopped: 15
# events, 7 in the week to 2026-09-08. The newest shape (forge-brains,
# mist-20260908-072846-a0, juror very-wrong): a plain-words task list whose
# first section was headed "Doing now", three items, every input in hand, turn
# ended. The standing precheck asks about permission, and that halt did not feel
# like asking permission, so it never triggered. The RCA's own proposal is this
# hook: key on the reply text, not on the agent's sense of what it is doing.
#
# So a final message that carries a "Doing now" / "Doing next" / "Next I will" /
# "Next steps" heading or bold label is blocked ONCE, with the precheck as the
# reason: for each item, name the input it still lacks; if none lacks one, do
# the items in this turn; if one does, move it under "waiting on" with the
# input named. A message that already puts the items under a waiting-on or
# blocked-on label passes. Loop-safe: stop_hook_active steps aside, one block
# per message hash.
# Mute: touch ~/.claude/.no-named-next-work-gate  (machine-wide until removed)
# Advice for a person reading the reply: see hook_should_run.
. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null && { hook_should_run owner-turn || exit 0; }

set -uo pipefail
[ -f "$HOME/.claude/.no-named-next-work-gate" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty'); sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -n "$sid" ] || exit 0

# The shared reader sits beside this hook when HOME has no copy (a test home).
type hook_last_assistant_text >/dev/null 2>&1 || . "$(dirname "$0")/hook-common.sh" 2>/dev/null || exit 0
# The reply comes from the Stop input (the transcript lags one message at Stop time).
text=$(hook_last_assistant_text "$input" "$tp")
[ -n "$text" ] || exit 0

# A heading or a bold label at line start. Inline prose ("next I will read the
# file, then…") is a sentence, not a section, and passes.
shape=""
head_line=$(printf '%s\n' "$text" | rg -n -i -m1 '^\s*(#{1,6}\s*|\*\*|__)?\s*(doing now|doing next|next i will|next i.ll|next steps?|up next|what i.ll do next|next on my (side|end|plate)|my next steps?)\s*(\*\*|__)?\s*:?\s*$' | cut -d: -f1)
if [ -n "$head_line" ]; then
  # The items are parked only when the waiting-on label comes after them. A
  # "Waiting on you" section higher up lists the owner's items and says nothing
  # about the agent's own.
  wait_line=$(printf '%s\n' "$text" | rg -n -i '^\s*(#{1,6}\s*|\*\*|__)?\s*(waiting on|blocked on|blocked_on|waits on)' | tail -n 1 | cut -d: -f1)
  [ -n "$wait_line" ] && [ "$wait_line" -gt "$head_line" ] && exit 0
  shape="section"
fi
# The reply's last lines say what comes next and then hand the go back
# ("I'll start item 1 next unless you'd rather redirect"). The owner reads that
# as waiting for a yes that was never needed.
tail3=$(printf '%s\n' "$text" | rg -v '^\s*$' | tail -n 3)
if [ -z "$shape" ] && printf '%s' "$tail3" | rg -qi "\bI(.ll| will| am going to|.m going to)\b[^.\n]{0,120}\bunless you\b"; then
  # A reply that is waiting on a running job has not stopped working.
  hook_background_live "$input" && exit 0
  shape="offer"
fi
[ -n "$shape" ] || exit 0

h=$(printf '%s' "$text" | shasum | cut -c1-12)
STATE="/tmp/claude-nextwork-${sid:0:8}"
[ "$(cat "$STATE" 2>/dev/null)" = "$h" ] && exit 0
printf '%s' "$h" > "$STATE"
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook named-next-work --action block --heeded unknown >/dev/null 2>&1 || true
jq -cn --arg r 'This reply has a "Doing now" / "Next" section and the turn is ending. That section is a claim about work, and the account has ended the turn on exactly this shape 15 times (named-the-next-work-then-stopped, 7 this week). Precheck, per item: name the input it still lacks. If no item lacks one, do the items in this turn, now, and send the reply after. If one does, move it under a "waiting on" label with the missing input named, and do the rest. Blocks once per message; mute: touch ~/.claude/.no-named-next-work-gate' '{decision:"block", reason:$r}'
