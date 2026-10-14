#!/usr/bin/env bash
# 37-goal.sh — UserPromptSubmit hinter: the one voice for a session's goal.
#
# A goal can be in three states, and each gets one kind of line:
#   - armed with the built-in /goal: lint it once per distinct text and warn only
#     when a clause is the owner's to finish (it jams the Stop hook); mirror the
#     arm into the gcc store so /clear does not lose it; retire the mirror when
#     the owner clears the arm.
#   - set in the gcc store but not armed: keep it in view on the first prompt and
#     every 8th, with the bare paste line that arms the Stop hook.
#   - none at all: offer a goal once when the prompt reads as work starting
#     (owner ruling 2026-09-01: "only offer when a substantive goal starts or we
#     do a recon"), and otherwise remind at the 8th goalless prompt and every
#     16th after.
# It never arms a goal; proposing is the agent's job, arming is the owner's.
#
# State: /tmp/claude-goalarm-<sid8> (last linted hash), /tmp/claude-goalhint-<sid8>
# and /tmp/claude-nogoal-<sid8> (prompt counters), /tmp/claude-goaloffer-<sid8>.
# Mutes: ~/.claude/.no-goal-hint (standing, offer, reminder) and
# ~/.claude/.no-goal-arm-lint (the arm lint and mirror).
set -uo pipefail
PROMPT=$(cat 2>/dev/null || echo "")
SID="${CLAUDE_HINT_SID:-${CLAUDE_CODE_SESSION_ID:-}}"; [ -n "$SID" ] || exit 0
# machine-generated "user" turns are not the owner talking
case "$PROMPT" in "<system-reminder>"*|"<command-name>"*|"<local-command"*|"Caveat:"*|"Base directory for this skill:"*|"Stop hook feedback:"*|"<task-notification>"*|"Another Claude session sent"*) exit 0;; esac
G="$HOME/.claude/scripts/goal/goal.sh"
GCC="$HOME/.claude/goals/$SID.json"
S8="${SID:0:8}"
# harness exits 1 on a cleared goal and still prints its JSON, so the exit code is not the gate
hj=$(bash "$G" harness --sid "$SID" 2>/dev/null) || true
armed=$(printf '%s' "$hj" | jq -r '.armed // false' 2>/dev/null)

# ── armed by the owner: mirror, lint ──
if [ ! -f "$HOME/.claude/.no-goal-arm-lint" ] && [ -n "$hj" ]; then
  ASTATE="/tmp/claude-goalarm-$S8"
  # Only a harness that says plainly "not armed" retires the mirror; a failed or
  # garbled read must never clear the owner's goal.
  if printf '%s' "$hj" | jq -e '.armed == false' >/dev/null 2>&1; then
    # The owner cleared a goal this hinter had seen armed: retire the mirror too,
    # or the standing branch re-injects a goal he ended (csync, 2026-09-08).
    if [ -f "$ASTATE" ] && [ -f "$GCC" ] && [ "$(jq -r '.by // empty' "$GCC")" = "owner" ]; then
      bash "$G" clear --sid "$SID" >/dev/null 2>&1 || true; trash "$ASTATE" 2>/dev/null || true
    fi
  elif [ "$armed" = "true" ]; then
    text=$(printf '%s' "$hj" | jq -r '.text // empty')
    h=$(printf '%s' "$text" | shasum | cut -c1-12)
    if [ -n "$text" ] && [ "$(cat "$ASTATE" 2>/dev/null)" != "$h" ]; then
      printf '%s' "$h" > "$ASTATE"
      if [ "$(jq -r '.text // empty' "$GCC" 2>/dev/null)" != "$text" ]; then
        bash "$G" set "$text" --by owner --sid "$SID" >/dev/null 2>&1 || true
      fi
      all=$(bash "$G" lint "$text" 2>&1 >/dev/null | rg -v '^linted\.$' || true)
      # Only an owner-actor clause earns an ask. A quantifier or a filename in a
      # goal the OWNER typed is his register: measured, not nagged (2026-09-08).
      actor=$(printf '%s' "$all" | rg -A4 -m1 'names an OWNER action' || true)
      other=$(printf '%s' "$all" | rg -v 'OWNER action|Stop-hook goal is only|owner clause blocks|Reword so the agent|rather than .take the owner' || true)
      [ -n "$other" ] && bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook goal-arm-lint --action measure --heeded n/a >/dev/null 2>&1 || true
      if [ -n "$actor" ]; then
        printf '%s\n%s\n%s\n' \
          "[goal-arm] The /goal armed in this session carries a clause only the owner can finish, which jams the Stop hook until he clears it by hand (9 and 23 fires on 2026-09-05). Put an amended paste line to him now, in one line, and keep working under the rest:" \
          "$actor" \
          "(mute: touch ~/.claude/.no-goal-arm-lint)"
      fi
    fi
  fi
