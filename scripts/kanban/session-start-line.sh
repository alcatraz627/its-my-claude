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
[ -n "$match" ] || exit 0

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
