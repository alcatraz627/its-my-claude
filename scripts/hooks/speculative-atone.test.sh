#!/usr/bin/env bash
# speculative-atone.test.sh — the three fixes of #43 (ledger 10, 20, 21), each
# with the defect planted to prove the guard: the hinter says the same thing at
# most twice, the Stop gate waits for the owner to go quiet, and agreeing costs
# what refuting costs.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
HINT="$HERE/speculative-atone-hint.sh"; STOP="$HERE/speculative-atone-stop.sh"
SPEC="$HERE/../atone-speculative.sh"
T=$(mktemp -d); export HOME="$T"; mkdir -p "$T/.claude/.turn-state" "$T/.claude/atone" "$T/.claude/scripts/ledger" "$T/.claude/scripts/session-mgmt"
cp "$HERE/../ledger/ledger-common.sh" "$T/.claude/scripts/ledger/" 2>/dev/null || true
cp "$HERE/../session-mgmt/owner-quiet.py" "$T/.claude/scripts/session-mgmt/"
export SPEC_ATONE_STORE="$T/.claude/atone/speculative.jsonl"
export PATH="$T/bin:$PATH"; mkdir -p "$T/bin"
# No broker in the sandbox: the hinter falls back to claude-<sid8> for the alias.
printf '#!/bin/sh\nexit 1\n' > "$T/bin/claude-ipc"; chmod +x "$T/bin/claude-ipc"
printf '#!/bin/sh\nexit 0\n' > "$T/bin/warn-log.sh"; chmod +x "$T/bin/warn-log.sh"
mkdir -p "$T/.claude/scripts/hooks"; cp "$T/bin/warn-log.sh" "$T/.claude/scripts/hooks/warn-log.sh"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
SID="abcdef12-0000-4000-8000-000000000000"
row() { jq -cn --arg id "$1" --arg s "claude-abcdef12" --arg sl "$2" '{id:$id, ts:"2026-09-08T00:00:00Z", session:$s, slug:$sl, severity:"S2", issue:"the auditor thinks so", status:"pending"}'; }
{ row spec-1 slug-one; row spec-2 slug-two; } > "$SPEC_ATONE_STORE"
hint() { jq -cn --arg s "$SID" '{session_id:$s, prompt:"go on"}' | bash "$HINT" 2>/dev/null | jq -r '.hookSpecificOutput.additionalContext // empty'; }

echo "== ledger 10: two identical fires, then one line =="
o1=$(hint); o2=$(hint); o3=$(hint); o4=$(hint)
printf '%s' "$o1" | rg -q '^┌─ 🙏 atone' && ok "nag 1 is the full box" || bad "nag 1: $o1"
printf '%s' "$o2" | rg -q '^┌─ 🙏 atone' && ok "nag 2 is the full box" || bad "nag 2: $o2"
printf '%s' "$o3" | rg -q '^🙏 atone · speculative: 2 row\(s\) still pending after 3 identical nags' && ok "nag 3 collapses to one line naming the count" || bad "nag 3: $o3"
printf '%s' "$o3" | rg -q 'spec-1 spec-2' && ok "the line names the ids" || bad "ids missing: $o3"
[ "$(printf '%s' "$o4" | wc -l | tr -d ' ')" -le 1 ] && ok "and stays one line" || bad "nag 4 grew again"
[ "$(cat "$T/.claude/.turn-state/spec-atone-nags-abcdef12")" = "4" ] && ok "the escalation count still climbs underneath" || bad "count did not climb"
# The set changes: a new row brings the box back.
row spec-3 slug-three >> "$SPEC_ATONE_STORE"
o5=$(hint)
printf '%s' "$o5" | rg -q '^┌─ 🙏 atone' && ok "a changed pending set brings the full box back" || bad "set change ignored: $o5"
printf '%s' "$o5" | rg -q 'agree = ' && ok "the box names the agree verb" || bad "agree verb missing"
# MUTATION: without the signature the box repeats forever.
M="$T/hint-mut.sh"; sed 's/if \[ "\$same" -gt 2 \]; then/if false; then/' "$HINT" > "$M"
rm -f "$T/.claude/.turn-state/spec-atone-sig-abcdef12"
for i in 1 2 3; do m3=$(jq -cn --arg s "$SID" '{session_id:$s, prompt:"go on"}' | bash "$M" 2>/dev/null | jq -r '.hookSpecificOutput.additionalContext // empty'); done
printf '%s' "$m3" | rg -q '^┌─ 🙏 atone' && ok "MUTATION: without the collapse the third nag is the box again" || bad "mutant collapsed anyway"

