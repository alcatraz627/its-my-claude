#!/usr/bin/env bash
# session-state.test.sh — the refusal must go red on an open row and green once
# it is done; show/clear round-trip; finished needs a reason.
set -uo pipefail
S=$HOME/.claude/scripts/session-state/session-state.sh; T=$HOME/.claude/scripts/task-table/task.sh
pass=0; fail=0; ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }
export SESSION_STATE_DIR=$(mktemp -d); SID=sstest00-0000-4000-8000-000000000001; ST=sstest00
STORE=$HOME/.claude/tasks/session-$ST
mkdir -p "$STORE"; bash "$T" add "ready row for the refusal" --session $ST >/dev/null 2>&1
[ -n "$(ls "$STORE")" ] && ok "fixture store holds a row" || ko "fixture store empty"
bash "$S" set finished --sid $SID --store $ST --reason "done" >/dev/null 2>&1; rc=$?
[ $rc -eq 1 ] && ok "finished REFUSED while a ready row is open (exit 1)" || ko "refusal (rc=$rc)"
[ -f "$SESSION_STATE_DIR/$SID.json" ] && ko "refusal still wrote a file" || ok "refusal wrote nothing"
bash "$S" set finished --sid $SID --store nosuch00 --reason "typo" >/dev/null 2>&1; rc=$?
[ $rc -eq 1 ] && ok "unresolvable --store refused (exit 1), not a free finish" || ko "typo store (rc=$rc)"
bash "$S" set finished --sid $SID --store $ST 2>/dev/null; rc=$?
[ $rc -eq 2 ] && ok "finished without --reason rejected (exit 2)" || ko "reason required (rc=$rc)"
bash "$S" set blocked --sid $SID --store $ST --reason "USER: needs a ruling" >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && [ "$(jq -r .state "$SESSION_STATE_DIR/$SID.json")" = blocked ] && ok "blocked writes even with a ready row" || ko "blocked (rc=$rc)"
bash "$T" done 1 --session $ST >/dev/null 2>&1
bash "$S" set finished --sid $SID --store $ST --reason "row done" >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && [ "$(jq -r .state "$SESSION_STATE_DIR/$SID.json")" = finished ] && ok "finished ACCEPTED once the row is done" || ko "accept (rc=$rc)"
[ "$(bash "$S" show $SID | jq -r .reason)" = "row done" ] && ok "show round-trips the reason" || ko "show"
bash "$S" clear $SID; bash "$S" show $SID >/dev/null 2>&1; rc=$?
[ $rc -eq 3 ] && ok "clear removes; show exits 3 (never 'finished' by absence)" || ko "clear/show (rc=$rc)"
trash "$STORE" 2>/dev/null; trash "$SESSION_STATE_DIR" 2>/dev/null
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
