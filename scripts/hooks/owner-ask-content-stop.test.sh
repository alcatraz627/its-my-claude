#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# owner-ask-content-stop.py: an ask that names only ids or a file is blocked; an ask
# that carries its question, options or default inline passes.
set -uo pipefail
HOOK="$HOME/.claude/scripts/hooks/owner-ask-content-stop.py"
T=$(mktemp -d)
export OWNER_ASK_STATE="$T"

pass=0 fail=0
run() {  # $1 reply text -> hook output
  local tp="$T/t-$RANDOM.jsonl"
  jq -cn --arg t "do the thing" '{type:"user", message:{role:"user", content:$t}}' > "$tp"
  jq -cn --arg t "$1" '{type:"assistant", message:{role:"assistant", content:[{type:"text", text:$t}]}}' >> "$tp"
  jq -cn --arg tp "$tp" '{session_id:"s1", transcript_path:$tp}' | python3 "$HOOK"
}
blocks() { local out; out=$(run "$2"); if [[ "$out" == *'"decision": "block"'* ]]; then pass=$((pass+1)); echo "ok   blocks: $1"; else fail=$((fail+1)); echo "FAIL should block: $1"; echo "     got: $out"; fi; }
passes() { local out; out=$(run "$2"); if [ -z "$out" ]; then pass=$((pass+1)); echo "ok   passes: $1"; else fail=$((fail+1)); echo "FAIL should pass: $1"; echo "     got: ${out:0:200}"; fi; }

blocks "the gcp-ingest case" "Built the preview envs. Rule on R1 to R3 when you can; details in docs/plan/DIRECTIONS.md."
blocks "decide on a list of ids" "Everything is green. I need you to decide D2, D4 and D7."
blocks "a file is the whole question" "Waiting on you: please answer the open questions in /Users/x/report.md."
blocks "a colon list of ids" "- Decide: H2, H7, H8."
blocks "answer ids in a file" 'Blocked on you: answer A1 to A6 in `/Users/x/docs/plan/86-feedback.md`.'
passes "an id labelling a described thing" "Pick the staging VM service user (#16) and the SSH alias (#17)."
passes "a verb inside a file path" 'The spec is at `/Users/x/output/20261021-step9-decide-effort/spec.md` with 12 directives.'
passes "an ask with a clause before the id" "After you approve the push, I'll start on item 1 unless you'd rather go in another order."
blocks "a proposal id as the ask" "Your call on prop-20261023-183703-77 before I start."
passes "the question is inline" "Rule on R1: should previews share sandbox's database? a) yes, cheaper (default) b) no, isolate."
passes "an id with its words" "Decide D2, whether the hub lives in bfb or Switchboard; I default to bfb."
passes "a decision page link carries the content" "Answer the page when you can: http://localhost:5106/dp/backlog-drain-1024/"
passes "ids in a status line, no ask" "Closed R1 to R3 and pushed 519f39a."
passes "ids inside a code block" $'Here is the ledger:\n```\nRule on R1 to R3\n```\nNothing needs you.'

# Required reason: a list of bare commands handed to the owner (mist-20261028-184946-19).
blocks "bare commands with no why" $'Needs you before I can go on:\n- Delete the staging VM\n- Approve the weekly live test\n- Rule on the network policy\n- Rotate the keys'
blocks "numbered bare commands" $'Waiting on you:\n1. Restart the broker\n2. Revoke the old token'
passes "commands that say why" $'Needs you before I can go on:\n- Delete the staging VM, because it bills $40 a day and nothing uses it\n- Rotate the keys (they were pasted into a public issue)\n- Approve the weekly live test so the drift check can run'
passes "one bare command is left alone" $'Needs you:\n- Approve the push'
passes "a list with no ask lead-in" $'Steps I took:\n- Delete the temp dir\n- Restart the broker\n- Rotate the log'
passes "bare commands with a decision page" $'Needs you:\n- Delete the VM\n- Rotate the keys\nAll on http://localhost:5106/dp/vm-cleanup/'
passes "bare commands inside a code block" $'Needs you:\n```\n- Delete the VM\n- Rotate the keys\n```'

# Loop-safe: the same reply blocks once, then becomes a note.
msg="Rule on Q1 and Q2 please."
first=$(run "$msg"); second=$(run "$msg")
if [[ "$first" == *block* && "$second" == *systemMessage* ]]; then pass=$((pass+1)); echo "ok   blocks once, then notes"; else fail=$((fail+1)); echo "FAIL loop safety: $second"; fi

# Stale tail: the transcript's newest assistant row is an older message, the Stop
# input's last_assistant_message is the real reply, and the verdict follows the real one.
stale() {  # $1 newest transcript row, $2 last_assistant_message, $3 session id
  local tp="$T/stale-$RANDOM.jsonl"
  jq -cn '{type:"user", message:{role:"user", content:"do the thing"}}' > "$tp"
  jq -cn --arg t "$1" '{type:"assistant", message:{role:"assistant", content:[{type:"text", text:$t}]}}' >> "$tp"
  jq -cn --arg tp "$tp" --arg m "$2" --arg s "$3" '{session_id:$s, transcript_path:$tp, last_assistant_message:$m}' | python3 "$HOOK"
}
out=$(stale "Closed R1 to R3 and pushed 519f39a." "I need you to decide D2, D4 and D7." stale01)
if [[ "$out" == *'"decision": "block"'* ]]; then pass=$((pass+1)); echo "ok   stale tail: the real reply's bare ask blocks"; else fail=$((fail+1)); echo "FAIL stale tail hid the real reply: $out"; fi
out=$(stale "I need you to decide D2, D4 and D7." "Closed R1 to R3 and pushed 519f39a." stale02)
if [ -z "$out" ]; then pass=$((pass+1)); echo "ok   stale tail: an old bare ask does not block a clean real reply"; else fail=$((fail+1)); echo "FAIL judged the old transcript row: ${out:0:200}"; fi

trash "$T" >/dev/null 2>&1
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
