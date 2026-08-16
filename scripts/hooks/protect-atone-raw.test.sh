#!/usr/bin/env bash
# Mutation test for protect-atone-raw's stage-two mention filter.
#
# The guard must keep blocking a real write to the raw ledger, and must stop
# blocking a command that merely QUOTES the ledger path as prose. Both
# directions are asserted, because a guard that only ever passes is untested and
# a mention filter that over-blanks would silently disarm the protection.
set -uo pipefail
G="$HOME/.claude/scripts/protect-atone-raw.sh"
P='atone/events.jsonl'

pass=0; fail=0
run() { printf '%s' "$1" | bash "$G" >/dev/null 2>&1; echo $?; }
t() { # name | json | want-blocked(yes|no)
  local name="$1" json="$2" want="$3" rc got
  rc=$(run "$json")
  if [ "$rc" -eq 0 ]; then got=no; else got=yes; fi
  if [ "$got" = "$want" ]; then pass=$((pass+1)); printf '  ok   %-42s blocked=%s\n' "$name" "$got"
  else fail=$((fail+1)); printf '  FAIL %-42s blocked=%s want=%s (rc=%s)\n' "$name" "$got" "$want" "$rc"; fi
}

j() { jq -cn --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}'; }

echo "== must STILL BLOCK: real writes to the raw ledger =="
t "truncate via redirect"      "$(j "echo x > ~/.claude/$P")"                       yes
t "append via redirect"        "$(j "echo x >> ~/.claude/$P")"                      yes
t "in-place edit"              "$(j "sed -i '' 's/a/b/' ~/.claude/$P")"             yes

echo "== must ALLOW: the path appears only inside quotes as prose =="
t "path quoted in a jq arg"    "$(j "jq -n --arg i \"the log is ~/.claude/$P\" .")" no
t "path in a proposal body"    "$(j "bash propose.sh add --body \"see ~/.claude/$P for detail\"")" no

echo "== must ALLOW: read-only inspection (pre-existing behaviour) =="
t "wc on the ledger"           "$(j "wc -l < ~/.claude/$P")"                        no
t "rg over the ledger"         "$(j "rg probe ~/.claude/$P")"                       no

echo "== must ALLOW: the atone CLI itself (pre-existing whitelist) =="
t "atone add via the CLI"      "$(j "bash ~/.claude/scripts/atone.sh add --slug x")" no

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
