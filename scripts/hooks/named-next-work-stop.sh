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
# blocked-on label passes, but only when that label comes after the section: a
# "Waiting on you" list higher up is the owner's items, not the agent's.
#
# A second shape blocks too: a closing line, within the last three, that says
# what comes next and hands the go back ("I'll start item 1 next unless you'd
# rather redirect"). It steps aside while a background job is still running.
# Both were found by replaying this gate over replies the owner corrected
# (i-dream gate replay, 2026-11-23: 0 of 5 halting corrections caught before).
#
# Two more come from the behaviour audit (findings F1 and F5): a reply that says
# nothing waits on the owner over a list of open work, and a reply that ends
# waiting on a job with no word on what happens if no reply comes. Each block
# offers the declared default, "If no reply: <action>" or "If no reply: hold,
# <why>", which keep-warm's next wake follows. A reasoned hold always passes:
# the owner asked that an agent may still choose to wait for a yes.
# Loop-safe: stop_hook_active steps aside, one block per message hash.
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

# The declared default (owner ruling D1, 2026-11-26): a reply that ends while the
# owner may be away says what the agent will do if no reply comes, as
# "If no reply: <action>" or "If no reply: hold, <what only the owner can give>".
# Keep-warm's next wake follows that line, so this gate reads it with keep-warm's
# own parser. A reasoned hold is the agent's call to wait, and passes; an action
# passes when the reply asks the owner something or a job is still running.
KW="${KEEPWARM_PY:-$(cd "$(dirname "$0")" && pwd)/../keepwarm/keepwarm.py}"
decl=$(printf '%s' "$text" | python3 "$KW" declared 2>/dev/null)
decl_kind=${decl%%$'\t'*}
asks=0
printf '%s' "$text" | tail -c 900 | rg -qi '\?(\s|$)|say go|your call|your go|do you want|would you like' && asks=1
shape=""
if [ "$decl_kind" = hold ]; then
  # "hold, the budget split is yours" names the missing input; a bare "hold" does not.
  set -- ${decl#*$'\t'}
  [ $# -ge 3 ] && exit 0
  shape="barehold"
elif [ "$decl_kind" = act ]; then
  [ "$asks" = 1 ] && exit 0
  hook_background_live "$input" && exit 0
  shape="declared"
fi

# A heading or a bold label at line start. Inline prose ("next I will read the
# file, then…") is a sentence, not a section, and passes.
head_line=""
[ -z "$shape" ] && head_line=$(printf '%s\n' "$text" | rg -n -i -m1 '^\s*(#{1,6}\s*|\*\*|__)?\s*(doing now|doing next|next i will|next i.ll|next steps?|up next|what i.ll do next|next on my (side|end|plate)|my next steps?)\s*(\*\*|__)?\s*:?\s*$' | cut -d: -f1)
if [ -n "$head_line" ]; then
  # The items are parked only when the waiting-on label comes after them. A
  # "Waiting on you" section higher up lists the owner's items and says nothing
  # about the agent's own.
  wait_line=$(printf '%s\n' "$text" | rg -n -i '^\s*(#{1,6}\s*|\*\*|__)?\s*(waiting on|blocked on|blocked_on|waits on)' | tail -n 1 | cut -d: -f1)
  # A parked section is fine, and the closing-line check below still runs.
  { [ -n "$wait_line" ] && [ "$wait_line" -gt "$head_line" ]; } || shape="section"
fi
# The reply's last lines say what work comes next and then hand the go back
# ("I'll start item 1 next unless you'd rather redirect"). The owner reads that
# as waiting for a yes that was never needed. It has to name work to begin:
# "I'll keep the default unless you say otherwise" reports a choice already
# made. A quoted line is someone else's words.
tail3=$(printf '%s\n' "$text" | rg -v '^\s*(>.*)?$' | tail -n 3)
if [ -z "$shape" ] && printf '%s' "$tail3" | rg -qi "\bI(.ll| will| am going to|.m going to)\s+(now\s+|then\s+|next\s+)?(start|begin|continue|proceed|pick up|move on|plan|tackle|take|do|run|merge|go ahead|work on|build|implement|write)\b[^\n]{0,160}\bunless you\b"; then
  # A reply that is waiting on a running job has not stopped working.
  hook_background_live "$input" && exit 0
  shape="offer"
fi
# The reply tells the owner nothing waits on them while it lists work still open
# (88339e91 L3905: "Nothing waits on you" over a "Still open" list, then six idle wakes).
if [ -z "$shape" ] && printf '%s' "$text" | rg -qi 'nothing (else |here )?(waits|is waiting) on (you|the owner)|nothing (here )?needs you|not blocked on you' \
   && printf '%s' "$text" | rg -qi 'still open|not yet|next (on my|step|i)|remaining|left to do|pending|not (yet )?(committed|released|pushed|run)\b'; then
  hook_background_live "$input" && exit 0
  shape="nothingwaits"
fi
# The reply ends waiting on a job or a seat while its own release, merge, push or
# commit sits undone, and says nothing of what happens if no reply comes. This fires
# even while the job runs (a9519ebf L15170: suites passed, the release was the
# agent's, and it waited 77 minutes on unrelated seats). A plain wait on a build the
# next step needs passes: a replay over 363 real turn endings found 14 such waits.
if [ -z "$shape" ] && printf '%s' "$tail3" | rg -i "\bI.m (still )?waiting (on|for)\b|\bstill waiting (on|for)\b" | rg -qiv "waiting (on|for) (you|your)\b" \
   && printf '%s' "$text" | rg -qi "until someone|\b(isn.t|is not|not|nothing is|none of it is) (yet )?(released|in production|deployed|merged|pushed|committed)\b"; then
  shape="waiting"
fi
[ -n "$shape" ] || exit 0

h=$(printf '%s' "$text" | shasum | cut -c1-12)
STATE="/tmp/claude-nextwork-${sid:0:8}"
[ "$(cat "$STATE" 2>/dev/null)" = "$h" ] && exit 0
printf '%s' "$h" > "$STATE"
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook named-next-work --action block --heeded unknown >/dev/null 2>&1 || true
declare_hint=' If you are choosing to wait for the owner anyway, end the reply with "If no reply: <what you will do>" or "If no reply: hold, <what only the owner can give>"; keep-warm follows that line.'
mute=' Blocks once per message; mute: touch ~/.claude/.no-named-next-work-gate'
precheck=' That is a claim about work, and the account has ended the turn on exactly this shape 15 times (named-the-next-work-then-stopped, 7 this week). Precheck, per item: name the input it still lacks. If no item lacks one, do the items in this turn, now, and send the reply after. If one does, move it under a "waiting on" label with the missing input named, and do the rest.'
case "$shape" in
  section)      lead='This reply has a "Doing now" / "Next" section and the turn is ending.'; r="$precheck$declare_hint" ;;
  offer)        lead='This reply ends by saying what you will do next and then hands the go back ("unless you ..."), and the turn is ending.'; r="$precheck$declare_hint" ;;
  nothingwaits) lead='This reply says nothing waits on the owner while it lists work still open, and the turn is ending.'; r="$precheck$declare_hint" ;;
  waiting)      lead='This reply ends waiting on something, with no line saying what happens if no reply comes.'
                r=' Name any work of yours that does not depend on what you are waiting on, and do it now.'"$declare_hint" ;;
  barehold)     lead='This reply ends with "If no reply: hold" and gives no reason.'
                r=' A hold is for what only the owner can give: name it after the comma ("If no reply: hold, the budget split is yours"). If nothing is missing, do the work now.' ;;
  declared)     lead='This reply declares what you will do if no reply comes, but it asks the owner nothing, so nothing waits on them.'
                r=' Do that action now, in this turn, and report after. Keep "If no reply:" for turns that put a question to the owner.' ;;
esac
jq -cn --arg lead "$lead" --arg r "$r$mute" '{decision:"block", reason:($lead + $r)}'
