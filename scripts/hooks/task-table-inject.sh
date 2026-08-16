#!/usr/bin/env bash
# task-table-inject.sh — put the task table in front of the owner without them
# having to scroll for it.
#
# WHY A HOOK CANNOT JUST PRINT IT. features/hooks-tui-limits.md:36 is explicit:
# no hook channel reaches the human transcript. additionalContext reaches Claude
# only. So this hook RENDERS the table and hands it to the agent with an
# instruction to reproduce it verbatim. The agent is the only path to the
# transcript (rules/surface-hook-nudges-to-user.md), and this makes that path
# reliable instead of dependent on the agent remembering.
#
# WHY IT EXISTS. The owner asked for the task list 15 times in two days and got
# an inconsistent answer each time: sometimes a table, sometimes prose, sometimes
# a wall of 46 descriptions. The format was never the problem. The consistency
# was. One of those asks was sent twice in a row with "check properly" appended,
# which is the escalation signature of an answer that missed.
#
# TWO TRIGGERS, deliberately narrow:
#   1. the prompt asks for the list, in any of the phrasings actually observed
#   2. it has been REMIND_AFTER turns since the table was last rendered AND
#      open tasks exist, in which case it nudges rather than injecting 40 lines
#
# Mute: touch ~/.claude/.no-task-table-inject   (machine-wide until removed)
set -uo pipefail
export PATH="/opt/homebrew/bin:$PATH"

[ -f "$HOME/.claude/.no-task-table-inject" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null) || exit 0
PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // .user_prompt // .message // empty' 2>/dev/null)
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$PROMPT" ] || exit 0

# Never fire on machine traffic. A task-notification or a system reminder is not
# the owner asking for anything.
case "$PROMPT" in
  '<task-notification'*|'[SYSTEM'*|'Caveat:'*|'<local-command'*) exit 0 ;;
esac

TABLE="$HOME/.claude/scripts/task-table/task-table.sh"
[ -x "$TABLE" ] || exit 0

SID8="${SID:0:8}"
STATE="/tmp/claude-task-table-${SID8:-unknown}"
REMIND_AFTER=12

# The phrasings are taken from the owner's actual asks, 2026-08-13 to 08-15,
# rather than invented. Add to this list from observed misses, never from guesses.
ASKED=0
printf '%s' "$PROMPT" | rg -qi \
  'task list|tasklist|todo list|task table|show me all|list again|show me the (queue|list)|entire task|full (task|todo)|what.s (left|next|pending)|remaining tasks|show.*statuses' \
  2>/dev/null && ASKED=1

if [ "$ASKED" = "1" ]; then
  # The script REFUSES (exit 4) rather than guessing which store is ours, since
  # there is no reliable live-session-to-store mapping and a confident wrong
  # table is the defect this whole thing exists to prevent. On a refusal, pass
  # the refusal THROUGH to the agent: the owner asked for the list, so silence
  # is not an acceptable answer. The agent identifies its store and pins it once.
  RENDERED=$("$TABLE" 2>/dev/null)
  rc=$?
  if [ "$rc" -ne 0 ] || [ -z "$RENDERED" ]; then
    REFUSAL=$("$TABLE" 2>&1 >/dev/null)
    [ -n "$REFUSAL" ] || exit 0
    MSG=$(printf 'The owner asked for the task list and the renderer REFUSED to guess which task store is theirs. Do not answer from memory and do not skip it.\n\nIdentify the store by its task subjects below, pin it once, then render:\n  bash ~/.claude/scripts/task-table/task-table.sh --pin <sid8>\n\n%s' "$REFUSAL")
    jq -n --arg c "$MSG" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:$c}}'
    exit 0
  fi
  date +%s > "$STATE" 2>/dev/null || true
  MSG=$(printf 'The owner asked for the task list. Open your reply with the table, inside a code fence, before any prose.\n\nTHE FACTS COME FROM THIS BASELINE. THE PRESENTATION IS YOURS.\nNever re-render from your own memory of the task list; that was the original defect. But the baseline is a floor, not a ceiling: add a context column when THIS queue needs one, and drop back to the baseline when it does not. The vocabulary and the bar each optional column must clear are in skills/tasks/SKILL.md. Do not add a model-tier column unless the queue genuinely mixes planning-grade judgment with straight execution.\n\nCHECK THE HEADER BEFORE YOU SHOW IT. Trusting this data over your memory is right for the CONTENT and is not a reason to skip the sanity check. Does the session id match the store you meant, are the counts near what this session has been doing, do you recognise the task names? If the header disagrees with your expectation, resolve it before rendering. A confident table about another session considered as this one is the worst outcome available.\n\nDereference anything a stranger could not parse. A bare task number, proposal id, or disposition code earns a one-line gloss; run task-table.sh --refs for the resolved set.\n\nSize is the owner ruling of 2026-08-13: width is free, height stays within 44 lines, truncation is loud.\n\n%s' "$RENDERED")
  jq -n --arg c "$MSG" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:$c}}'
  exit 0
fi

# Second trigger: a periodic nudge, not a second copy of the table.
COUNT_FILE="${STATE}.turns"
prev=0; [ -f "$COUNT_FILE" ] && prev=$(cat "$COUNT_FILE" 2>/dev/null || echo 0)
case "$prev" in ''|*[!0-9]*) prev=0 ;; esac
next=$((prev + 1))
printf '%s' "$next" > "$COUNT_FILE" 2>/dev/null || true

if [ "$next" -ge "$REMIND_AFTER" ]; then
  DIGEST=$("$TABLE" --compact  2>/dev/null) || exit 0
  [ -n "$DIGEST" ] || exit 0
  printf '0' > "$COUNT_FILE" 2>/dev/null || true
  MSG=$(printf 'It has been %s turns since the task table was last shown, and the owner has asked for it repeatedly across sessions. If this turn touches task state, close your reply with the full table (bash ~/.claude/scripts/task-table/task-table.sh). Current state:\n\n%s' "$REMIND_AFTER" "$DIGEST")
  jq -n --arg c "$MSG" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:$c}}'
fi
exit 0
