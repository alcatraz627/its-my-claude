#!/usr/bin/env bash
# chain-scan.test.sh — the false-fire cases matter more than the true ones.
#
# This guard blocks. The failure mode that makes a blocking guard worse than no
# guard is firing on a correct command, so most of these cases are commands that
# MUST pass: quoted pipes, heredocs, escaped semicolons, jq filters, loops.

set -uo pipefail
SCAN="$HOME/.claude/scripts/hooks/chain-scan.py"
pass=0
fail=0

check() {
  local label="$1" expect="$2" cmd="$3"
  local got
  got=$(printf '%s' "$cmd" | python3 "$SCAN" 2>/dev/null)
  if [ "$expect" = "quiet" ]; then
    if [ -z "$got" ]; then
      printf '  ok    %s\n' "$label"
      pass=$((pass + 1))
    else
      printf '  FAIL  %s (expected quiet, got "%s")\n' "$label" "$got"
      fail=$((fail + 1))
    fi
  else
    if [ -n "$got" ]; then
      printf '  ok    %s (fired: %s)\n' "$label" "$got"
      pass=$((pass + 1))
    else
      printf '  FAIL  %s (expected a fire, got nothing)\n' "$label"
      fail=$((fail + 1))
    fi
  fi
}

echo "MUST FIRE, the real chaining the owner banned"
check "plain and-chain"            fire  'git status && git log -3'
check "semicolon chain"            fire  'cd /tmp; ls'
check "pipe to head"               fire  'cat foo.txt | head -5'
check "three-part chain"           fire  'a && b && c'
check "or-chain"                   fire  'make || echo failed'
check "cd then command"            fire  'cd /Users/x/proj && npm test'

echo
echo "MUST STAY QUIET, correct commands a naive guard would break"
check "quoted pipe in regex"       quiet "rg -n 'alpha|beta' /abs/path"
check "double-quoted pipe"         quiet 'rg -n "a|b" /abs/path'
check "escaped find terminator"    quiet 'find /abs -name x -exec rm {} \;'
check "jq filter with pipe"        quiet "jq -r '.a | .b' /abs/file.json"
check "semicolon inside quotes"    quiet 'echo "one; two"'
check "and inside a message"       quiet 'git commit -m "fix a && b parsing"'
check "single command"             quiet 'ls -la /abs/path'
check "url with query"             quiet 'curl -s "https://x.test/?a=1&b=2"'
check "awk with pipe in string"    quiet "awk '{print \$1}' /abs/f"

echo
echo "MUST STAY QUIET, shell constructs whose punctuation is syntax"
check "until loop (the wake payload)" quiet 'until [ -f /tmp/x ]; do sleep 5; done; echo done'
check "for loop"                   quiet 'for r in a b c; do echo $r; done'
check "if statement"               quiet 'if [ -f /tmp/x ]; then echo yes; fi'
check "heredoc body with pipes"    quiet "$(printf 'cat >> /tmp/f <<%s\na | b && c; d\nROWS\n' 'ROWS')"

echo
printf -- '---- pass=%d fail=%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
