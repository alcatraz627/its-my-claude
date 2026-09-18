#!/usr/bin/env bash
# Tests for hook-snooze.sh: owner approval is required, scopes match, expiry drops rows.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; S="$HERE/hook-snooze.sh"
T=$(mktemp -d); export SNOOZE_LEDGER="$T/snooze.jsonl"; export SNOOZE_NOW=1789800000
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

out=$(bash "$S" add prose --for 3d --scope global --reason "owner is drafting a spec in his own register" 2>&1); rc=$?
[ "$rc" -eq 3 ] && ok "add without --approved-by owner is refused" || bad "unapproved add rc $rc: $out"
out=$(bash "$S" add prose --for 3d --scope global --reason "owner is drafting a spec in his own register" --approved-by owner --by abcdef12 2>&1); rc=$?
[ "$rc" -eq 0 ] && ok "approved add lands" || bad "add: $out"
[ "$(jq -c 'select(.hook=="reply-lede")' "$SNOOZE_LEDGER" | wc -l | tr -d ' ')" = 1 ] && ok "group expands to its hooks" || bad "group expansion"
bash "$S" check prose-smell >/dev/null && ok "global scope matches any cwd" || bad "global check"
bash "$S" check declared-ready >/dev/null && bad "an unsnoozed hook reads snoozed" || ok "unsnoozed hook is not matched"

bash "$S" add declared-ready --for 1d --scope project --project /tmp/proj-a --reason "migrating the sentinel for one project" --approved-by owner >/dev/null
bash "$S" check declared-ready --project /tmp/proj-a/sub >/dev/null && ok "project scope matches a subdirectory" || bad "project scope"
bash "$S" check declared-ready --project /tmp/proj-b >/dev/null && bad "project scope leaks to another project" || ok "project scope stays in its project"

bash "$S" add weekly-usage --for 4h --scope session --session 1234567890ab --reason "owner said press on this session" --approved-by owner >/dev/null
bash "$S" check weekly-usage --session 1234567890ab >/dev/null && ok "session scope matches its session" || bad "session scope"
bash "$S" check weekly-usage --session ffffffffffff >/dev/null && bad "session scope leaks" || ok "session scope stays in its session"

out=$(SNOOZE_NOW=$((1789800000 + 5 * 86400)) bash "$S" list); printf '%s' "$out" | rg -q 'no live snoozes' && ok "expired rows drop on read" || bad "expiry: $out"
id=$(jq -r 'select(.hook=="declared-ready") | .id' "$SNOOZE_LEDGER" | head -1)
bash "$S" lift "$id" >/dev/null; bash "$S" check declared-ready --project /tmp/proj-a >/dev/null && bad "lift did not remove" || ok "lift removes the row"
out=$(bash "$S" add prose --for 3d --scope global --reason "short" --approved-by owner 2>&1); rc=$?; [ "$rc" -eq 2 ] && ok "a 5-char reason is refused" || bad "short reason rc $rc"

echo "== MUTATION: without the approval check, an unapproved add lands =="
sed 's/\[ "\$approved" = "owner" \] ||/false \&\&/' "$S" > "$T/mut.sh"
out=$(SNOOZE_LEDGER="$T/m.jsonl" bash "$T/mut.sh" add prose --for 1h --scope global --reason "no approval given at all here" 2>&1); rc=$?
[ "$rc" -eq 0 ] && ok "mutant accepts, so the approval check is load-bearing" || bad "mutant rc $rc"
echo "---- pass=$pass fail=$fail"; [ "$fail" -eq 0 ]
