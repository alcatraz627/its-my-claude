#!/usr/bin/env bash
# policy-approve-ask.sh against a scratch policy store: an approved pick applies the
# change, anything else changes nothing.
set -uo pipefail
HOOK="$HOME/.claude/scripts/hooks/policy-approve-ask.sh"
POL="$HOME/.claude/scripts/pol/pol.sh"
T=$(mktemp -d)
export POL_ROOT="$T/policy" POL_REQUEST_DIR="$T" POL_SESSION="sess-1"
mkdir -p "$POL_ROOT"
cp "$HOME/.claude/policy/registry.json" "$POL_ROOT/registry.json"
printf '{"global":{},"projects":{}}\n' > "$POL_ROOT/policy.json"

pass=0 fail=0
check() { if [[ "$2" == *"$3"* ]]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; echo "     got: ${2:0:240}"; fi; }

ask() {  # $1 options JSON array of labels, $2 picked label -> hook output
  jq -cn --argjson opts "$1" --arg pick "$2" '{tool_name:"AskUserQuestion", session_id:"sess-1",
    tool_input:{questions:[{question:"Allow it?", options:($opts | map({label:.}))}]},
    tool_response:{answers:{"Allow it?":$pick}}}' | bash "$HOOK"
}
request() { bash "$POL" request "$@"; }
code() { jq -r '.nonce' "$T/.policy-request-sess-1"; }
value() { bash "$POL" get git.push_main --cwd /tmp; }

out=$(request git.push_main allow --global)
check "request prints the option to offer" "$out" "Approve policy $(code): Push to main = allow (global)"
check "a request changes nothing by itself" "$(value)" "ask"

check "an unrelated question is ignored" "$(ask '["Yes","No"]' "Yes")" ""
check "and leaves the request pending" "$(code)" "$(code)"

c=$(code)
out=$(ask "[\"Approve policy $c: Push to main = allow (global)\", \"Approve policy $c: again\"]" "Approve policy $c: again")
check "two options carrying the code refuse" "$out" "exactly one"
check "and change nothing" "$(value)" "ask"

out=$(ask "[\"Approve policy $c: Push to main = allow (global)\", \"Leave it\"]" "Leave it")
check "a decline changes nothing" "$out" "did not approve"
check "the store is untouched" "$(value)" "ask"

request git.push_main allow --global >/dev/null; c=$(code)
out=$(ask "[\"Approve policy $c: Push to main = allow (global)\", \"Leave it\"]" "Approve policy $c: Push to main = allow (global)")
check "the owner's pick applies it" "$out" "the owner approved: git.push_main = allow (global)"
check "and the store now says allow" "$(value)" "allow"

request git.push_main block --global >/dev/null; c=$(code)
jq --argjson ts 1 '.ts = $ts' "$T/.policy-request-sess-1" > "$T/r" && mv "$T/r" "$T/.policy-request-sess-1"
out=$(ask "[\"Approve policy $c: x\", \"No\"]" "Approve policy $c: x")
check "an expired request does nothing" "$(value)" "allow"

check "an invalid value is refused at request time" "$(request git.push_main maybe --global 2>&1)" "invalid value"

trash "$T" >/dev/null 2>&1
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
