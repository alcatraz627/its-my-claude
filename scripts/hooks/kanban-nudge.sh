#!/usr/bin/env bash
# Tells an agent working in a project that its owner has asks waiting on the
# board, once per session, and then gets out of the way.
#
# The corpus behind this: 241 cards, 15 notes, not one ever picked up. The write
# side worked and the pickup side did not, so writing to the board taught the
# owner that writing to the board changes nothing. The session-start line names
# unsorted asks, but a session that starts before the owner writes never sees it.
# This is the mid-session half of that signal.
#
# Owner ruling 2026-08-17, on how it must behave: "the nudge being just an inform,
# stressing the importance but allowing the agent to decide". So it is advisory,
# never a gate, and it rides the same PostToolUse channel the task-tool nudge
# uses. It is heed-instrumented for the same reason that one is: an advisory
# whose fire and heed rates are unknown cannot be tuned, only argued about.
#
# Runtime contract: reads the PostToolUse payload on stdin (needs .session_id and
# .cwd). Fires at most once per session. Always exits 0.
#
# The additionalContext envelope must be the documented
# {hookSpecificOutput:{hookEventName,additionalContext}} shape. A bare top-level
# {additionalContext} is silently ignored by the harness, with no error and no
# --debug signal; no-task-nudge.sh shipped that way and reached nobody for weeks
# (assets/reports/20260713-hook-envelope/).

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$cwd" ] || exit 0

[ -f "$HOME/.claude/.no-kanban-nudge" ] && exit 0

SENT="/tmp/claude-kanban-nudged-${sid:0:8}"
[ -f "$SENT" ] && exit 0

KROOT="${KANBAN_ROOT:-$HOME/.claude/kanban}"
REG="$KROOT/registry.json"
ITEMS="$KROOT/items.json"
LANDINGS="$KROOT/landings.json"
[ -f "$REG" ] && [ -f "$ITEMS" ] || exit 0

# Which board owns this cwd. No board here means nothing to nudge about.
slug=$(jq -r --arg cwd "$cwd" '
  .boards | to_entries[]
  | .value.root as $r
  | select(($cwd == $r) or ($cwd | startswith($r + "/")))
  | .key' "$REG" 2>/dev/null | head -1)
[ -n "$slug" ] || exit 0
name=$(jq -r --arg s "$slug" '.boards[$s].name // $s' "$REG" 2>/dev/null)

# Unsorted asks visible on this board. Mirrors displayScope() in lib.ts and the
# same jq in session-start-line.sh — keep all three in sync; a lib.ts change does
# NOT reach here and no suite can catch the drift, because each is tested alone.
counts=$(jq -r --slurpfile L <(cat "$LANDINGS" 2>/dev/null || echo '{"landings":{}}') --arg slug "$slug" '
  def scope: if ((.boards // []) | length) > 0 then .boards elif .slug then [.slug] else null end;
  def here: (scope == null) or (scope | index($slug) != null);
  ($L[0].landings // {}) as $done
  | [ .items[]? | select($done[.id] == null) | select(here) ] as $vis
  | [ ($vis | length),
      ([ $vis[] | select(.starred == true) ]  | length),
      ([ $vis[] | select(.triggered != null) ] | length) ]
  | @tsv' "$ITEMS" 2>/dev/null)
# A store that will not parse is not an empty queue. Say so rather than going
# quiet, which is the exact failure the adversarial review found in the readers.
if [ $? -ne 0 ] || [ -z "$counts" ]; then
  : > "$SENT"
  jq -nc --arg c "[kanban] The owner's asks on board \"$name\" could not be read ($ITEMS will not parse), so I cannot tell you whether any are waiting. Worth a look before you assume there is nothing: bash ~/.claude/scripts/kanban/kanban.sh items" \
    '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
  exit 0
fi

total=$(printf '%s' "$counts" | cut -f1)
starred=$(printf '%s' "$counts" | cut -f2)
queued=$(printf '%s' "$counts" | cut -f3)
[ "${total:-0}" -gt 0 ] 2>/dev/null || exit 0

: > "$SENT"

extra=""
[ "${starred:-0}" -gt 0 ] 2>/dev/null && extra="$extra, $starred starred"
[ "${queued:-0}" -gt 0 ] 2>/dev/null && extra="$extra, $queued queued for now"

line="[kanban] The owner has $total unsorted ask(s) on board \"$name\"$extra. They write these without classifying them, and sorting is the agent's job: read them with 'bash ~/.claude/scripts/kanban/kanban.sh items', then record what you did with 'kanban.sh classify <item-id> <task|subtask|clarification|remark> [--card <id>]'. This is an inform, not a gate. Finish what you are doing first if that is the right call."

# Arm the heed marker AFTER deciding to fire, and baseline on the count rather
# than on zero: sorting two of five asks is a heed, not a miss.
HEED_BASELINE="$total" bash "$HOME/.claude/scripts/hooks/heed-writeback.sh" arm \
  kanban-nudge kanban-asks-sorted "$slug" "$sid" >/dev/null 2>&1 || true

jq -nc --arg c "$line" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
exit 0
