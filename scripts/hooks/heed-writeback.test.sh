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
# stop <root> <sid> — a Stop feeds the real payload shape, because resolve reads
# .session_id from it to decide whose markers it may judge. Passing a bare newline
# here (the first cut) makes every case exercise the no-session branch, which is
# not a shape production ever sees.
stop()  { printf '{"session_id":"%s"}' "$2" \
            | TMPDIR="$1/" HOME="$1/home" WARN_LOG_STORE="$1/warn.jsonl" bash heed-writeback.sh resolve; }
store() { printf '%s/home/.claude/tasks/session-%s' "$1" "${2:0:8}"; }

heed_for() {
  [ -f "$1/warn.jsonl" ] || { echo none; return; }
  jq -r --arg r "$2" 'select(.kind=="heed" and .ref==$r) | .heeded' "$1/warn.jsonl" 2>/dev/null \
    | tail -1 | grep . || echo none
}

echo "== heeded: tasks appear before the window closes =="
T=$(setup); S=aaa11111
armed "$T" "$S"; mkdir -p "$(store "$T" "$S")"; echo '{}' > "$(store "$T" "$S")/1.json"
stop "$T" "$S"
[ "$(heed_for "$T" "no-task-nudge:$S")" = true ] \
  && ok "writes heeded=true when the store gains a task" \
  || bad "expected true, got $(heed_for "$T" "no-task-nudge:$S")"

echo "== unheeded: store still empty when the window closes =="
T=$(setup); S=bbb22222
armed "$T" "$S"; for _ in 1 2 3; do stop "$T" "$S"; done
[ "$(heed_for "$T" "no-task-nudge:$S")" = false ] \
  && ok "writes heeded=false after the grace window" \
  || bad "expected false, got $(heed_for "$T" "no-task-nudge:$S")"

echo "== the grace window is real: no verdict before it closes =="
T=$(setup); S=ccc33333
armed "$T" "$S"; for _ in 1 2; do stop "$T" "$S"; done
[ "$(heed_for "$T" "no-task-nudge:$S")" = none ] \
  && ok "silent at stop 2 of 3 (an empty store is not yet a miss)" \
  || bad "scored a verdict inside the grace window"

echo "== a late create still counts =="
T=$(setup); S=ddd44444
armed "$T" "$S"; stop "$T" "$S"
mkdir -p "$(store "$T" "$S")"; echo '{}' > "$(store "$T" "$S")/7.json"
stop "$T" "$S"
[ "$(heed_for "$T" "no-task-nudge:$S")" = true ] \
  && ok "a task created after the first Stop is still credited" \
  || bad "late create was not credited"

echo "== highwatermark counts, because the store reaps completed tasks =="
T=$(setup); S=eee55555
armed "$T" "$S"; mkdir -p "$(store "$T" "$S")"; echo '4' > "$(store "$T" "$S")/.highwatermark"
for _ in 1 2 3; do stop "$T" "$S"; done
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
stop "$T" "$S"
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
stop "$T" sk111111
[ "$(heed_for "$T" 'persona-suggest:sk111111')" = true ] \
  && ok "adopting the suggested persona records heeded=true" \
  || bad "adoption not credited"

T=$(setup); armp "$T" skeptical-reviewer sk222222
for _ in 1 2 3; do stop "$T" sk222222; done
[ "$(heed_for "$T" 'persona-suggest:sk222222')" = false ] \
  && ok "no adoption within the window records heeded=false" \
  || bad "expected false, got $(heed_for "$T" 'persona-suggest:sk222222')"

T=$(setup); armp "$T" skeptical-reviewer sk333333
adopt "$T" art-director
for _ in 1 2 3; do stop "$T" sk333333; done
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
for _ in 1 2 3; do stop "$T" sk444444; done
[ "$(heed_for "$T" 'persona-suggest:sk444444')" = false ] \
  && ok "a PRE-EXISTING adoption does not count, even once the log grows" \
  || bad "scored a heed off a line that predates the suggestion"

