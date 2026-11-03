#!/usr/bin/env bash
# lifecycle: tune-able hook (owner D2, 2026-11-03: a command plus an advisory note; revisit a block only if the mistake recurs)
# instrument: self (a ready-to-merge run after the note records heeded:true)
# review-by: 2026-12-01
# retire-if: heed-rate < 30% over 20 fires
# ready-claim-note.sh: tells the owner, on screen, when a reply says a pull request is ready to
# merge and nothing checked that this turn.
#
# "Ready to merge" has been said three times (2026-08-26, 2026-09-18, 2026-10-28) about a PR GitHub
# showed as conflicting, because the agent judged from the review bot's last round and never asked
# GitHub. scripts/pr/ready-to-merge.py asks GitHub about every merge precondition; this note
# points at it. It never blocks: owner ruling D2a, hard-blocks are earned by a repeat.
#
#   claim, no ready-to-merge run this turn        note: run it
#   claim, run this turn said NOT READY           note: the check disagrees with the reply
#   claim, run this turn said READY               silent
#
# Loop-safe: one note per distinct claim; the same claim at a later Stop records heeded:false
# once and stays quiet. A run after a note records heeded:true.
# Mute: touch ~/.claude/.no-ready-claim-note (machine-wide until removed). Telemetry: warn-log.sh --hook ready-claim.

# Advice for a person reading the reply: see hook_should_run.
. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null && { hook_should_run owner-turn || exit 0; }

set -uo pipefail
[ -f "$HOME/.claude/.no-ready-claim-note" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null || exit 0
hook_snoozed ready-claim && exit 0

input=$(cat 2>/dev/null) || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
sid8=$(hook_sid8 "$sid")
LOG="$HOME/.claude/scripts/hooks/warn-log.sh"
MARK="/tmp/claude-ready-claim-${sid8}"   # signature of the claim we last noted

# This turn's tool activity: from the last real user message to the end of the transcript.
turn=""
if [ -n "$tp" ] && [ -f "$tp" ]; then
  window=$(tail -n 1200 "$tp" 2>/dev/null)
  start=$(printf '%s\n' "$window" | jq -rc '
    select(.type=="user"
      and ( (.message.content|type=="string" and (.|length>0))
         or (.message.content|type=="array" and (any(.[]?; .type=="text"))) ))
    | input_line_number' 2>/dev/null | tail -n 1)
  if [ -n "$start" ]; then turn=$(printf '%s\n' "$window" | tail -n +"$start"); else turn="$window"; fi
fi
ran=0; last_verdict=""
if [ -n "$turn" ]; then
  # A run is a Bash call that names the command, whatever flags or path came with it.
  if printf '%s\n' "$turn" | jq -r 'select(.type=="assistant") | .message.content[]?
      | select(.type=="tool_use" and .name=="Bash") | .input.command // empty' 2>/dev/null | rg -q 'ready-to-merge'; then
    ran=1
    last_verdict=$(printf '%s\n' "$turn" | jq -r 'select(.type=="user") | .message.content[]?
        | select(.type=="tool_result") | (.content // "") | if type=="array" then (map(.text? // "")|join("\n")) else . end' 2>/dev/null \
      | rg -o '^(NOT )?READY TO MERGE:' 2>/dev/null | tail -n 1)
  fi
fi

if [ "$ran" = 1 ] && [ "$last_verdict" != "NOT READY TO MERGE:" ] && [ -s "$MARK" ] && [ ! -f "$MARK.seen" ]; then
  # A note was shown and the check has now run: the note was heeded.
  bash "$LOG" --hook ready-claim --heed-of "ready-claim:$sid8" --heeded true >/dev/null 2>&1 || true
  : > "$MARK.seen"
fi

claim_text=$(hook_last_assistant_text "$input" "$tp") || exit 0
[ -n "$claim_text" ] || exit 0

# What counts as the claim. Quoted output, code and block quotes describe, so they are removed first
# (same stripper declared-ready-stop.sh uses). Each sentence is judged alone: a conditional, a question
# or a negation ("not ready to merge", "once it is ready to merge", "ready to merge?") is no claim.
CLAIM_RE='\b((ready|good|safe|clear|fine|okay|ok)[[:space:]]+to[[:space:]]+(be[[:space:]]+)?merg(e|ed)|can[[:space:]]+(now[[:space:]]+)?be[[:space:]]+merged|merge[- ]ready|ready[[:space:]]+for[[:space:]]+merg(e|ing))\b'
NOT_A_CLAIM_RE="\\b(not|isn.?t|aren.?t|wasn.?t|never|no longer|cannot|can.?t|won.?t|until|once|unless|if|when|before|after|whether|whenever|should be|would be|will be|to be sure|check (that|whether)|so that)\\b"
prose=$(printf '%s\n' "$claim_text" \
  | awk 'BEGIN{f=0} /^[[:space:]]*```/{f=!f; next} !f{print}' \
  | sed -e 's/`[^`]*`//g' -e '/^[[:space:]]*>/d')
claim=""
while IFS= read -r s; do
  [ -n "$s" ] || continue
  printf '%s' "$s" | rg -qiP "$CLAIM_RE" 2>/dev/null || continue
  printf '%s' "$s" | rg -qiP "$NOT_A_CLAIM_RE" 2>/dev/null && continue
  printf '%s' "$s" | rg -q '\?[[:space:]]*$' 2>/dev/null && continue
  claim="$s"; break
done <<EOF
$(printf '%s' "$prose" | rg -oP '[^.!?\n]+[.!?]?' 2>/dev/null)
EOF
[ -n "$claim" ] || exit 0

# A run this turn that agreed with the reply leaves nothing to say.
if [ "$ran" = 1 ] && [ "$last_verdict" = "READY TO MERGE:" ]; then exit 0; fi

kind=norun; [ "$ran" = 1 ] && kind=disagree
sig=$(printf '%s:%s' "$kind" "$claim" | shasum 2>/dev/null | awk '{print $1}')
prev=""; [ -s "$MARK" ] && prev=$(cat "$MARK" 2>/dev/null)
if [ -n "$sig" ] && [ "$sig" = "$prev" ]; then
  # Told once already and the claim came back unchanged: scored once, then quiet.
  if [ ! -f "$MARK.seen" ]; then
    bash "$LOG" --hook ready-claim --heed-of "ready-claim:$sid8" --heeded false >/dev/null 2>&1 || true
    : > "$MARK.seen"
  fi
  exit 0
fi
printf '%s' "$sig" > "$MARK" 2>/dev/null || true
rm -f "$MARK.seen" 2>/dev/null
bash "$LOG" --hook ready-claim --action nudge --heeded unknown --detail "$kind" >/dev/null 2>&1 || true

if [ "$kind" = disagree ]; then
  msg="ℹ ready-claim: this reply says a PR is ready to merge, but ready-to-merge ran this turn and said NOT READY. Its blockers are in the tool output above; the reply and the check disagree. Mute: touch ~/.claude/.no-ready-claim-note"
else
  msg="ℹ ready-claim: this reply says a PR is ready to merge, and nothing asked GitHub this turn. A review bot's last round is not the merge state: on 2026-10-28 a PR was called ready while GitHub showed it conflicting. python3 ~/.claude/scripts/pr/ready-to-merge.py <pr> reads conflicts, checks, reviews, open threads, the Clanky review, the target branch and unpushed commits, and names each blocker. Mute: touch ~/.claude/.no-ready-claim-note"
fi
jq -cn --arg m "$msg" '{systemMessage:$m}' 2>/dev/null || true
exit 0
