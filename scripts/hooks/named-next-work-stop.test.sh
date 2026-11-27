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

# The owner's waiting list sits above the agent's own section: the agent's items are not parked.
tx "$T/g.jsonl" $'## Waiting on you\n- the budget call\n\n## Next on my side\n1. the batch\n2. the release\n'
out=$(run "$T/g.jsonl" g1)
printf '%s' "$out" | rg -q '"decision":"block"' && ok "a waiting list above the section does not park the agent's own items" || bad "waiting-on above the section let it pass"

# A closing line that says what comes next and hands the go back.
tx "$T/h.jsonl" $'Two things are open.\n\nI\'ll start item 1 next unless you\'d rather redirect.'
out=$(run "$T/h.jsonl" h1)
printf '%s' "$out" | rg -q '"decision":"block"' && ok "a closing offer that hands the go back blocks" || bad "closing offer passed"
printf '%s' "$out" | rg -q 'hands the go back.*name the input it still lacks' && ok "the offer's reason names its shape and keeps the precheck" || bad "offer reason wrong: $out"

tx "$T/i.jsonl" $'I\'ll keep the old name unless you object, and that part is done.\n\nThe suite is green.\n\nNothing is open.\n\nAll pushed.'
out=$(run "$T/i.jsonl" i1)
[ -z "$out" ] && ok "the same words above the last three lines pass" || bad "an early mention blocked: $out"

# A choice already made is not work waiting on a go.
tx "$T/j.jsonl" $'Done: the timeout is now 30s.\n\nI\'ll keep the default retries unless you say otherwise.'
out=$(run "$T/j.jsonl" j1)
[ -z "$out" ] && ok "reporting a choice already made passes" || bad "a settled choice blocked: $out"

tx "$T/k.jsonl" $'The reviewer wrote:\n\n> I\'ll merge this unless you object.\n\nI replied with the numbers.'
out=$(run "$T/k.jsonl" k1)
[ -z "$out" ] && ok "someone else's quoted offer passes" || bad "a quoted line blocked: $out"

tx "$T/l.jsonl" $'Two files are left.\n\nI\'ll start with `foo.rs` unless you\'d rather redirect.'
out=$(run "$T/l.jsonl" l1)
printf '%s' "$out" | rg -q '"decision":"block"' && ok "a filename before 'unless' does not hide the offer" || bad "a period hid the offer"

tx "$T/m.jsonl" $'## Next steps\n1. the batch\n\n**Waiting on**\n- the batch: your budget call\n\nI\'ll do the release unless you object.'
out=$(run "$T/m.jsonl" m1)
printf '%s' "$out" | rg -q '"decision":"block"' && ok "a closing offer after a parked section still blocks" || bad "a parked section hid the closing offer"

runb() { jq -cn --arg tp "$1" --arg s "sess-$2" '{transcript_path:$tp, session_id:$s, background_tasks:[{status:"running", command:"cargo test"}]}' | bash "$HOOK" 2>/dev/null; }
out=$(runb "$T/h.jsonl" h2)
[ -z "$out" ] && ok "a closing offer while a job is still running passes" || bad "blocked a reply that is waiting on a running job"

# The declared default: "If no reply: <action>" or "If no reply: hold, <why>" (D1, 2026-11-26).
export KEEPWARM_PY="$HERE/../keepwarm/keepwarm.py"
rm -f /tmp/claude-nextwork-sess-*
tx "$T/n.jsonl" $'Every suite passes. Nothing waits on you.\n\n**Still open:**\n- no real render has run through the page yet\n- nothing is committed\n'
out=$(run "$T/n.jsonl" n1)
printf '%s' "$out" | rg -q '"decision":"block"' && ok "'nothing waits on you' over open work blocks" || bad "nothing-waits passed: $out"
printf '%s' "$out" | rg -q 'If no reply' && ok "its reason names the declared-default line" || bad "reason lacks the If no reply line: $out"

tx "$T/o.jsonl" $'Every suite passes. Nothing waits on you.\n\n**Still open:**\n- the budget split\n\nIf no reply: hold, the budget split is yours to set.'
out=$(run "$T/o.jsonl" o1)
[ -z "$out" ] && ok "a declared hold with its reason passes" || bad "declared hold blocked: $out"

tx "$T/p.jsonl" $'Two items are open.\n\nIf no reply: hold'
out=$(run "$T/p.jsonl" p1)
printf '%s' "$out" | rg -q '"decision":"block"' && ok "a bare hold with no reason blocks" || bad "bare hold passed"

