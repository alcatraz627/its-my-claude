#!/usr/bin/env bash
# 37-goal-standing.sh — UserPromptSubmit hinter: the session's goal, kept in view.
#
# The built-in /goal Stop hook dies on /clear and nothing re-arms it. When /catchup
# (or the agent) has written a gcc goal for this session (scripts/goal/goal.sh set)
# and the harness /goal is NOT armed, this injects the standing objective on the
# first prompt and then every 8th, with the one line the owner can paste to arm the
# real Stop hook. When the harness goal IS armed it stays silent: the harness already
# holds the goal, and a second voice would be noise. Owner ruling 2026-08-18: losing
# the goal is the one unacceptable outcome; the agent re-arms unless told not to.
#
# State: /tmp/claude-goalhint-<sid8>, a prompt counter. Mute: touch ~/.claude/.no-goal-hint
set -uo pipefail
PROMPT=$(cat 2>/dev/null || echo "")
[ -f "$HOME/.claude/.no-goal-hint" ] && exit 0
SID="${CLAUDE_HINT_SID:-${CLAUDE_CODE_SESSION_ID:-}}"; [ -n "$SID" ] || exit 0
GOAL="$HOME/.claude/goals/$SID.json"
# machine-generated "user" turns are not the owner talking; do not spend a slot on them
case "$PROMPT" in "<system-reminder>"*|"<command-name>"*|"<local-command"*|"Caveat:"*|"Base directory for this skill:"*|"Stop hook feedback:"*|"<task-notification>"*|"Another Claude session sent"*) exit 0;; esac
G="$HOME/.claude/scripts/goal/goal.sh"
if [ ! -f "$GOAL" ]; then
  # No goal anywhere. The first paste line went unarmed and nothing raised the
  # absence again across twenty turns of work (sys-monitor, 2026-09-08). Its own
  # counter, so these prompts spend no slot of the standing-goal cadence below:
  # once at the eighth goalless prompt and every sixteenth after.
  S2="/tmp/claude-nogoal-${SID:0:8}"; m=$(cat "$S2" 2>/dev/null || echo 0); m=$((m+1)); echo "$m" > "$S2"
  [ "$m" -eq 8 ] || [ $((m % 16)) -eq 0 ] || exit 0
  armed=$(bash "$G" harness --sid "$SID" 2>/dev/null | jq -r '.armed // false')
  [ "$armed" = "true" ] && exit 0
  printf '%s\n' "[goal] $m prompts in and no goal is armed or proposed for this session. If this is more than a lookup, print the owner a /goal paste line now (rules/goal-statement-on-starting-work.md) and work under it. (mute: touch ~/.claude/.no-goal-hint)"
  exit 0
fi
STATE="/tmp/claude-goalhint-${SID:0:8}"; n=$(cat "$STATE" 2>/dev/null || echo 0); n=$((n+1)); echo "$n" > "$STATE"
[ "$n" -eq 1 ] || [ $((n % 8)) -eq 0 ] || exit 0
armed=$(bash "$G" harness --sid "$SID" 2>/dev/null | jq -r '.armed // false')
[ "$armed" = "true" ] && exit 0
text=$(jq -r '.text // empty' "$GOAL"); [ -n "$text" ] || exit 0
by=$(jq -r '.by // "agent"' "$GOAL")
# The paste line stands alone on its own line, bare, so selecting it copies clean.
# It used to sit mid-sentence with the mute clause appended (adv-goal F7,
# 2026-09-05), on the goal surface the owner meets most often.
printf '%s\n%s\n%s\n' \
  "[goal] Standing objective for this session (set by $by, harness /goal NOT armed): $text. Keep working under it. To arm the Stop hook too, the owner can paste the next line:" \
  "/goal $text" \
  "(mute: touch ~/.claude/.no-goal-hint)"