echo "== ledger 20: the Stop gate waits for the owner to go quiet =="
printf '9' > "$T/.claude/.turn-state/spec-atone-nags-abcdef12"; rm -f "$T/.claude/.turn-state/spec-atone-blocked-abcdef12"
now_iso() { python3 -c 'import datetime,sys; print((datetime.datetime.now(datetime.timezone.utc)-datetime.timedelta(seconds=int(sys.argv[1]))).strftime("%Y-%m-%dT%H:%M:%S.000Z"))' "$1"; }
tx() { # tx <file> <seconds-ago of the owner prompt> [cron-after]
  : > "$1"
  jq -cn --arg ts "$(now_iso "$2")" '{type:"user", timestamp:$ts, message:{role:"user", content:"where is the pi"}}' >> "$1"
  if [ "${3:-}" = cron ]; then jq -cn --arg ts "$(now_iso 5)" '{type:"user", timestamp:$ts, message:{role:"user", content:"Wake check. Two steps, in this order."}}' >> "$1"; fi
  jq -cn '{type:"assistant", message:{role:"assistant", content:[{type:"text", text:"looking"}]}}' >> "$1"
}
stop() { jq -cn --arg s "$SID" --arg tp "$1" '{session_id:$s, transcript_path:$tp}' | bash "$STOP" 2>/dev/null; }
tx "$T/live.jsonl" 60
out=$(stop "$T/live.jsonl"); [ -z "$out" ] && ok "owner spoke 60s ago: no block" || bad "blocked mid-conversation: $out"
tx "$T/quiet.jsonl" 7200
out=$(stop "$T/quiet.jsonl"); printf '%s' "$out" | rg -q '"decision": ?"block"' && ok "owner quiet 2h: the gate blocks" || bad "no block when idle: $out"
rm -f "$T/.claude/.turn-state/spec-atone-blocked-abcdef12"
tx "$T/cron.jsonl" 7200 cron
out=$(stop "$T/cron.jsonl"); printf '%s' "$out" | rg -q '"decision": ?"block"' && ok "a cron wake 5s ago does not count as the owner speaking" || bad "cron wake read as owner: $out"
rm -f "$T/.claude/.turn-state/spec-atone-blocked-abcdef12"
out=$(SPEC_ATONE_IDLE_S=30 stop "$T/live.jsonl"); printf '%s' "$out" | rg -q '"decision": ?"block"' && ok "the idle window is a knob (30s makes 60s-ago idle)" || bad "knob ignored"
rm -f "$T/.claude/.turn-state/spec-atone-blocked-abcdef12"
: > "$T/nots.jsonl"; jq -cn '{type:"user", message:{role:"user", content:"where is the pi"}}' >> "$T/nots.jsonl"
out=$(stop "$T/nots.jsonl"); printf '%s' "$out" | rg -q '"decision": ?"block"' && ok "no timestamp on the prompt: the old behaviour (block) holds" || bad "no-timestamp path changed: $out"
printf '%s' "$out" | rg -q 'agree \(' && ok "the block names the agree verb" || bad "agree missing from the block"
# MUTATION: without the idle test the gate fires on the count alone.
M="$T/stop-mut.sh"; sed 's/\[ "\$quiet" -lt "\$IDLE_S" \] \&\& exit 0/true/' "$STOP" > "$M"
rm -f "$T/.claude/.turn-state/spec-atone-blocked-abcdef12"
out=$(jq -cn --arg s "$SID" --arg tp "$T/live.jsonl" '{session_id:$s, transcript_path:$tp}' | bash "$M" 2>/dev/null)
printf '%s' "$out" | rg -q '"decision": ?"block"' && ok "MUTATION: without the idle test the live exchange is blocked (ledger 20's shape)" || bad "mutant did not block"

echo "== ledger 21: agree costs what refute costs =="
out=$(bash "$SPEC" agree spec-1 --evidence "short" 2>&1); rc=$?
[ "$rc" -eq 2 ] && ok "agree refuses a nod under 40 chars, like refute" || bad "short agree accepted (rc $rc)"
out=$(bash "$SPEC" agree spec-1 --evidence "turn 14:23 in b13dc141: the list was written and the turn ended with every input in hand" 2>&1); rc=$?
[ "$rc" -eq 0 ] && ok "agree with cited evidence is one command" || bad "agree failed: $out"
jq -e 'select(.id=="spec-1") | .status=="agreed" and (.evidence|length)>40 and (.resolved_ts|length)>0' "$SPEC_ATONE_STORE" >/dev/null && ok "the row is agreed with evidence and a timestamp" || bad "row shape"
printf '%s' "$out" | rg -q 'owed when idle' && ok "and it says the real /atone is still owed" || bad "no owed line: $out"
o=$(hint); printf '%s' "$o" | rg -q 'spec-1' && bad "an agreed row still nags" || ok "an agreed row leaves the nag"
bash "$SPEC" agreed 2>/dev/null | rg -q 'spec-1' && ok "agreed lists what is owed" || bad "agreed list empty"
bash "$SPEC" stats 2>/dev/null | rg -q 'agreed' && ok "stats counts agreed on its own" || bad "stats hides agreed"
# MUTATION: dropping the evidence floor makes agree a free dismissal in the other direction.
M="$T/spec-mut.sh"; sed 's/\[ \${#evidence} -ge 40 \] || { echo "atone-speculative agree/false \&\& { echo "atone-speculative agree/' "$SPEC" > "$M"
out=$(bash "$M" agree spec-2 --evidence "yes" 2>&1); rc=$?
[ "$rc" -eq 0 ] && ok "MUTATION: without the floor a three-letter agree lands (the floor is load-bearing)" || bad "mutant refused: $out"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