fi
# An armed goal speaks for itself; a second voice would be noise.
[ "$armed" = "true" ] && exit 0
[ -f "$HOME/.claude/.no-goal-hint" ] && exit 0

# ── set but not armed: keep it in view ──
if [ -f "$GCC" ]; then
  STATE="/tmp/claude-goalhint-$S8"; n=$(cat "$STATE" 2>/dev/null || echo 0); n=$((n+1)); echo "$n" > "$STATE"
  [ "$n" -eq 1 ] || [ $((n % 8)) -eq 0 ] || exit 0
  text=$(jq -r '.text // empty' "$GCC"); [ -n "$text" ] || exit 0
  by=$(jq -r '.by // "agent"' "$GCC")
  # The paste line stands alone so selecting it copies clean.
  printf '%s\n%s\n%s\n' \
    "[goal] Standing objective for this session (set by $by, harness /goal NOT armed): $text. Keep working under it. To arm the Stop hook too, the owner can paste the next line:" \
    "/goal $text" \
    "(mute: touch ~/.claude/.no-goal-hint)"
  exit 0
fi

# ── no goal: offer once when work starts, remind at the 8th goalless prompt and every 16th after ──
S2="/tmp/claude-nogoal-$S8"; m=$(cat "$S2" 2>/dev/null || echo 0); m=$((m+1)); echo "$m" > "$S2"
OSTATE="/tmp/claude-goaloffer-$S8"
if [ ! -f "$OSTATE" ] \
  && printf '%s' "$PROMPT" | rg -qiP '\b(build|implement|refactor|migrate|redesign|rebuild|rewrite|ship|wire up|set up|stand up|plan (out|for|the)|design|audit|investigate|recon|dig into|look into|figure out|trace|diagnose|scope out|work (on|through)|let'"'"'s (do|build|start|tackle)|start (on|the)|take (on|a look at))\b' 2>/dev/null \
  && ! printf '%s' "$PROMPT" | rg -qiP '^\s*(what|where|which|who|when|how do|show me|list|tell me|explain|can you (see|find|show))\b' 2>/dev/null; then
  : > "$OSTATE"
  echo "[goal] No goal is set for this session and this reads as work starting. Propose one line the owner can optionally arm, per rules/goal-statement-on-starting-work.md: name the outcome a person would recognise when the work lands, not the boxes you will tick. No clause may require the owner to act. Print it bare on its own line as  /goal <text>  so selecting it copies clean. He may well not arm it; offer anyway. (mute: touch ~/.claude/.no-goal-hint)"
  exit 0
fi

[ "$m" -eq 8 ] || [ $((m % 16)) -eq 0 ] || exit 0
printf '%s\n' "[goal] $m prompts in and no goal is armed or proposed for this session. If this is more than a lookup, print the owner a /goal paste line now (rules/goal-statement-on-starting-work.md) and work under it. (mute: touch ~/.claude/.no-goal-hint)"
