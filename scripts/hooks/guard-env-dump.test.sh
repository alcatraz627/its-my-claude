#!/usr/bin/env bash
# Checks guard-env-dump: whole-environment dumps are refused, named reads pass.
set -u
G="$(dirname "$0")/guard-env-dump.sh"
pass=0; fail=0
check() { # want(deny|allow) command
  local out got
  out=$(jq -cn --arg c "$2" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$G")
  if printf '%s' "$out" | grep -q '"deny"'; then got=deny; else got=allow; fi
  if [[ $got == "$1" ]]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL want $1 got $got: $2"; fi
}
check deny "env"
check deny "printenv"
check deny "env | sort"
check deny "printenv > /tmp/x"
check deny "set"
check deny "export -p"
check deny "declare -x"
check deny "cd /tmp && env"
check allow "printenv HOME"
check allow "env FOO=1 python3 x.py"
check allow "env -u FOO cmd"
check allow "set -e"
check allow "export FOO=bar"
check allow "echo \$HOME"
check allow "git commit -m 'run env to see vars'"
check allow "rg -n 'printenv' file.sh"
echo "$pass passed, $fail failed"
[[ $fail == 0 ]]
