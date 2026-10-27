#!/usr/bin/env bash
# Checks guard-env-dump: whole-environment dumps are refused, named reads pass.
set -u
G="${GUARD:-$(dirname "$0")/guard-env-dump.sh}"
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
check deny "pm2 jlist --silent"
check deny "pm2 show kanban"
check deny "pm2 env 0"
check deny "pm2 prettylist"
check deny "ps eww 123"
check deny "ps -ef"
check deny "ps -Ewww -p 1"
check deny "docker inspect web"
# Real leaks from the week of 2026-10-19: gcloud token printed bare, and a
# process listing run on another machine through ssh.
check deny "gcloud auth print-access-token"
check deny "gcloud auth application-default print-access-token"
check deny "gcloud auth print-identity-token"
check deny "gcloud auth print-access-token 2>/dev/null"
check deny "gcloud auth print-access-token | pbcopy"
check deny "gcloud auth print-access-token --impersonate-service-account=a@b.iam && ls"
check deny 'echo "$(gcloud auth print-access-token)"'
check deny "ssh extractor-vm 'ps auxe'"
check deny "ssh extractor-vm ps -efww"
check deny "ssh -i ~/.ssh/k -p 2222 extractor-vm 'cd /srv && ps -efww'"
check deny 'ssh extractor-vm "pm2 jlist"'
check deny "ssh extractor-vm 'env'"
check deny "ssh extractor-vm 'ps auxe' | grep cloudflared"
# Legitimate token and ssh uses.
check allow 'curl -H "Authorization: Bearer $(gcloud auth print-access-token)" https://x.example/api'
check allow 'curl -H Authorization:$(gcloud auth print-access-token) https://x.example/api'
check allow 'TOKEN=$(gcloud auth print-access-token)'
check allow 'TOKEN=`gcloud auth print-access-token`'
check allow "gcloud auth print-access-token > /tmp/tok"
check allow "gcloud auth print-access-token &> /tmp/tok"
check allow "gcloud auth list"
check allow "ssh extractor-vm 'ps aux'"
check allow "ssh extractor-vm uptime"
check allow "ssh -p 22 extractor-vm 'ls -la /srv'"
check allow "ssh extractor-vm"
check allow "git commit -m 'ssh host ps auxe leaked a token'"
check allow "echo 'ssh host \"ps auxe\"'"
check allow "ps aux"
check allow "pm2 ls"
check allow "pm2 restart kanban"
check allow "pm2 logs kanban --lines 20 --nostream"
check allow "ps aux"
check allow "ps -o pid,comm -p 1"
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
