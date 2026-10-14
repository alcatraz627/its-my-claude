#!/usr/bin/env bash
# Canary: when the ledger append is denied, atone add and propose add must say so
# (non-zero exit, a stderr line, no success receipt) instead of reporting a
# record that was never written. A sandboxed Codex session saw "recorded" and
# exit 0 while the append failed with "Operation not permitted".
#
# Everything runs under a throwaway HOME / store, never the live ledgers.
set -uo pipefail
S="$HOME/.claude/scripts"
SB=$(mktemp -d)
trap 'chmod -R u+w "$SB" 2>/dev/null; trash "$SB" 2>/dev/null' EXIT
pass=0; fail=0
ok()  { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad() { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }

mkdir -p "$SB/.claude/atone"
STORE="$SB/.claude/atone/events.jsonl"
: > "$STORE"

atone_add() { # slug
  HOME="$SB" CLAUDE_CODE_SESSION_ID=canary ATONE_NO_FUZZY=1 ATONE_NO_REPEAT_BUMP=1 \
    bash "$S/atone.sh" add --slug "$1" --title "canary" --issue "i" --cause "c" \
    --fix "f" --what-not "w" --severity S1 >"$SB/out" 2>"$SB/err"
}

echo "== atone add: a writable ledger records and exits 0 (the control) =="
atone_add canary-writable; rc=$?
[ "$rc" = 0 ] && [ "$(wc -l < "$STORE" | tr -d ' ')" = 1 ] \
  && ok "control run wrote one event (rc 0)" \
  || bad "control run failed, so the canary below proves nothing (rc=$rc, lines=$(wc -l < "$STORE"))"
rg -q "recorded|✓" "$SB/out" && ok "control stdout carries the receipt the denied run must lack" \
  || bad "control prints no receipt, so the no-receipt check below is vacuous"

echo "== atone add: a denied append is reported =="
chmod 444 "$STORE"
before=$(wc -l < "$STORE" | tr -d ' ')
atone_add canary-denied; rc=$?
[ "$rc" != 0 ] && ok "exits non-zero (rc $rc)" || bad "exited 0 with the ledger unwritable"
rg -q "NOT recorded" "$SB/err" && ok "stderr says the event was not recorded" || bad "no failure line on stderr: $(head -2 "$SB/err")"
rg -q "recorded|✓" "$SB/out" && bad "stdout still carries a success receipt: $(head -3 "$SB/out")" || ok "no success receipt on stdout"
[ "$(wc -l < "$STORE" | tr -d ' ')" = "$before" ] && ok "the ledger is unchanged" || bad "the ledger grew despite the denial"
chmod 644 "$STORE"

echo "== propose add: control, then a denied append =="
export PROPOSE_STORE="$SB/proposals.jsonl" PROPOSE_LOCK="$SB/.proposals.lock"
: > "$PROPOSE_STORE"
bash "$S/propose.sh" add --title "canary" --body "b" >"$SB/out" 2>"$SB/err"; rc=$?
[ "$rc" = 0 ] && [ "$(wc -l < "$PROPOSE_STORE" | tr -d ' ')" = 1 ] \
  && ok "control run filed one proposal (rc 0)" || bad "propose control failed (rc=$rc)"
rg -q "filed" "$SB/out" && ok "control stdout carries the 'filed' receipt" || bad "propose control prints no receipt, so the check below is vacuous"
chmod 444 "$PROPOSE_STORE"
bash "$S/propose.sh" add --title "canary denied" --body "b" >"$SB/out" 2>"$SB/err"; rc=$?
[ "$rc" != 0 ] && ok "exits non-zero (rc $rc)" || bad "exited 0 with the store unwritable"
rg -q "NOT filed" "$SB/err" && ok "stderr says the proposal was not filed" || bad "no failure line on stderr: $(head -2 "$SB/err")"
rg -q "filed" "$SB/out" && bad "stdout still says filed: $(head -2 "$SB/out")" || ok "no 'filed' receipt on stdout"
chmod 644 "$PROPOSE_STORE"

echo "== the shared writer: checked fails, the hook-safe wrapper still returns 0 =="
# shellcheck disable=SC1091
source "$S/ledger/ledger-common.sh"
: > "$SB/ro.jsonl"; chmod 444 "$SB/ro.jsonl"
ledger_append_checked "$SB/ro.jsonl" "$SB/ro.lock" '{"x":1}' 2>/dev/null; rc=$?
[ "$rc" != 0 ] && ok "ledger_append_checked returns non-zero" || bad "ledger_append_checked swallowed the failure"
ledger_append "$SB/ro.jsonl" "$SB/ro.lock" '{"x":1}' 2>"$SB/err"; rc=$?
[ "$rc" = 0 ] && ok "ledger_append stays best-effort (rc 0) for hooks" || bad "ledger_append now fails callers that must not fail"
rg -q "nothing was recorded" "$SB/err" && ok "and it still says so on stderr" || bad "ledger_append failed silently"

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
