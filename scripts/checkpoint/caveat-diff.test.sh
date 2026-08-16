#!/usr/bin/env bash
# Tests for validate-checkpoint.sh --diff-caveats (task #37 / D13, part 3).
#
# The failure it guards is not a broken file. It is a well-formed dump that
# quietly carries less debt than the one before it, which rules/invariant-
# graduation.md documents in both directions: doc-22 lost a UX constraint and the
# claude-ipc round lost an honest "none of these were reviewed" caveat.
#
# The hard part is not detection, it is not crying wolf. A carried-forward caveat
# is normally REWORDED, and the commonest edit is a counter moving. A gate that
# calls that a loss gets muted within a day, so the reworded case is a first-class
# row here, not an afterthought.

set -uo pipefail
V="$HOME/.claude/scripts/checkpoint/validate-checkpoint.sh"

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok   $1"; }
bad() { fail=$((fail+1)); echo "  FAIL $1"; }

mk() {  # mk <caveats-line-body> -> path
  local body="$1" t; t=$(mktemp -d)
  {
    printf '# Core Dump\n\n## Resume Contract\n\n'
    printf -- '- **Standing caveats:** %s\n\n' "$body"
    printf '## Initial Goal\nx\n## Agent Actions\nx\n## Current Expectation\nx\n## Pending Items\nx\n'
  } > "$t/cp.md"
  printf '%s' "$t/cp.md"
}

PREV=$(mk '(1) NOTHING IS COMMITTED, 152 dirty files. (2) The atone snapshot net has been dead since May. (3) Four review findings remain undispositioned.')

echo "== a reworded carry-forward is not a loss =="
A=$(mk '(1) Nothing is committed, now 156 dirty files. (2) The atone snapshot net has been dead since May. (3) Four review findings remain undispositioned.')
bash "$V" "$A" --diff-caveats "$PREV" >/dev/null 2>&1 \
  && ok "counters moving (152 to 156) does not read as vanished" \
  || bad "false positive on a reworded caveat"

echo "== adding a caveat is not a loss =="
B=$(mk '(1) NOTHING IS COMMITTED, 152 dirty files. (2) The atone snapshot net has been dead since May. (3) Four review findings remain undispositioned. (4) A brand new one.')
bash "$V" "$B" --diff-caveats "$PREV" >/dev/null 2>&1 \
  && ok "a new caveat alongside the old ones is clean" \
  || bad "adding a caveat was reported as a loss"

echo "== dropping caveats IS a loss, and it names them =="
C=$(mk '(1) NOTHING IS COMMITTED, 152 dirty files.')
out=$(bash "$V" "$C" --diff-caveats "$PREV" 2>&1); rc=$?
[ "$rc" = 3 ] && ok "exits 3 when caveats vanish" || bad "expected exit 3, got $rc"
printf '%s' "$out" | rg -q 'atone snapshot net' \
  && ok "names the dropped caveat rather than just counting" \
  || bad "did not name what vanished"
printf '%s' "$out" | rg -q 'Four review findings' \
  && ok "names every dropped caveat, not just the first" \
  || bad "reported only one of two losses"

echo "== a dump with no caveats at all loses everything, loudly =="
D=$(mk '(1) ')
bash "$V" "$D" --diff-caveats "$PREV" >/dev/null 2>&1 \
  && bad "an emptied caveat list passed as clean" \
  || ok "emptying the list is reported"

echo "== usage =="
bash "$V" "$PREV" --diff-caveats /nonexistent/file.md >/dev/null 2>&1
[ "$?" = 2 ] && ok "missing previous file exits 2" || bad "bad usage did not exit 2"
bash "$V" "$PREV" >/dev/null 2>&1 \
  && ok "the plain parse-contract mode is unaffected" \
  || bad "adding the mode broke normal validation"

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
