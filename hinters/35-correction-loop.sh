#!/usr/bin/env bash
# 35-correction-loop.sh — UserPromptSubmit hinter: correction-density breaker.
#
# When the user corrects the agent repeatedly in a short span, the best move is
# usually NOT to keep patching a poisoned context — a fresh session with a better
# prompt beats a long one carrying accumulated corrections (Anthropic best-
# practices §"manage your session"; this account runs a ~22%-correction profile).
# This detects correction DENSITY (>=3 correction-shaped prompts in the last 6)
# and once suggests the core-dump -> clear -> restate remedy — which the Resume
# Contract now makes cheap.
#
# It measures density, not same-issue semantics, so it is a cheap additionalContext
# nudge, never a block (features/hook-design.md: price FP by cost-of-false-fire; a
# dismissable nudge tolerates a higher FP rate than a block ever could). The
# 3-in-6 window damps the odd misclassified prompt; it fires once per cluster and
# re-arms only after the loop breaks (a window with <=1 correction).
#
# Sibling, not overlap: 10-atone-circuit-breaker fires on a repeated FILED atone
# slug; this fires on repeated USER corrections that never got an /atone. Different
# signal, same spirit.
#
# State: /tmp/claude-corrloop-<session>  (line 1 = window string of 0/1, last 6;
#        line 2 = "fired" once armed). Mute: touch ~/.claude/.no-correction-loop
#        (machine-wide, like every .no-* mute — see features/hook-design.md).

set -uo pipefail
PROMPT=$(cat 2>/dev/null || echo "")
[ -z "$PROMPT" ] && exit 0
[ -f "$HOME/.claude/.no-correction-loop" ] && exit 0

SESSION_KEY="${CLAUDE_SESSION_ID:-$(date +%Y-%m-%d)}"
STATE="/tmp/claude-corrloop-${SESSION_KEY}"

low=$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Correction-shaped? Conservative: strong pushback phrases, OR a short prompt that
# opens with a bare negation. Long prompts that merely contain "no"/"wrong" mid-
# sentence are NOT flagged (that is normal task language, not a correction).
cls=0
case "$low" in
  *"revert"*|*"undo that"*|*"that's not"*|*"thats not"*|*"not what i"*|\
  *"why did you"*|*"you broke"*|*"you missed"*|*"you ignored"*|*"you keep"*|\
  *"still broken"*|*"still failing"*|*"still wrong"*|*"still not"*|\
  *"stop doing"*|*"that's wrong"*|*"thats wrong"*|*"this is wrong"*|\
  *"undo the"*|*"put it back"*|*"broke it"*|*"same mistake"*|*"again?"*) cls=1 ;;
esac
if [ "$cls" = 0 ]; then
  # short bare-negation opener (a terse correction like "no, use X" / "nope" / "wrong")
  words=$(printf '%s' "$low" | wc -w | tr -d ' ')
  if [ "$words" -le 8 ]; then
    case "$low" in no|nope|wrong|"no "*|"nope "*|"wrong "*|"not "*|"don't "*|"dont "*) cls=1 ;; esac
  fi
fi

# Roll the window (keep last 6 classifications).
win=""; fired=""
if [ -f "$STATE" ]; then
  win=$(sed -n 1p "$STATE" 2>/dev/null)
  fired=$(sed -n 2p "$STATE" 2>/dev/null)
fi
win="${win}${cls}"
# Keep last 6 chars. Positive offset only: bash 3.2's `${v: -6}` returns EMPTY
# when the string is shorter than 6 (verified) — using it here silently wiped
# the window every turn until it reached length 6.
len=${#win}
[ "$len" -gt 6 ] && win="${win:$((len-6))}"
count=$(printf '%s' "$win" | tr -cd 1 | wc -c | tr -d ' ')

# Re-arm once the loop breaks (this window has <=1 correction).
[ "$count" -le 1 ] && fired=""

out=""
if [ "$count" -ge 3 ] && [ "$fired" != "fired" ]; then
  fired="fired"
  out="[correction-loop] You've corrected me ${count}× in the last few turns. Past ~2 corrections on one thread, a fresh session with a sharper prompt usually beats continuing to patch this context (Anthropic best-practices). Cheap now: /core-dump (the Resume Contract captures the next move) → /clear → restate the task incorporating what we just learned. Ignore if this is steady iteration, not a stuck loop.  (mute: touch ~/.claude/.no-correction-loop)"
fi

# Persist window + fired flag.
printf '%s\n%s\n' "$win" "$fired" > "$STATE" 2>/dev/null || true

[ -n "$out" ] && printf '%s\n' "$out"
exit 0
