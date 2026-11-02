#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# Tests for named-next-work-stop.sh: a reply that ends on a "Doing now" section
# blocks once; a parked list, a sentence, and a continuing harness pass.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HOOK="$HERE/named-next-work-stop.sh"
T=$(mktemp -d); export HOME="$T"; mkdir -p "$T/.claude"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
tx() { # tx <file> <assistant text>
  : > "$1"
  jq -cn '{type:"user", message:{role:"user", content:"simple words please"}}' >> "$1"
  jq -cn --arg a "$2" '{type:"assistant", message:{role:"assistant", content:[{type:"text", text:$a}]}}' >> "$1"
}
run() { jq -cn --arg tp "$1" --arg s "sess-$2" --argjson a "${3:-false}" '{transcript_path:$tp, session_id:$s, stop_hook_active:$a}' | bash "$HOOK" 2>/dev/null; }
rm -f /tmp/claude-nextwork-sess-*

tx "$T/a.jsonl" $'Here is the list.\n\n**Doing now**\n- ask push-guard-7c\n- review the overnight closes\n- amend ADR-007\n'
out=$(run "$T/a.jsonl" a1)
printf '%s' "$out" | rg -q '"decision":"block"' && ok "a bold Doing-now label at the end of the turn blocks" || bad "Doing now passed: $out"
printf '%s' "$out" | rg -q 'name the input it still lacks' && ok "the reason carries the precheck" || bad "reason lacks the precheck"
out=$(run "$T/a.jsonl" a1)
[ -z "$out" ] && ok "the same message is blocked once, then steps aside" || bad "blocked twice"
rm -f /tmp/claude-nextwork-sess-*
out=$(run "$T/a.jsonl" a1 true)
[ -z "$out" ] && ok "steps aside while the harness is continuing" || bad "blocked under stop_hook_active"

tx "$T/b.jsonl" $'## Next steps\n1. push\n2. review\n'
out=$(run "$T/b.jsonl" b1)
printf '%s' "$out" | rg -q '"decision":"block"' && ok "a Next-steps heading blocks too" || bad "Next steps passed"

tx "$T/c.jsonl" $'**Doing now**\n- amend ADR-007\n\n**Waiting on**\n- push-guard-7c: the review shape (asked, msg-382b)\n'
out=$(run "$T/c.jsonl" c1)
[ -z "$out" ] && ok "a list that parks its items under waiting-on passes" || bad "parked list blocked"

tx "$T/d.jsonl" $'Next I will read the store, then the ADR, and the fix follows in this turn.'
out=$(run "$T/d.jsonl" d1)
[ -z "$out" ] && ok "the phrase inside a sentence is not a section" || bad "sentence blocked"

tx "$T/e.jsonl" $'All three landed; suites green.'
out=$(run "$T/e.jsonl" e1)
[ -z "$out" ] && ok "a plain done reply passes" || bad "plain reply blocked"

touch "$T/.claude/.no-named-next-work-gate"
rm -f /tmp/claude-nextwork-sess-*
out=$(run "$T/a.jsonl" f1)
[ -z "$out" ] && ok "the mute file silences it" || bad "fired under mute"
rm -f "$T/.claude/.no-named-next-work-gate"

# Stale tail: the transcript's newest assistant row is an older message, the Stop
# input's last_assistant_message is the real reply, and the verdict follows the real one.
runm() { jq -cn --arg tp "$1" --arg s "sess-$2" --arg m "$3" '{transcript_path:$tp, session_id:$s, last_assistant_message:$m}' | bash "$HOOK" 2>/dev/null; }
rm -f /tmp/claude-nextwork-sess-*
tx "$T/s1.jsonl" 'All done, nothing is open.'
out=$(runm "$T/s1.jsonl" s1 $'Here is the list.\n\n**Doing now**\n- ask push-guard-7c\n')
printf '%s' "$out" | rg -q '"decision":"block"' && ok "stale tail: the real reply's Doing-now label blocks" || bad "stale tail hid the real reply: $out"
tx "$T/s2.jsonl" $'**Doing now**\n- ask push-guard-7c\n'
out=$(runm "$T/s2.jsonl" s2 'All done, nothing is open.')
[ -z "$out" ] && ok "stale tail: an old Doing-now row does not block a clean real reply" || bad "judged the old transcript row: $out"

# MUTATION: without the heading regex the hook is a no-op that reads as passing.
M="$T/mut.sh"; sed 's/doing now|doing next|next i will/zzz-never/' "$HOOK" > "$M"
rm -f /tmp/claude-nextwork-sess-*
out=$(jq -cn --arg tp "$T/a.jsonl" --arg s "sess-m1" '{transcript_path:$tp, session_id:$s}' | HOME="$T" bash "$M" 2>/dev/null)
[ -z "$out" ] && ok "MUTATION: dropping the heading pattern turns the block off (the assertion above is load-bearing)" || bad "mutant still blocked"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
