#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# guard-lazy-question.sh: advisory on AskUserQuestion. Checks the no-read nudge is
# unchanged and that the notes lookup names the memory file that likely answers.
set -uo pipefail
HOOK="${LQ_HOOK:-$HOME/.claude/scripts/hooks/guard-lazy-question.sh}"
T=$(mktemp -d)
export HOME="$T/home"
CWD="/work/proj"
PM="$HOME/.claude/projects/-work-proj/memory"
GM="$HOME/.claude/memory/global"
mkdir -p "$PM" "$GM"

for i in 1 2 3 4 5 6 7 8; do
  printf -- '---\nname: filler %s\n---\nHow the build cache is laid out for part %s of the tooling.\n' "$i" "$i" > "$PM/filler-$i.md"
done
printf -- '---\nname: Clanky accounts\n---\nClanky has its own Slack login and two accounts: bot and reviewer.\n' > "$PM/clanky-accounts.md"
printf -- '- [Test logins](reference_test-logins.md): Speedway staging login and password for the QA tenant\n' > "$GM/MEMORY.md"
printf -- '---\nname: test logins\n---\nSpeedway staging: user qa@example.test, password in the keychain item speedway-qa.\n' > "$GM/reference_test-logins.md"

pass=0 fail=0
run() {  # $1 question, $2 READ|NOREAD -> hook stdout
  local tp="$T/t-$RANDOM.jsonl"
  jq -cn '{type:"user", message:{role:"user", content:"go"}}' > "$tp"
  if [ "$2" = READ ]; then
    jq -cn '{type:"assistant", message:{role:"assistant", content:[{type:"tool_use", name:"Read", input:{file_path:"/x"}}]}}' >> "$tp"
  else
    jq -cn '{type:"assistant", message:{role:"assistant", content:[{type:"text", text:"hm"}]}}' >> "$tp"
  fi
  jq -cn --arg tp "$tp" --arg q "$1" --arg cwd "$CWD" \
    '{tool_name:"AskUserQuestion", cwd:$cwd, transcript_path:$tp, tool_input:{questions:[{header:"Ask", question:$q}]}}' \
    | bash "$HOOK"
}
check() {  # $1 name, $2 output, $3 grep pattern that must match ("" = must be empty)
  if [ -z "$3" ]; then
    if [ -z "$2" ]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1 (expected silence)"; echo "     got: ${2:0:200}"; fi
  elif [[ "$2" == *$3* ]]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1 (wanted: $3)"; echo "     got: ${2:0:300}"; fi
}

out=$(run "Which Speedway staging login should I use for the QA tenant?" READ)
check "global note named for a login question" "$out" "reference_test-logins.md"
out=$(run "Which Clanky accounts exist, and are any of them blocked?" READ)
check "project note named for an accounts question" "$out" "clanky-accounts.md"
out=$(run "Should the empty state use a blue or a green button?" READ)
check "no match after a read stays silent" "$out" ""
out=$(run "Should the empty state use a blue or a green button?" NOREAD)
check "no match, no read: today's nudge" "$out" "did NOT read"
case "$out" in *"memory notes"*) fail=$((fail+1)); echo "FAIL no-match nudge must not mention notes";; *) pass=$((pass+1)); echo "ok   no-match nudge carries no notes line";; esac
out=$(run "Which Speedway staging login should I use for the QA tenant?" NOREAD)
check "match and no read: both parts" "$out" "did NOT read"
check "match and no read: notes line" "$out" "reference_test-logins.md"
out=$(run "What should the build cache part of the tooling look like?" READ)
check "words common to most notes are ignored" "$out" ""

mkdir -p "$HOME/.claude"; touch "$HOME/.claude/.no-lazy-question-gate"
out=$(run "Which Speedway staging login should I use for the QA tenant?" READ)
check "muted" "$out" ""

trash "$HOME/.claude/.no-lazy-question-gate" >/dev/null 2>&1
start=$(python3 -c 'import time; print(int(time.time()*1000))')
run "Which Speedway staging login should I use for the QA tenant?" READ >/dev/null
end=$(python3 -c 'import time; print(int(time.time()*1000))')
if [ $((end - start)) -gt 1000 ]; then fail=$((fail+1)); echo "FAIL slower than 1s"; else pass=$((pass+1)); echo "ok   fast ($((end - start)) ms)"; fi

trash "$T" >/dev/null 2>&1
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
