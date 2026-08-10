#!/usr/bin/env bash
# One session-start line for projects that have a kanban board: board name +
# unread human-note count, so the agent (the primary reader) knows to pull
# notes before working. Silent in projects with no board.
#
# Runs in the synchronous SessionStart injection lane (sessionstart-inject.sh):
# reads the SessionStart payload on stdin, prints {additionalContext} or
# nothing. Pure file reads (registry.json / notes.json / ack.json) — no server,
# no bun, so it stays sub-100ms and works while the board server is down.
# Unread definition mirrors cli.ts: note.updatedAt (ms) > ack.lastAckTs (ms).

set -uo pipefail
command -v jq >/dev/null 2>&1 || exit 0

REG="$HOME/.claude/kanban/registry.json"
[ -f "$REG" ] || exit 0

cwd=$(cat 2>/dev/null | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] || exit 0

match=$(jq -r --arg cwd "$cwd" '
  .boards | to_entries[]
  | .value.root as $r
  | select(($cwd == $r) or ($cwd | startswith($r + "/")))
  | [.key, .value.name] | @tsv' "$REG" 2>/dev/null | head -1)
# No board here. A board is for user communication across a whole project, so
# offer one only where the project has already outlived a session, and never on
# the strength of one session's todo count (features/kanban.md).
if [ -z "$match" ]; then
  [ -f "$HOME/.claude/kanban/.no-offer" ] && exit 0
  [ -f "$cwd/.claude/kanban-declined" ] && exit 0
  prior=0
  # a checkpoint here means an earlier session meant to hand work forward
  [ -f "$HOME/.claude/checkpoints/index.jsonl" ] && prior=$(jq -r --arg c "$cwd" \
    'select(.project_root == $c) | .project_root' "$HOME/.claude/checkpoints/index.jsonl" 2>/dev/null | wc -l | tr -d ' ')
  # or several sessions have kept notes here
  notes_dir="$cwd/.claude/session-notes"
  [ -d "$notes_dir" ] && sessions=$(find "$notes_dir/" -name '*.md' ! -name '_active.md' 2>/dev/null | wc -l | tr -d ' ') || sessions=0
  if [ "${prior:-0}" -ge 1 ] 2>/dev/null || [ "${sessions:-0}" -ge 2 ] 2>/dev/null; then
    why="this project has carried work across sessions"
    printf '{"additionalContext":"%s"}\n' \
      "[kanban] No board here, and $why. A board is the human's view of a project across sessions and agents; offer one if the work continues: bash ~/.claude/scripts/kanban/kanban.sh init · never offer here: touch $cwd/.claude/kanban-declined"
  fi
  exit 0
fi

slug=${match%%$'\t'*}
name=${match#*$'\t'}
bdir="$HOME/.claude/kanban/boards/$slug"

ack_ms=$(jq -r '.lastAckTs // 0' "$bdir/ack.json" 2>/dev/null || echo 0)
# @me self-notes never nag the agent; !now marks actionable. Minimal mirror of
# lib.ts parseNoteTags — keep the token regexes in sync.
counts=$(jq -r --argjson ack "${ack_ms:-0}" '
  [ to_entries[]
    | select(.value.note != null and .value.note != "")
    | select(.value.note | test("(^|[\\s(])@me([\\s).,;:]|$)"; "i") | not)
    | select((.value.updatedAt | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601 * 1000) > $ack) ]
  | [ length, ([ .[] | select(.value.note | test("(^|[\\s(])!now([\\s).,;:]|$)"; "i")) ] | length) ]
  | @tsv' "$bdir/notes.json" 2>/dev/null || printf '0\t0')
unread=${counts%%$'\t'*}
actionable=${counts#*$'\t'}

if [ "${unread:-0}" -gt 0 ] 2>/dev/null; then
  extra=""; [ "${actionable:-0}" -gt 0 ] 2>/dev/null && extra=" ($actionable marked !now)"
  line="[kanban] board \"$name\" — $unread unread human note(s)$extra. Pull them before working: bash ~/.claude/scripts/kanban/kanban.sh notes --unread --ack · board: http://localhost:5106/b/$slug"
else
  line="[kanban] board \"$name\" — no unread notes · sync: bash ~/.claude/scripts/kanban/kanban.sh sync · board: http://localhost:5106/b/$slug"
fi

jq -nc --arg c "$line" '{additionalContext: $c}'
exit 0
