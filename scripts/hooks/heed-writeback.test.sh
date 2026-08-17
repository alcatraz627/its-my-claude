#!/usr/bin/env bash
# Tests for heed-writeback.sh (task #41 / D15).
#
# Asserts the LEDGER LINE, not the marker's absence. A marker disappears on both
# outcomes and on a parse failure, so "the marker is gone" is a negative check
# that is vacuously true when nothing worked. Every case reads the kind:heed
# record back out of the ledger and checks its heeded value and ref.
#
# Cases run under a throwaway HOME, because the check resolves the task store
# from $HOME at check time rather than from a path captured at arm time.

set -uo pipefail
cd "$(dirname "$0")" || exit 1

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok   $1"; }
bad() { fail=$((fail+1)); echo "  FAIL $1"; }

# The throwaway HOME needs a real warn-log.sh, because heed-writeback resolves it
# under $HOME. Copy the actual script rather than stubbing it, so these cases
# exercise the same writer production uses.
setup() {
  local t; t=$(mktemp -d)
  mkdir -p "$t/home/.claude/tasks" "$t/home/.claude/scripts/hooks"
  cp warn-log.sh "$t/home/.claude/scripts/hooks/" 2>/dev/null || true
  printf '%s' "$t"
}
armed() { TMPDIR="$1/" HOME="$1/home" bash heed-writeback.sh arm no-task-nudge task-store-nonempty "$2" "$2"; }
stop()  { echo '' | TMPDIR="$1/" HOME="$1/home" WARN_LOG_STORE="$1/warn.jsonl" bash heed-writeback.sh resolve; }
store() { printf '%s/home/.claude/tasks/session-%s' "$1" "${2:0:8}"; }

heed_for() {
  [ -f "$1/warn.jsonl" ] || { echo none; return; }
  jq -r --arg r "$2" 'select(.kind=="heed" and .ref==$r) | .heeded' "$1/warn.jsonl" 2>/dev/null \
    | tail -1 | grep . || echo none
}

echo "== heeded: tasks appear before the window closes =="
T=$(setup); S=aaa11111
armed "$T" "$S"; mkdir -p "$(store "$T" "$S")"; echo '{}' > "$(store "$T" "$S")/1.json"
stop "$T"
[ "$(heed_for "$T" "no-task-nudge:$S")" = true ] \
  && ok "writes heeded=true when the store gains a task" \
  || bad "expected true, got $(heed_for "$T" "no-task-nudge:$S")"

echo "== unheeded: store still empty when the window closes =="
T=$(setup); S=bbb22222
armed "$T" "$S"; for _ in 1 2 3; do stop "$T"; done
[ "$(heed_for "$T" "no-task-nudge:$S")" = false ] \
  && ok "writes heeded=false after the grace window" \
  || bad "expected false, got $(heed_for "$T" "no-task-nudge:$S")"

echo "== the grace window is real: no verdict before it closes =="
T=$(setup); S=ccc33333
armed "$T" "$S"; for _ in 1 2; do stop "$T"; done
[ "$(heed_for "$T" "no-task-nudge:$S")" = none ] \
  && ok "silent at stop 2 of 3 (an empty store is not yet a miss)" \
  || bad "scored a verdict inside the grace window"

echo "== a late create still counts =="
T=$(setup); S=ddd44444
armed "$T" "$S"; stop "$T"
mkdir -p "$(store "$T" "$S")"; echo '{}' > "$(store "$T" "$S")/7.json"
stop "$T"
[ "$(heed_for "$T" "no-task-nudge:$S")" = true ] \
  && ok "a task created after the first Stop is still credited" \
  || bad "late create was not credited"

echo "== highwatermark counts, because the store reaps completed tasks =="
T=$(setup); S=eee55555
armed "$T" "$S"; mkdir -p "$(store "$T" "$S")"; echo '4' > "$(store "$T" "$S")/.highwatermark"
for _ in 1 2 3; do stop "$T"; done
[ "$(heed_for "$T" "no-task-nudge:$S")" = true ] \
  && ok "made tasks and finished them all reads as heeded" \
  || bad "nonzero highwatermark with zero *.json was scored a miss"

# REGRESSION, found 2026-08-16 by exercising the deployed path rather than the
# unit. The first cut passed the hook's $TASK_DIR into arm. At fire time the task
# list is empty by definition, so that variable holds the LEGACY bare-id fallback
# and never the session-<sid8> directory the store actually creates a moment
# later. The captured path would have read an empty directory for the rest of the
# session and scored a miss on every single fire. Passing the sid and resolving at
# check time is the fix; this row is what pins it.
echo "== the store did not exist at arm time (the deployed shape) =="
T=$(setup); S=fff66666
armed "$T" "$S"                                    # nothing under tasks/ at all yet
mkdir -p "$(store "$T" "$S")"; echo '{}' > "$(store "$T" "$S")/1.json"
stop "$T"
[ "$(heed_for "$T" "no-task-nudge:$S")" = true ] \
  && ok "credits a store created AFTER the arm, under session-<sid8>" \
  || bad "armed against a stale path; the real store was never seen"

echo "== persona-adopted: the second check kind (task #31) =="
# armp <root> <persona> — arms against the fake HOME's persona usage log
armp() {
  mkdir -p "$1/home/.claude/personas/usage"
  touch "$1/home/.claude/personas/usage/events.jsonl"
  TMPDIR="$1/" HOME="$1/home" bash heed-writeback.sh arm persona-suggest persona-adopted "$2" "$3"
}
adopt() { printf '{"ts":"2026-08-16T00:00:00Z","persona":"%s"}\n' "$2" >> "$1/home/.claude/personas/usage/events.jsonl"; }

