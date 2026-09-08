#!/usr/bin/env bash
# Tests for credential-ask-stop.sh: a reply that asks for a mint blocks once unless
# the turn checked auth first; everything else passes.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HOOK="$HERE/credential-ask-stop.sh"
T=$(mktemp -d); export HOME="$T"; mkdir -p "$T/.claude"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
tx() { # tx <file> <user prompt> <assistant text> [bash command]
  local f="$1" u="$2" a="$3" c="${4:-}"
  : > "$f"
  jq -cn --arg u "$u" '{type:"user", message:{role:"user", content:$u}}' >> "$f"
  if [ -n "$c" ]; then
    jq -cn --arg c "$c" '{type:"assistant", message:{role:"assistant", content:[{type:"tool_use", name:"Bash", input:{command:$c}}]}}' >> "$f"
    jq -cn '{type:"user", message:{role:"user", content:[{type:"tool_result", content:"ok"}]}}' >> "$f"
  fi
  jq -cn --arg a "$a" '{type:"assistant", message:{role:"assistant", content:[{type:"text", text:$a}]}}' >> "$f"
}
run() { jq -cn --arg tp "$1" --arg s "sess-$2" '{transcript_path:$tp, session_id:$s}' | bash "$HOOK" 2>/dev/null; }
rm -f /tmp/claude-credask-sess-*

tx "$T/a.jsonl" "why does install 401?" "Generate a new personal access token with read:packages and export it."
out=$(run "$T/a.jsonl" a1)
printf '%s' "$out" | rg -q '"decision":"block"' && ok "a mint ask with no auth check blocks" || bad "mint ask passed: $out"
out=$(run "$T/a.jsonl" a1)
[ -z "$out" ] && ok "the same message is blocked once, then steps aside" || bad "blocked twice"

tx "$T/b.jsonl" "why does install 401?" "No new token: gh auth already carries read:packages; export GITHUB_PACKAGES_TOKEN=\$(gh auth token)." "gh auth status"
out=$(run "$T/b.jsonl" b1)
[ -z "$out" ] && ok "an auth check this turn clears the gate" || bad "blocked despite gh auth status: $out"

tx "$T/c.jsonl" "why does install 401?" "Mint a fresh token for the registry." "printenv GITHUB_PACKAGES_TOKEN"
out=$(run "$T/c.jsonl" c1)
[ -z "$out" ] && ok "printenv of the variable counts as a check" || bad "printenv not recognised"

tx "$T/d.jsonl" "status?" "The push landed; the token lint is green."
out=$(run "$T/d.jsonl" d1)
[ -z "$out" ] && ok "the word token alone does not fire" || bad "false fire on 'token lint'"

tx "$T/e.jsonl" "status?" "Create a secret in Secret Manager named GH_PACKAGES_TOKEN for the Cloud Build step."
out=$(run "$T/e.jsonl" e1)
printf '%s' "$out" | rg -q '"decision":"block"' && ok "asking for a secret to be created blocks too" || bad "secret ask passed"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
