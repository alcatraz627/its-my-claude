#!/usr/bin/env bash
# named-next-work-stop.sh — Stop hook: a "Doing now" section is a claim, not a plan.
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
set -uo pipefail
[ -f "$HOME/.claude/.no-named-next-work-gate" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty'); sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -n "$tp" ] && [ -f "$tp" ] || exit 0

text=$(tail -n 200 "$tp" | python3 -c '
import json, sys
recs = [json.loads(l) for l in sys.stdin if l.strip()]
for r in reversed(recs):
    if r.get("type") == "assistant":
        c = (r.get("message") or {}).get("content") or []
        print(" \n".join(b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text"))
        break
' 2>/dev/null)
[ -n "$text" ] || exit 0

# A heading or a bold label at line start. Inline prose ("next I will read the
# file, then…") is a sentence, not a section, and passes.
printf '%s' "$text" | rg -qi '^\s*(#{1,6}\s*|\*\*|__)?\s*(doing now|doing next|next i will|next i.ll|next steps?|up next|what i.ll do next)\s*(\*\*|__)?\s*:?\s*$' || exit 0
# The items are already parked with what they wait on.
printf '%s' "$text" | rg -qi '^\s*(#{1,6}\s*|\*\*|__)?\s*(waiting on|blocked on|blocked_on|waits on)' && exit 0

h=$(printf '%s' "$text" | shasum | cut -c1-12)
STATE="/tmp/claude-nextwork-${sid:0:8}"
[ "$(cat "$STATE" 2>/dev/null)" = "$h" ] && exit 0
printf '%s' "$h" > "$STATE"
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook named-next-work --action block --heeded unknown >/dev/null 2>&1 || true
jq -cn --arg r 'This reply has a "Doing now" / "Next" section and the turn is ending. That section is a claim about work, and the account has ended the turn on exactly this shape 15 times (named-the-next-work-then-stopped, 7 this week). Precheck, per item: name the input it still lacks. If no item lacks one, do the items in this turn, now, and send the reply after. If one does, move it under a "waiting on" label with the missing input named, and do the rest. Blocks once per message; mute: touch ~/.claude/.no-named-next-work-gate' '{decision:"block", reason:$r}'