tx "$T/q.jsonl" $'Suites are green on main.\n\nIf no reply: cut the release and post the notes.'
out=$(run "$T/q.jsonl" q1)
printf '%s' "$out" | rg -q '"decision":"block"' && ok "a declared action with nothing asked blocks: do it now" || bad "declared action with no ask passed"
printf '%s' "$out" | rg -q 'asks the owner nothing' && ok "its reason says nothing was asked" || bad "declared-action reason wrong: $out"

tx "$T/r.jsonl" $'Which schema do you want, A or B?\n\nIf no reply: build on schema A.'
out=$(run "$T/r.jsonl" r1)
[ -z "$out" ] && ok "a question with a declared default passes" || bad "question plus default blocked: $out"

out=$(runb "$T/q.jsonl" q2)
[ -z "$out" ] && ok "a declared action while a job runs passes" || bad "declared action blocked while a job runs"

tx "$T/t.jsonl" $'Main is pushed with all four suites passing, but it is not released.\n\nI\'m waiting on the ui-flow and docs-targets seats.'
out=$(runb "$T/t.jsonl" t1)
printf '%s' "$out" | rg -q '"decision":"block"' && ok "a reply waiting on seats with no declared default blocks, even while they run" || bad "waiting reply passed: $out"
printf '%s' "$out" | rg -q 'does not depend on' && ok "its reason asks for the work that does not depend on the wait" || bad "waiting reason wrong: $out"

# Replay regression (a0daccbc L3188): an honest wait on a build the next step needs passes.
tx "$T/t2.jsonl" $'Motion and rail are unverified and remain open. I\'m waiting on the motion build.'
out=$(runb "$T/t2.jsonl" t2)
[ -z "$out" ] && ok "a plain wait on a build the next step needs passes" || bad "an honest wait blocked: $out"

tx "$T/u.jsonl" $'Main is pushed, not released.\n\nI\'m waiting on the ui-flow seat.\n\nIf no reply: cut the release now; the seat does not touch it.'
out=$(runb "$T/u.jsonl" u1)
[ -z "$out" ] && ok "a waiting reply with a declared default passes while the job runs" || bad "declared waiting reply blocked: $out"

tx "$T/v.jsonl" $'Two things are open.\n\nI\'ll start item 1 next unless you\'d rather redirect.\n\nIf no reply: hold, item 1 spends about $30 and you set that budget.'
out=$(run "$T/v.jsonl" v1)
[ -z "$out" ] && ok "a closing offer with a reasoned hold passes" || bad "offer with reasoned hold blocked: $out"

tx "$T/w.jsonl" $'All three landed and nothing waits on you. Nothing is left open.'
out=$(run "$T/w.jsonl" w1)
[ -z "$out" ] && ok "'nothing waits on you' with no open work passes" || bad "a finished report blocked: $out"

# MUTATION: without the nothing-waits pattern, the 88339e91 shape passes again.
M3="$T/mut3.sh"; sed 's/nothing (else |here )?(waits|is waiting)/zzz-never/' "$HOOK" > "$M3"
rm -f /tmp/claude-nextwork-sess-*
out=$(jq -cn --arg tp "$T/n.jsonl" --arg s "sess-m3" '{transcript_path:$tp, session_id:$s}' | HOME="$T" bash "$M3" 2>/dev/null)
[ -z "$out" ] && ok "MUTATION: dropping the nothing-waits pattern lets the halt through (the assertion above is load-bearing)" || bad "nothing-waits mutant still blocked: $out"
# MUTATION: with the parser unreachable, a reasoned hold no longer parks the reply.
rm -f /tmp/claude-nextwork-sess-*
out=$(KEEPWARM_PY=/nonexistent run "$T/o.jsonl" m4)
printf '%s' "$out" | rg -q '"decision":"block"' && ok "MUTATION: without the shared parser the declared hold is not seen (the parser is load-bearing)" || bad "hold still passed with no parser"

# MUTATION: with the order rule removed, any waiting-on label parks everything again.
M2="$T/mut2.sh"; sed 's/\[ "\$wait_line" -gt "\$head_line" \]/true/' "$HOOK" > "$M2"; cp "$HERE/hook-common.sh" "$T/hook-common.sh" 2>/dev/null
rm -f /tmp/claude-nextwork-sess-*
out=$(jq -cn --arg tp "$T/g.jsonl" --arg s "sess-m2" '{transcript_path:$tp, session_id:$s}' | HOME="$T" bash "$M2" 2>/dev/null)
[ -z "$out" ] && ok "MUTATION: dropping the order rule lets the waiting list hide the section (the assertion above is load-bearing)" || bad "order-rule mutant still blocked"

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
