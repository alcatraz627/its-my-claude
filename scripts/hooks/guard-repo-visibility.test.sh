#!/usr/bin/env bash
# Checks guard-repo-visibility: public creates and edits in versable-git are denied,
# private ones and other owners pass.
set -uo pipefail
H="$(cd "$(dirname "$0")" && pwd)/guard-repo-visibility.sh"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
if [ -f "$HOME/.claude/.no-repo-visibility-gate" ]; then echo "mute file present"; exit 2; fi
bash_in() { jq -nc --arg c "$1" '{tool_name:"Bash", tool_input:{command:$c}}'; }
denied() { printf '%s' "$1" | jq -e '.hookSpecificOutput.permissionDecision=="deny"' >/dev/null 2>&1; }

out=$(bash_in "gh repo create versable-git/new-thing --public --source ." | bash "$H")
denied "$out" && ok "public create in versable-git is denied" || bad "public create ($out)"
out=$(bash_in "gh repo create versable-git/new-thing --private --source ." | bash "$H")
[ -z "$out" ] && ok "private create in versable-git passes" || bad "private create ($out)"
out=$(bash_in "gh repo create alcatraz627/toy --public" | bash "$H")
[ -z "$out" ] && ok "public create under the personal account passes" || bad "personal public ($out)"
out=$(bash_in "gh repo edit versable-git/x --visibility public --accept-visibility-change-consequences" | bash "$H")
denied "$out" && ok "making a versable-git repo public is denied" || bad "edit public ($out)"
out=$(bash_in "gh repo edit versable-git/x --visibility private" | bash "$H")
[ -z "$out" ] && ok "making a versable-git repo private passes" || bad "edit private ($out)"
out=$(jq -nc '{tool_name:"mcp__github__create_repository", tool_input:{name:"x", organization:"versable-git", private:false}}' | bash "$H")
denied "$out" && ok "MCP public create in versable-git is denied" || bad "mcp public ($out)"
out=$(jq -nc '{tool_name:"mcp__github__create_repository", tool_input:{name:"x", organization:"versable-git", private:true}}' | bash "$H")
[ -z "$out" ] && ok "MCP private create in versable-git passes" || bad "mcp private ($out)"
out=$(bash_in 'echo "gh repo create versable-git/x --public is banned"' | bash "$H")
[ -z "$out" ] && ok "a mention in echo passes" || bad "echo mention ($out)"
out=$(bash_in 'bash -c "gh repo create versable-git/x --public"' | bash "$H")
denied "$out" && ok "a bash -c wrapper is still denied" || bad "bash -c wrapper ($out)"

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
