#!/usr/bin/env bash
# skill-invocation-log.sh — PostToolUse on Skill: record that a skill actually ran.
#
# skills/usage/events.jsonl is written by a `skill-log.sh record` step inside each
# SKILL.md, which means it measures WHICH SKILLS REMEMBERED TO REPORT, not which
# ran. Measured 2026-09-01: 49 of 74 skills carry no such step, including
# adversarial-review, magi, decision-wizard and gated-plan. An analysis that read
# their zeros as "never used" was wrong, and the owner caught it.
#
# This closes the gap at the only place that cannot be forgotten: the dispatch
# itself. One line per invocation into a separate stream, so the self-reported
# ledger keeps its meaning (it carries outcome, corrections, gate verdicts that
# only the skill knows) and this one carries ground truth about what ran.
#
# Deliberately NOT merged into events.jsonl: those rows mean "a skill reported its
# own outcome" and these mean "a skill was invoked". Conflating them would destroy
# the only signal that revealed the gap.
set -uo pipefail
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0

name=$(printf '%s' "$input" | jq -r '.tool_input.skill // empty' 2>/dev/null)
[ -n "$name" ] || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null)

LOG="$HOME/.claude/skills/usage/invocations.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || exit 0
line=$(jq -cn --arg s "$name" --arg sid "$sid" \
  '{ts:(now|todate), skill:$s, session_id:$sid, src:"dispatch"}' 2>/dev/null) || exit 0

# Concurrent sessions share this stream; a partial line would poison the ledger.
if command -v flock >/dev/null 2>&1; then
  printf '%s\n' "$line" | flock "$LOG.lock" tee -a "$LOG" >/dev/null 2>&1 || true
else
  printf '%s\n' "$line" >> "$LOG" 2>/dev/null || true
fi
exit 0
