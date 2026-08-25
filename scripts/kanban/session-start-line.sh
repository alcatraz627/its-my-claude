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

KROOT="${KANBAN_ROOT:-$HOME/.claude/kanban}"
REG="$KROOT/registry.json"
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
  [ -f "$KROOT/.no-offer" ] && exit 0
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
bdir="$KROOT/boards/$slug"

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

# The owner's own asks, unsorted. An item with no landing has never been read
# by any agent, which is the state this line exists to break. Unassigned items
# count too: they belong to no board yet and any agent may route them.
#
# This re-implements pendingItems() from lib.ts in jq, the same way the note-tag
# regexes are mirrored here, so the line still works with no bun and no server.
# Keep both definitions of "pending" in sync: a lib.ts change does NOT reach here
# and the suite cannot catch the drift, because each side is tested on its own.
ITEMS="$KROOT/items.json"
LANDINGS="$KROOT/landings.json"
mine=0; loose=0; starred=0; queued=0; broken=""
if [ -f "$ITEMS" ]; then
  # A parse failure must NOT collapse to zero: an empty queue and an unreadable
  # one produce the same silence, and silence reads as nothing to report. So the
  # jq exit status is checked and reported instead of swallowed.
  icounts=$(jq -r --slurpfile L <(cat "$LANDINGS" 2>/dev/null || echo '{"landings":{}}') --arg slug "$slug" '
    # mirrors displayScope() in lib.ts: explicit tags win, else the origin
    # board scopes it, else it shows everywhere (null)
    def scope: if ((.boards // []) | length) > 0 then .boards elif .slug then [.slug] else null end;
    def here: (scope == null) or (scope | index($slug) != null);
    ($L[0].landings // {}) as $done
    | [ .items[]? | select($done[.id] == null) ] as $pending
    | [ $pending[] | select(here) ] as $vis
    | [ ([ $vis[] | select(scope != null) ] | length),
        ([ $vis[] | select(scope == null) ] | length),
        ([ $vis[] | select(.starred == true) ] | length),
        ([ $vis[] | select(.triggered != null) ] | length) ]
    | @tsv' "$ITEMS" 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$icounts" ]; then
    broken="yes"
  else
    mine=$(printf '%s' "$icounts" | cut -f1); loose=$(printf '%s' "$icounts" | cut -f2)
    starred=$(printf '%s' "$icounts" | cut -f3); queued=$(printf '%s' "$icounts" | cut -f4)
  fi
fi
asks=""
if [ -n "$broken" ]; then
  asks=" · WARNING: the owner's asks could not be read ($ITEMS will not parse), so this line cannot tell you whether any are waiting. Check it before assuming there is nothing to do."
elif [ "${mine:-0}" -gt 0 ] 2>/dev/null || [ "${loose:-0}" -gt 0 ] 2>/dev/null; then
  bits="$mine here"; [ "${loose:-0}" -gt 0 ] 2>/dev/null && bits="$bits, $loose unassigned"
  [ "${starred:-0}" -gt 0 ] 2>/dev/null && bits="$bits, $starred starred"
  # queued = the owner clicked "now" and expects pickup ahead of the next sweep
  [ "${queued:-0}" -gt 0 ] 2>/dev/null && bits="$bits, $queued QUEUED FOR NOW"
  asks=" · the owner has unsorted asks ($bits). Read and sort them: bash ~/.claude/scripts/kanban/kanban.sh items"
fi

# The owner's selection: cards/notes they have ticked in the UI as "this is what
# I mean". Read straight from the file so this line needs no bun and no server.
picked=""
SELF="$bdir/selection.json"
if [ -f "$SELF" ]; then
  scounts=$(jq -r '[ (.cards // [] | length), (.notes // [] | length) ] | @tsv' "$SELF" 2>/dev/null || printf '0\t0')
  scards=${scounts%%$'\t'*}; snotes=${scounts#*$'\t'}
  if [ "${scards:-0}" -gt 0 ] 2>/dev/null || [ "${snotes:-0}" -gt 0 ] 2>/dev/null; then
    picked=" · the owner has SELECTED ${scards:-0} card(s) and ${snotes:-0} note(s) — that is their working set: bash ~/.claude/scripts/kanban/kanban.sh selected"
  fi
fi

# The owner's drafts. A draft is the rung above an ask: a document they sat down
# and wrote, so it is worth reading before planning, and "Offer to a session" is
# them asking for pickup now. Nothing surfaced this before, so offering a draft
# lit the button up and reached no one.
#
# The pending rule mirrors isPulled() + pendingDrafts() in lib.ts and must stay in
# step with them. test-drafts.sh section 11 pins the two against one fixture, so
# the drift is caught rather than merely warned about.
DRAFTSF="$KROOT/drafts.json"
PULLSF="$KROOT/pulls.json"
dpend=0; doffer=0; dagent=0; dbroken=""
if [ -f "$DRAFTSF" ]; then
  # Timestamps compare as strings on purpose: these are all Date.toISOString(),
  # so they are same-format UTC and sort correctly, while jq's fromdateiso8601
  # rejects the fractional seconds every one of them carries.
  dcounts=$(jq -r --slurpfile P <(cat "$PULLSF" 2>/dev/null || echo '{"pulls":{}}') --arg slug "$slug" '
    ($P[0].pulls // {}) as $pulls
    | [ .drafts[]?
        | select((.isTemplate // false) | not)
        | . as $d
        | ($pulls[$d.id].at // null) as $taken
        | ([($d.updatedAt // ""), ($d.triggered // "")] | max) as $touched
        # no pull, or one the owner has outdated by editing or re-offering
        | select($taken == null or $touched > $taken)
      ] as $live
    # mirrors visibleTo() in lib.ts. This hook cannot resolve an agent alias: it
    # runs at SessionStart, BEFORE the session registers with the ipc broker, so
    # the answer would be "no" for every agent-addressed draft including the ones
    # meant for this reader. So it counts what it can see and reports the rest as
    # a separate number, which sends the reader to the CLI, where the alias does
    # resolve. A wrong count is worse here than an honest partial one.
    | [ $live[] | select((.to // []) | length == 0)
                 | select((.slug // null) == null or .slug == $slug) ] as $mine
    | [ $live[] | select([ (.to // [])[] | select(startswith("board:")) ]
                         | index("board:" + $slug) != null) ] as $forboard
    | ($mine + $forboard | unique_by(.id)) as $pending
    | [ $live[] | select([ (.to // [])[] | select(startswith("agent:")) ] | length > 0) ] as $foragent
    | [ ($pending | length),
        ([ $pending[] | select(.triggered != null) ] | length),
        ($foragent | length) ]
    | @tsv' "$DRAFTSF" 2>/dev/null)
  # Same rule as the asks above: an unreadable store must not read as an empty one.
  if [ $? -ne 0 ] || [ -z "$dcounts" ]; then
    dbroken="yes"
  else
    dpend=$(printf '%s' "$dcounts" | cut -f1); doffer=$(printf '%s' "$dcounts" | cut -f2)
    dagent=$(printf '%s' "$dcounts" | cut -f3)
  fi
fi
drafted=""
if [ -n "$dbroken" ]; then
  drafted=" · WARNING: the owner's drafts could not be read ($DRAFTSF will not parse), so this line cannot tell you whether any are waiting."
elif [ "${dpend:-0}" -gt 0 ] 2>/dev/null || [ "${dagent:-0}" -gt 0 ] 2>/dev/null; then
  dbits="$dpend waiting"
  [ "${doffer:-0}" -gt 0 ] 2>/dev/null && dbits="$dbits, $doffer OFFERED TO A SESSION"
  [ "${dagent:-0}" -gt 0 ] 2>/dev/null && dbits="$dbits, $dagent addressed to a named agent (this line cannot tell whether that is you — the CLI can)"
  drafted=" · the owner has drafts ($dbits) — documents they wrote for you, above an ask. Read before planning: bash ~/.claude/scripts/kanban/kanban.sh drafts"
fi

# D9a: a decision waiting on the owner is attention the same way an unread note
# is, so the agent's own line says it rather than only the board showing it.
decided=""
pending_dec=$(python3 - "$slug" <<'PYD' 2>/dev/null || echo 0
import json, os, sys
slug = sys.argv[1]
n = 0
try:
    plan = json.load(open(os.path.expanduser(f"~/.claude/kanban/boards/{slug}/plan.json")))
    n += sum(1 for d in (plan.get("decisions") or []) if not d.get("answer"))
except Exception:
    pass
try:
    reg = os.path.expanduser("~/.claude/assets/decision-pages")
    pend = set()
    try:
        pend = {l.strip() for l in open(os.path.join(reg, ".pending.txt")) if l.strip()}
    except Exception:
        pass
    for s in pend:
        try:
            c = json.load(open(os.path.join(reg, s, "config.json")))
        except Exception:
            continue
        if (c.get("origin") or {}).get("board") == slug:
            n += 1
except Exception:
    pass
print(n)
PYD
)
if [ "${pending_dec:-0}" -gt 0 ] 2>/dev/null; then
  decided=" · $pending_dec decision(s) waiting on the owner: bash ~/.claude/scripts/kanban/kanban.sh decide list"
fi

if [ "${unread:-0}" -gt 0 ] 2>/dev/null; then
  extra=""; [ "${actionable:-0}" -gt 0 ] 2>/dev/null && extra=" ($actionable marked !now)"
  line="[kanban] board \"$name\" — $unread unread human note(s)$extra. Pull them before working: bash ~/.claude/scripts/kanban/kanban.sh notes --unread --ack$asks$picked$drafted$decided · board: http://localhost:5106/b/$slug"
else
  line="[kanban] board \"$name\" — no unread notes$asks$picked$drafted$decided · sync: bash ~/.claude/scripts/kanban/kanban.sh sync · board: http://localhost:5106/b/$slug"
fi

jq -nc --arg c "$line" '{additionalContext: $c}'
exit 0
