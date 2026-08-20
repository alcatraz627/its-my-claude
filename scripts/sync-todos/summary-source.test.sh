#!/usr/bin/env bash
# Tests that the stop-sync drift nudge counts from the STORE, not the replay
# (task #52).
#
# The defect was not a wrong store. resolve-store.sh was already returning the
# right one; its answer just never reached the summary, because TASK_DIR feeds
# only the elif branch that a live transcript skips. So the nudge counted
# replay_tasks.py's output, which reconstructs the list from THIS session's
# transcript and therefore sees only tasks TOUCHED since the clear.
#
# Both numbers were correct about different things and nothing said which:
# "3 pending, 11 done" against a real store of 6 open and 44 done. A summary
# labelled "Current:" reads as the whole queue, so an agent that trusts it goes
# hunting for 33 tasks it supposedly failed to record.

set -uo pipefail
cd "$(dirname "$0")" || exit 1

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok   $1"; }
bad() { fail=$((fail+1)); echo "  FAIL $1"; }

# Calls the REAL script the hook calls. An earlier version re-implemented this
# logic inline and therefore passed while stop-sync.sh was mutated to skip the
# store entirely: it pinned the arithmetic and not the wiring.
summarize() { bash ./summarize-store.sh "$1"; }

mkstore() {
  local t; t=$(mktemp -d); local i=0 k
  _n() {                          # _n <count> <status> <label>
    k=0
    while [ "$k" -lt "$1" ]; do
      i=$((i+1)); k=$((k+1))
      printf '{"id":"%s","subject":"%s %s","status":"%s"}' "$i" "$3" "$i" "$2" > "$t/$i.json"
    done
  }
  _n "$1" completed done
  _n "$2" pending   pend
  _n "$3" in_progress active
  printf '%s' "$t"
}

echo "== the store's real totals, not a session-scoped subset =="
S=$(mkstore 44 6 1)
got=$(summarize "$S")
printf '%s' "$got" | grep -q '1 in-progress, 6 pending, 44 done' \
  && ok "reports the full store ($got)" \
  || bad "expected 1/6/44, got: $got"

echo "== the incident's shape: a big done-pile the replay could not see =="
# The replay saw 11 done because 11 were touched this session. The store held 44.
# Any summary that reports the smaller number is the bug.
printf '%s' "$got" | grep -q '44 done' \
  && ok "a done count far above the session-touched subset survives" \
  || bad "done count collapsed toward the touched subset"

echo "== in-progress subjects are named, capped at three =="
S2=$(mkstore 1 1 5)
got2=$(summarize "$S2")
printf '%s' "$got2" | grep -q '5 in-progress' \
  && ok "counts every in-progress row" || bad "miscounted in-progress: $got2"
n=$(printf '%s' "$got2" | grep -o 'active [0-9]*' | wc -l | tr -d ' ')
[ "$n" -le 3 ] && ok "names at most three ($n)" || bad "named $n subjects, cap is 3"

echo "== an empty store yields zeros, not a crash =="
S3=$(mktemp -d)
got3=$(summarize "$S3")
printf '%s' "$got3" | grep -q '0 in-progress, 0 pending, 0 done' \
  && ok "empty store reads as zeros" || bad "empty store: $got3"

echo "== unparseable rows are skipped, not fatal =="
S4=$(mkstore 2 1 0); printf 'not json' > "$S4/99.json"
got4=$(summarize "$S4")
printf '%s' "$got4" | grep -q '0 in-progress, 1 pending, 2 done' \
  && ok "a corrupt task file does not sink the count" || bad "corrupt row: $got4"

echo "== absent store returns nothing and exits nonzero, so the caller can fall back =="
if summarize /nonexistent/store >/dev/null 2>&1; then
  bad "a missing store exited 0"
else
  ok "a missing store exits nonzero rather than reporting a confident zero"
fi

echo "== the live wiring: stop-sync must actually CALL this script =="
bash -n ./stop-sync.sh && ok "stop-sync.sh is syntactically valid" || bad "stop-sync.sh broken"
grep -q 'summarize-store.sh' ./stop-sync.sh \
  && ok "stop-sync.sh calls summarize-store.sh (wiring pinned, not just the maths)" \
  || bad "stop-sync.sh no longer calls summarize-store.sh"
grep -q 'COUNT FROM THE STORE, NOT THE REPLAY' ./stop-sync.sh \
  && ok "the rationale is recorded where the next reader will look" \
  || bad "rationale comment missing"

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
