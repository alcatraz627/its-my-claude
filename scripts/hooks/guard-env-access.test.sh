#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# Checks that guard-env-access nudges a new env read in ordinary code and stays quiet
# in the project's own env module (any JS or TS flavour), its tests and its config.
set -uo pipefail

HOOK="${HOOK_UNDER_TEST:-$HOME/.claude/scripts/hooks/guard-env-access.sh}"
T=$(mktemp -d)
mkdir -p "$T/proj/.git" "$T/proj/src"
pass=0 fail=0

# nudge FILE: the hook's output for a Write of a new env read to FILE
nudge() {
  jq -cn --arg f "$1" '{tool_name:"Write", tool_input:{file_path:$f, content:"const url = process.env.API_URL;\n"}}' | bash "$HOOK"
}
loud() {  # $1 name, $2 file: the hook must speak
  local out; out=$(nudge "$2")
  if [[ "$out" == *"[env-access]"* ]]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1"; echo "     got: $out"; fi
}
quiet() {  # $1 name, $2 file: the hook must stay silent
  local out; out=$(nudge "$2")
  if [ -z "$out" ]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1"; echo "     got: $out"; fi
}

loud  "a new env read in ordinary code is nudged" "$T/proj/src/client.mjs"
loud  "and in a plain .js file" "$T/proj/src/client.js"
quiet "env.ts is the sanctioned module" "$T/proj/src/env.ts"
quiet "env.mjs is the sanctioned module" "$T/proj/src/env.mjs"
quiet "env.js is the sanctioned module" "$T/proj/src/env.js"
quiet "env.mts is the sanctioned module" "$T/proj/src/env.mts"
quiet "env.cjs is the sanctioned module" "$T/proj/src/env.cjs"
quiet "env.py is the sanctioned module" "$T/proj/src/env.py"
loud  "a file that only ends in env.mjs is not the module" "$T/proj/src/myenv.mjs"
quiet "a test file is skipped" "$T/proj/src/client.test.mjs"

trash "$T" >/dev/null 2>&1
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
