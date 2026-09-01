#!/usr/bin/env bash
# 38-goal-offer.sh — UserPromptSubmit hinter: offer a goal line when substantive
# work starts and none is set.
#
# Its sibling 37-goal-standing.sh keeps an EXISTING goal in view and exits on
# line 20 when no goal file is there, so a session that never sets one is never
# reminded it could. Measured in the goal-rearm observation log on 2026-09-01:
# 13 of roughly 24 observed sessions ran with nothing armed. The offer half was
# never built.
#
# This fires at most ONCE per session, only when the owner's prompt reads as work
# starting or a recon beginning, and stays silent on lookups, continuations, and
# machine turns. Owner ruling 2026-09-01: "only offer when a substantive goal
# starts or we do a recon. I won't arm it every time, but it's nice to have it
# offered." So a false fire costs one ignorable line and a miss costs the goal,
# which is why the verb list below is generous rather than precise.
#
# It does NOT write a goal. Proposing is the agent's job, arming is the owner's
# (rules/goal-statement-on-starting-work.md, "Propose, do not arm").
#
# State: /tmp/claude-goaloffer-<sid8>. Mute: touch ~/.claude/.no-goal-hint
# (shared with 37 on purpose: one switch turns off all goal chatter).
set -uo pipefail
PROMPT=$(cat 2>/dev/null || echo "")
[ -f "$HOME/.claude/.no-goal-hint" ] && exit 0
SID="${CLAUDE_HINT_SID:-${CLAUDE_CODE_SESSION_ID:-}}"; [ -n "$SID" ] || exit 0

# A goal already exists → 37 owns this session's goal chatter.
[ -f "$HOME/.claude/goals/$SID.json" ] && exit 0

# Machine-generated "user" turns are not the owner talking.
case "$PROMPT" in
  "<system-reminder>"*|"<command-name>"*|"<local-command"*|"Caveat:"*|\
  "Base directory for this skill:"*|"Stop hook feedback:"*|"<task-notification>"*|\
  "Another Claude session sent"*) exit 0 ;;
esac

# Once per session. Written before the offer so a failure downstream cannot
# turn this into a repeating nudge.
STATE="/tmp/claude-goaloffer-${SID:0:8}"
[ -f "$STATE" ] && exit 0

# The harness may already hold a goal even with no gcc file.
G="$HOME/.claude/scripts/goal/goal.sh"
if [ -x "$G" ]; then
  armed=$(bash "$G" harness --sid "$SID" 2>/dev/null | jq -r '.armed // false' 2>/dev/null)
  [ "$armed" = "true" ] && exit 0
fi

# Work starting, or a recon. Lookups and continuations are not either.
printf '%s' "$PROMPT" | rg -qiP \
  '\b(build|implement|refactor|migrate|redesign|rebuild|rewrite|ship|wire up|set up|stand up|plan (out|for|the)|design|audit|investigate|recon|dig into|look into|figure out|trace|diagnose|scope out|work (on|through)|let'"'"'s (do|build|start|tackle)|start (on|the)|take (on|a look at))\b' \
  2>/dev/null || exit 0

# A lookup wearing a work verb ("show me the plan", "what did you build") is not
# work starting.
printf '%s' "$PROMPT" | rg -qiP '^\s*(what|where|which|who|when|how do|show me|list|tell me|explain|can you (see|find|show))\b' 2>/dev/null && exit 0

: > "$STATE"
echo "[goal] No goal is set for this session and this reads as work starting. Propose one line the owner can optionally arm, per rules/goal-statement-on-starting-work.md: name the outcome a person would recognise when the work lands, not the boxes you will tick. No clause may require the owner to act. Print it bare on its own line as  /goal <text>  so selecting it copies clean. He may well not arm it; offer anyway. (mute: touch ~/.claude/.no-goal-hint)"