T=$(setup); armp "$T" skeptical-reviewer sk111111
adopt "$T" skeptical-reviewer
stop "$T"
[ "$(heed_for "$T" 'persona-suggest:sk111111')" = true ] \
  && ok "adopting the suggested persona records heeded=true" \
  || bad "adoption not credited"

T=$(setup); armp "$T" skeptical-reviewer sk222222
for _ in 1 2 3; do stop "$T"; done
[ "$(heed_for "$T" 'persona-suggest:sk222222')" = false ] \
  && ok "no adoption within the window records heeded=false" \
  || bad "expected false, got $(heed_for "$T" 'persona-suggest:sk222222')"

T=$(setup); armp "$T" skeptical-reviewer sk333333
adopt "$T" art-director
for _ in 1 2 3; do stop "$T"; done
[ "$(heed_for "$T" 'persona-suggest:sk333333')" = false ] \
  && ok "adopting a DIFFERENT persona is not a heed of this suggestion" \
  || bad "credited the wrong persona"

# The baseline is the whole point: a persona adopted BEFORE the suggestion must
# not count, or the metric reads healthy while measuring nothing.
#
# The log MUST grow after arming for this row to test anything. A first draft
# left it static, and the check's line-count-equality early exit answered "no"
# before the offset was ever used — so the row passed with the offset mutated
# away. Growing it with a DIFFERENT persona forces the comparison to run: the
# correct code reads only the new line and says no, while an offset-blind version
# finds the old matching line and says yes.
T=$(setup)
mkdir -p "$T/home/.claude/personas/usage"
printf '{"ts":"2026-08-01T00:00:00Z","persona":"skeptical-reviewer"}\n' > "$T/home/.claude/personas/usage/events.jsonl"
TMPDIR="$T/" HOME="$T/home" bash heed-writeback.sh arm persona-suggest persona-adopted skeptical-reviewer sk444444
adopt "$T" art-director
for _ in 1 2 3; do stop "$T"; done
[ "$(heed_for "$T" 'persona-suggest:sk444444')" = false ] \
  && ok "a PRE-EXISTING adoption does not count, even once the log grows" \
  || bad "scored a heed off a line that predates the suggestion"

echo "== arm is idempotent: a re-fire does not reset the window =="
T=$(setup); S=ggg77777
armed "$T" "$S"; stop "$T"; armed "$T" "$S"
n=$(grep -c '^stops=1$' "$T/claude-heed-no-task-nudge-$S" 2>/dev/null || echo 0)
[ "$n" = 1 ] && ok "re-arming leaves the existing marker and its stop count alone" \
             || bad "re-arm clobbered the window (stops reset)"

echo "== the mute is honoured =="
T=$(setup); S=hhh88888
armed "$T" "$S"; mkdir -p "$(store "$T" "$S")"; echo '{}' > "$(store "$T" "$S")/1.json"
MUTE="$T/home/.claude/.no-heed-writeback"; touch "$MUTE"
stop "$T"
[ "$(heed_for "$T" "no-task-nudge:$S")" = none ] \
  && ok "writes nothing while ~/.claude/.no-heed-writeback exists" \
  || bad "mute file did not stop the writeback"

echo "== kanban-asks-sorted: the third check kind (task #62) =="
# Heeded means the count went DOWN, not that it hit zero: sorting some of the
# owner's asks is acting on the nudge.
kchk() {
  KANBAN_ROOT="$1" bash -c '
source /dev/stdin <<EOF
$(sed -n "/^check_kanban_asks_sorted()/,/^}/p" '"$HOME"'/.claude/scripts/hooks/heed-writeback.sh)
EOF
check_kanban_asks_sorted "$1" "$2"' _ "$2" "$3"
}
K=$(mktemp -d "${TMPDIR:-/tmp}/heedkan-XXXXXX")
printf '{"items":[{"id":"a","body":"x","slug":"b1","createdAt":"2026-01-01T00:00:00Z","updatedAt":"2026-01-01T00:00:00Z"},{"id":"b","body":"y","slug":"b1","createdAt":"2026-01-01T00:00:00Z","updatedAt":"2026-01-01T00:00:00Z"}]}' > "$K/items.json"
echo '{"landings":{}}' > "$K/landings.json"
[ "$(kchk "$K" b1 2)" = no ]  && ok "an unchanged count is not a heed" \
                              || bad "an unchanged ask count scored a heed"
[ "$(kchk "$K" b1 4)" = yes ] && ok "a count that dropped reads as heeded" \
                              || bad "sorting asks did not register as a heed"
# An unassigned ask is visible on every board, so it counts toward each.
printf '{"items":[{"id":"c","body":"loose","createdAt":"2026-01-01T00:00:00Z","updatedAt":"2026-01-01T00:00:00Z"}]}' > "$K/items.json"
[ "$(kchk "$K" other-board 2)" = yes ] && ok "an untagged ask counts on a board it was not written on" \
                                       || bad "an untagged ask was invisible to another board's check"
# The load-bearing one: a broken store must never score a false heed.
printf '{"items": [ {"id":"a","body":"trun' > "$K/items.json"
[ "$(kchk "$K" b1 4)" = unknown ] && ok "a corrupt store is unknown, never a false heed" \
                                  || bad "a corrupt store scored $(kchk "$K" b1 4) instead of unknown"
[ "$(kchk "$K/gone" b1 4)" = unknown ] && ok "a missing store is unknown" \
                                       || bad "a missing store did not read as unknown"
rm -rf "$K"

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
