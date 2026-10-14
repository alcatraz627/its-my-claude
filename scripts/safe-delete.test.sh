#!/usr/bin/env bash
# Suite for safe-delete.sh: which spellings of a deletion are blocked, and which
# mentions of one stay silent. GUARD_UNDER_TEST points it at a mutated copy
# (the copy must sit next to hooks/shell-scan.py, i.e. in scripts/).
set -uo pipefail
HOOK="${GUARD_UNDER_TEST:-$(cd "$(dirname "$0")" && pwd)/safe-delete.sh}"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

run() { jq -nc --arg c "$1" '{tool_name:"Bash", tool_input:{command:$c}}' | bash "$HOOK" 2>/dev/null; }
blocked() {
  local out; out=$(run "$1")
  if [ -n "$out" ] && printf '%s' "$out" | jq -e '.decision == "block"' >/dev/null 2>&1; then ok "BLOCKED: $1"; else bad "not blocked: $1"; fi
}
allowed() { [ -z "$(run "$1")" ] && ok "allow: $1" || bad "blocked (should pass): $1"; }

# What always blocked
blocked "rm notes.txt"
blocked "rm -rf build"
blocked "ls && rm notes.txt"
blocked 'rm "a file.txt"'

# Spellings that used to slip past (D33 audit, 2026-10-15)
blocked '\rm notes.txt'
blocked "/bin/rm notes.txt"
blocked "command rm notes.txt"
blocked "env rm notes.txt"
blocked "sudo rm notes.txt"
blocked "ls | xargs rm"
blocked "xargs -I{} rm {}"
blocked "find . -name '*.tmp' -delete"
blocked "find . -name x -exec rm {} \\;"
blocked "unlink notes.txt"
blocked 'bash -c "rm notes.txt"'
blocked "sh -c 'rm -rf build'"

# Mentions and look-alikes stay silent
allowed 'echo "do not rm -rf the repo"'
allowed 'git commit -m "remove rm usage"'
allowed "git rm tracked.txt"
allowed "trash notes.txt"
allowed "rg -n 'rm -rf' scripts/"
allowed "ls farm-data"
allowed "find . -name x -exec echo {} \\;"
allowed 'bash -c "echo rm"'
allowed 'printf "%s\n" "\\rm x"'

# The block must be valid JSON even when the command carries quotes.
out=$(run 'bash -c "rm \"quoted name\""')
printf '%s' "$out" | jq -e '.reason | contains("trash")' >/dev/null 2>&1 && ok "block reason is valid JSON with quotes in the command" || bad "block reason is not valid JSON"

echo "---- pass=$pass fail=$fail"
[ $fail -eq 0 ]
