#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# memory-reach.py: the global index loads at session start, and a prompt naming
# another project brings in that project's memory index once.
set -uo pipefail
H="${MEMORY_REACH_BIN:-$HOME/.claude/scripts/hooks/memory-reach.py}"
T=$(mktemp -d)
export MEMORY_REACH_STATE="$T" MEMORY_REACH_PROJECTS="$T/projects" MEMORY_REACH_GLOBAL="$T/global/MEMORY.md"
mkdir -p "$T/global" "$T/projects/-Users-alcatraz627-Code-Versable-speedway/memory" "$T/projects/-Users-alcatraz627-Code-Versable-versable-foundry/memory"
printf '# Global\n<!-- hidden -->\n- [Test logins](reference_test-logins.md): read before a login ask\n' > "$T/global/MEMORY.md"
printf -- '- [Staging access](speedway-staging-test-access.md): FLIP and F3 accounts\n' > "$T/projects/-Users-alcatraz627-Code-Versable-speedway/memory/MEMORY.md"
printf -- '- [Foundry note](x.md): y\n' > "$T/projects/-Users-alcatraz627-Code-Versable-versable-foundry/memory/MEMORY.md"
FOUNDRY="/Users/alcatraz627/Code/Versable/versable-foundry"

pass=0 fail=0
check() { if [[ "$2" == *"$3"* ]]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; echo "     got: ${2:0:200}"; fi; }
none()  { if [ -z "$2" ]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; echo "     got: ${2:0:200}"; fi; }
ask() { jq -cn --arg p "$1" --arg c "$2" '{session_id:"s1", cwd:$c, prompt:$p}' | python3 "$H" prompt; }

out=$(echo '{}' | python3 "$H" session-start)
check "the global index loads at session start" "$out" "Test logins"
check "and its HTML comments are dropped" "$( [[ "$out" == *hidden* ]] && echo leaked || echo clean )" "clean"
check "naming speedway from foundry brings its memory" "$(ask "check the Speedway previews" "$FOUNDRY")" "FLIP and F3"
none "only once per session" "$(ask "speedway again" "$FOUNDRY")"
none "a session's own project is not re-injected" "$(ask "versable-foundry work" "$FOUNDRY")"
none "a prompt naming no project injects nothing" "$(jq -cn '{session_id:"s2", cwd:"/x", prompt:"update the readme"}' | python3 "$H" prompt)"

# A project is named by its full name or a listed alias, never by a word borrowed from it.
for p in better-file-browser local-models landing-app switchboard-mac slack-automation; do
  mkdir -p "$T/projects/-Users-alcatraz627-Code-$p/memory"
  printf -- '- [%s note](x.md): y\n' "$p" > "$T/projects/-Users-alcatraz627-Code-$p/memory/MEMORY.md"
done
askas() { jq -cn --arg s "$1" --arg p "$2" '{session_id:$s, cwd:"/x", prompt:$p}' | python3 "$H" prompt; }
none "better alone does not load better-file-browser"  "$(askas f1 "make it better and show me a better layout")"
none "local alone does not load local-models"          "$(askas f2 "a local tailnet address and a local store")"
none "landing alone does not load landing-app"         "$(askas f3 "the landing box follows when they report")"
none "slack alone does not load slack-automation"      "$(askas f4 "a slack bot, in slack")"
none "browser alone does not load better-file-browser" "$(askas f5 "open the browser")"
check "the full name loads better-file-browser"        "$(askas g1 "work on better-file-browser today")" "better-file-browser note"
check "the name with spaces loads local-models"        "$(askas g2 "check local models first")" "local-models note"
check "the full name loads landing-app"                "$(askas g3 "ship landing-app")" "landing-app note"
check "the full name loads slack-automation"           "$(askas g4 "review slack-automation")" "slack-automation note"
check "the alias bfb loads better-file-browser"        "$(askas g5 "build it into bfb")" "better-file-browser note"
check "the alias switchboard loads switchboard-mac"    "$(askas g6 "inventory the switchboard notes")" "switchboard-mac note"
none "an alias inside a longer word does not load"     "$(askas f6 "bfbx and switchboards")"
none "a hyphenated alias lookalike does not load"      "$(askas f7 "my-bfb-thing")"

trash "$T" >/dev/null 2>&1
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