echo "== arm is idempotent: a re-fire does not reset the window =="
T=$(setup); S=ggg77777
armed "$T" "$S"; stop "$T" "$S"; armed "$T" "$S"
n=$(grep -c '^stops=1$' "$T/claude-heed-no-task-nudge-$S" 2>/dev/null || echo 0)
[ "$n" = 1 ] && ok "re-arming leaves the existing marker and its stop count alone" \
             || bad "re-arm clobbered the window (stops reset)"

echo "== the mute is honoured =="
T=$(setup); S=hhh88888
armed "$T" "$S"; mkdir -p "$(store "$T" "$S")"; echo '{}' > "$(store "$T" "$S")/1.json"
MUTE="$T/home/.claude/.no-heed-writeback"; touch "$MUTE"
stop "$T" "$S"
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

echo "== a session judges only its own markers =="
# The live failure this pins: 130 markers from other sessions sat in one TMPDIR.
# Letting any Stop run their window down manufactures a miss the armed session
# never earned, and persona-adopted reads a GLOBAL log, so another session's
# adoption would have been credited to this untouched suggestion.
T=$(setup); MINE=mmm11111; THEIRS=ttt22222
armed "$T" "$MINE"; armed "$T" "$THEIRS"
for _ in 1 2 3 4; do stop "$T" "$MINE"; done
[ "$(heed_for "$T" "no-task-nudge:$MINE")" = false ] \
  && ok "my own marker still reaches a verdict" \
  || bad "own-session marker was not judged"
[ "$(heed_for "$T" "no-task-nudge:$THEIRS")" = none ] \
  && ok "another session's marker is left untouched" \
  || bad "scored a verdict on a marker this session never armed"
[ -f "$T/claude-heed-no-task-nudge-$THEIRS" ] \
  && ok "and is left in place, not deleted — that session may still return" \
  || bad "deleted another session's pending marker"

echo "== a marker whose session never returns is reaped, not scored =="
# Runs PAST the grace window on purpose. One Stop would leave the no-ledger-line
# assertion vacuously true — it would also pass with reaping deleted entirely,
# because nothing reaches MAX_STOPS in a single Stop. Four Stops make the negative
# assertion able to fail: without the reap, this marker scores heeded=false.
T=$(setup); S=rrr33333
armed "$T" "$S"
touch -t 202601010000 "$T/claude-heed-no-task-nudge-$S"   # far past the reap window
for _ in 1 2 3 4; do stop "$T" "$S"; done
[ ! -f "$T/claude-heed-no-task-nudge-$S" ] \
  && ok "an aged-out marker is removed" \
  || bad "aged-out marker survived the reap"
[ "$(heed_for "$T" "no-task-nudge:$S")" = none ] \
  && ok "and writes NO ledger line — an unscored fire, not a fabricated miss" \
  || bad "reaping wrote a verdict: $(heed_for "$T" "no-task-nudge:$S")"

echo "== the reap window does not eat a live marker =="
T=$(setup); S=sss44444
armed "$T" "$S"; stop "$T" "$S"
[ -f "$T/claude-heed-no-task-nudge-$S" ] \
  && ok "a fresh marker survives a Stop" \
  || bad "reaped a marker armed moments ago"

# ── rows below pin findings from the 2026-08-18 adversarial gate ────────────
# Each one stayed green before its fix, which is the only reason it is here.

echo "== a half-written marker is left alone, not deleted =="
# arm() is not atomic in the naive form, so another session's Stop can glob a
# marker mid-write. The first cut deleted anything that failed to parse, BEFORE
# checking whose it was — destroying a live session's instrumentation with no
# ledger trace and no way to notice.
T=$(setup)
printf 'hook=no-task-nudge\nsid=other111\n' > "$T/claude-heed-no-task-nudge-other111"
stop "$T" myown123
[ -f "$T/claude-heed-no-task-nudge-other111" ] \
  && ok "an unparseable foreign marker survives an unrelated session's Stop" \
  || bad "deleted a torn marker belonging to another session"

echo "== a corrupt highwatermark is not laundered into a heed =="
# tr -dc '0-9' strips the sign, so "-5" arrived as 5 and scored a heed for tasks
# that never existed.
T=$(setup); S=hwneg001
armed "$T" "$S"; mkdir -p "$(store "$T" "$S")"
echo '-5' > "$(store "$T" "$S")/.highwatermark"
stop "$T" "$S"
[ "$(heed_for "$T" "no-task-nudge:$S")" = none ] \
  && ok "a negative highwatermark scores nothing" \
  || bad "a negative highwatermark scored $(heed_for "$T" "no-task-nudge:$S")"

