#!/usr/bin/env bash
# queue-stop.sh: Stop hook. While a queue drive is on, a stop with agent-ready
# rows left on the goal is sent back with the next row named.
#
# It keys on the goal record, not on the wording of the reply: the question is
# whether `queue-run.sh ready` still lists a row. Active only in a session that
# ran `queue-run.sh on` (owner ruling queue-1015 Q3). It blocks once per record
# state and steps aside when nothing is ready. Under stop_hook_active (the agent
# is already continuing after a block) it blocks again only when the record has
# moved since, so it can never loop without progress. If three stops in a row
# see the record unchanged, the row in hand is parked with a reason and the block
# names the next one, so a loop the agent does not notice still moves on.
#
# Mute: touch ~/.claude/.no-queue-stop-gate (machine-wide until removed);
# pause one session's drive with `queue-run.sh off`.
set -uo pipefail
[ -f "$HOME/.claude/.no-queue-stop-gate" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
continuing=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -n "$sid" ] || exit 0
GOALS="$HOME/.claude/goals"
drive="$GOALS/runs/active/$sid.json"
[ -f "$drive" ] || exit 0
QR="$HOME/.claude/scripts/goals/queue-run.sh"
gid=$(jq -r '.goal // empty' "$drive" 2>/dev/null)
[ -n "$gid" ] && [ -f "$GOALS/by-id/$gid.json" ] || exit 0
rows=$(bash "$QR" ready --sid "$sid" 2>/dev/null) || exit 0
. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null || exit 0

# The record's state: every row's state and gate, plus how far the run ledger has got.
sig=$( { jq -c '[.tasks[] | [.id, .state, (.gate != null)]]' "$GOALS/by-id/$gid.json"; wc -l < "$GOALS/runs/$gid.jsonl" 2>/dev/null; } | shasum | cut -c1-12)
MARK="/tmp/claude-queuestop-$(hook_sid8 "$sid")"
prev_sig=""; seen=0
[ -f "$MARK" ] && read -r prev_sig seen < "$MARK"
if [ "$sig" = "$prev_sig" ]; then seen=$((seen + 1)); else seen=1; fi

parked_note=""
if [ "$seen" -ge 3 ] && [ "$continuing" != "true" ]; then
  first=$(printf '%s\n' "$rows" | head -n 1)
  id=$(printf '%s' "$first" | sed -n 's/^#\([0-9][0-9]*\).*/\1/p')
  if [ -n "$id" ] && bash "$QR" park "$id" --sid "$sid" --by queue-stop \
       --why "the session stopped 3 times with the goal record unchanged; parked by the Stop hook so the run moves on" >/dev/null 2>&1; then
    parked_note="Parked $first: three stops in a row left the record unchanged."
    rows=$(bash "$QR" ready --sid "$sid" 2>/dev/null) || rows=""
    sig=$( { jq -c '[.tasks[] | [.id, .state, (.gate != null)]]' "$GOALS/by-id/$gid.json"; wc -l < "$GOALS/runs/$gid.jsonl" 2>/dev/null; } | shasum | cut -c1-12)
    seen=1
  fi
fi
printf '%s %s\n' "$sig" "$seen" > "$MARK"
# One block per record state: a repeat stop on the same state is let through.
[ "$seen" -eq 1 ] || exit 0
[ -n "$rows" ] || exit 0

next=$(printf '%s\n' "$rows" | head -n 1)
n=$(printf '%s\n' "$rows" | wc -l | tr -d ' ')
reason="The queue drive is on and goal $gid still has $n agent-ready row(s). Next: $next. Run queue-run.sh next and work it; park it with queue-run.sh park <id> --why \"…\" once its budget is spent, and stop only when queue-run.sh ready lists nothing."
[ -n "$parked_note" ] && reason="$parked_note $reason"
text=$(hook_last_assistant_text "$input" "$(printf '%s' "$input" | jq -r '.transcript_path // empty')")
last=$(printf '%s\n' "$text" | sed '/^[[:space:]]*$/d' | tail -n 1)
case "$last" in
  *\?*) reason="Your reply ends on a question. Nothing is asked mid-run: if only the owner can answer it, file it with gs gate $gid <id> \"USER: …\" --do \"<your drafted answer>\" and carry on; otherwise answer it yourself. $reason" ;;
esac
reason="$reason To pause the run: queue-run.sh off. Mute: touch ~/.claude/.no-queue-stop-gate"
jq -cn --arg r "$reason" '{decision:"block", reason:$r}'
