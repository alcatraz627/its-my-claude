#!/usr/bin/env bash
# 39-goal-arm-lint.sh — UserPromptSubmit hinter: lint the goal the harness armed.
#
# goal.sh warns about an owner-actor clause on its own set path, but the owner
# arms goals with the built-in /goal, which never passes through goal.sh. On
# 2026-09-05 two such goals jammed the Stop hook 9 and 23 times. This reads the
# armed text from the transcript on each owner prompt (goal.sh harness, ~30ms),
# lints it once per distinct text, and warns. It never blocks and never clears.
# Owner ruling 2026-09-08 (a): "yes ... let's measure like we already are".
#
# State: /tmp/claude-goalarm-<sid8>, the hash of the last text linted.
# Mute: touch ~/.claude/.no-goal-arm-lint
set -uo pipefail
PROMPT=$(cat 2>/dev/null || echo "")
[ -f "$HOME/.claude/.no-goal-arm-lint" ] && exit 0
SID="${CLAUDE_HINT_SID:-${CLAUDE_CODE_SESSION_ID:-}}"; [ -n "$SID" ] || exit 0
case "$PROMPT" in "<system-reminder>"*|"<command-name>"*|"<local-command"*|"Caveat:"*|"Base directory for this skill:"*|"Stop hook feedback:"*|"<task-notification>"*|"Another Claude session sent"*) exit 0;; esac
G="$HOME/.claude/scripts/goal/goal.sh"
# harness exits 1 on a cleared goal and still prints its JSON; the clear is the
# case the retire branch below exists for, so the exit code is not the gate.
hj=$(bash "$G" harness --sid "$SID" 2>/dev/null) || true
[ -n "$hj" ] || exit 0
STATE="/tmp/claude-goalarm-${SID:0:8}"
GCC="$HOME/.claude/goals/$SID.json"
if [ "$(printf '%s' "$hj" | jq -r '.armed // false')" != "true" ]; then
  # The owner cleared a goal this hinter had seen armed: retire the mirror too,
  # or the standing hinter re-injects a goal he ended (csync, 2026-09-08).
  if [ -f "$STATE" ] && [ -f "$GCC" ] && [ "$(jq -r '.by // empty' "$GCC")" = "owner" ]; then
    bash "$G" clear --sid "$SID" >/dev/null 2>&1 || true; trash "$STATE" 2>/dev/null || true
  fi
  exit 0
fi
text=$(printf '%s' "$hj" | jq -r '.text // empty'); [ -n "$text" ] || exit 0
h=$(printf '%s' "$text" | shasum | cut -c1-12)
[ "$(cat "$STATE" 2>/dev/null)" = "$h" ] && exit 0
printf '%s' "$h" > "$STATE"
# Mirror the owner's arm into the gcc store, so a /clear does not lose it and
# catchup finds it without grepping the transcript (csync, 2026-09-08: a full
# product goal survived only as a paraphrase in task metadata).
if [ "$(jq -r '.text // empty' "$GCC" 2>/dev/null)" != "$text" ]; then
  bash "$G" set "$text" --by owner --sid "$SID" >/dev/null 2>&1 || true
fi
all=$(bash "$G" lint "$text" 2>&1 >/dev/null | rg -v '^linted\.$' || true)
[ -n "$all" ] || exit 0
# Only an owner-actor clause earns an ask: it jams the Stop hook. A quantifier or
# a filename in a goal the OWNER typed is his register, measured and logged, not
# nagged; three sessions put amended paste lines to him for those (2026-09-08).
actor=$(printf '%s' "$all" | rg -A4 -m1 'names an OWNER action' || true)
other=$(printf '%s' "$all" | rg -v 'OWNER action|Stop-hook goal is only|owner clause blocks|Reword so the agent|rather than .take the owner' || true)
[ -n "$other" ] && bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook goal-arm-lint --action measure --heeded n/a >/dev/null 2>&1 || true
[ -n "$actor" ] || exit 0
printf '%s\n%s\n%s\n' \
  "[goal-arm] The /goal armed in this session carries a clause only the owner can finish, which jams the Stop hook until he clears it by hand (9 and 23 fires on 2026-09-05). Put an amended paste line to him now, in one line, and keep working under the rest:" \
  "$actor" \
  "(mute: touch ~/.claude/.no-goal-arm-lint)"