T=$(setup); S=hwjunk01
armed "$T" "$S"; mkdir -p "$(store "$T" "$S")"
printf 'not-a-number\n' > "$(store "$T" "$S")/.highwatermark"
stop "$T" "$S"
[ "$(heed_for "$T" "no-task-nudge:$S")" = none ] \
  && ok "a non-numeric highwatermark scores nothing" \
  || bad "junk in .highwatermark scored a verdict"

echo "== a rotated persona log reads unknown, never a miss =="
# The shrunk-log guard had zero coverage: mutating it away left all 23 rows green.
# Without it, tail past the end of a truncated file prints nothing and the check
# says "no" — a fabricated miss, which is the exact corruption this file exists
# to prevent.
T=$(setup)
mkdir -p "$T/home/.claude/personas/usage"
for i in 1 2 3 4 5; do printf '{"persona":"filler"}\n'; done > "$T/home/.claude/personas/usage/events.jsonl"
TMPDIR="$T/" HOME="$T/home" bash heed-writeback.sh arm persona-suggest persona-adopted skeptical-reviewer rot11111
printf '{"persona":"filler"}\n' > "$T/home/.claude/personas/usage/events.jsonl"   # rotated: 5 lines -> 1
for _ in 1 2 3 4; do stop "$T" rot11111; done
[ "$(heed_for "$T" 'persona-suggest:rot11111')" = none ] \
  && ok "a log that shrank below the baseline yields no verdict at all" \
  || bad "a rotated log scored $(heed_for "$T" 'persona-suggest:rot11111')"

echo "== HEED_REAP_HOURS cannot be set to something that eats live markers =="
# find -mmin +<negative> is true for every file, so -1 or 0 wiped every marker on
# the next Stop, silently and with no ledger line.
# Sids are exactly 8 chars: arm() names the marker ${hook}-${sid:0:8}, so a longer
# sid here makes the assertion look for a file that was never going to exist and
# the row fails for a reason that has nothing to do with the code under test.
i=0
for bad_val in -1 0 abc 2.5 ''; do
  i=$((i+1)); T=$(setup); S="reapv00$i"
  armed "$T" "$S"
  # env, not a bare assignment prefix: prefixing a shell FUNCTION does not export
  # the variable to the script the function then runs, so the whole row would test
  # the default value and pass no matter what the code does.
  printf '{"session_id":"%s"}' "$S" \
    | env HEED_REAP_HOURS="$bad_val" TMPDIR="$T/" HOME="$T/home" \
          WARN_LOG_STORE="$T/warn.jsonl" bash heed-writeback.sh resolve
  [ -f "$T/claude-heed-no-task-nudge-$S" ] \
    && ok "HEED_REAP_HOURS='$bad_val' falls back to the default; marker survives" \
    || bad "HEED_REAP_HOURS='$bad_val' reaped a marker armed one second ago"
done

echo "== ownership is decided on the full session id, not an 8-char prefix =="
# Two different sessions can share the first 8 hex chars. Comparing prefixes let
# one resolve and delete the other's marker, filing the verdict under a session
# that never saw the nudge.
T=$(setup)
A=deadbeef-aaaa-4aaa-8aaa-aaaaaaaaaaaa
B=deadbeef-bbbb-4bbb-8bbb-bbbbbbbbbbbb
TMPDIR="$T/" HOME="$T/home" bash heed-writeback.sh arm no-task-nudge task-store-nonempty "$A" "$A"
for _ in 1 2 3 4; do stop "$T" "$B"; done
[ "$(heed_for "$T" "no-task-nudge:deadbeef")" = none ] \
  && ok "a prefix-sharing session writes no verdict for a marker it never armed" \
  || bad "prefix collision produced a verdict: $(heed_for "$T" "no-task-nudge:deadbeef")"
[ -f "$T/claude-heed-no-task-nudge-deadbeef" ] \
  && ok "and leaves the marker in place for its real owner" \
  || bad "prefix-sharing session deleted another session's marker"

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
