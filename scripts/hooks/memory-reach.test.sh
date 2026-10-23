#!/usr/bin/env bash
# memory-reach.py: the global index loads at session start, and a prompt naming
# another project brings in that project's memory index once.
set -uo pipefail
H="$HOME/.claude/scripts/hooks/memory-reach.py"
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

trash "$T" >/dev/null 2>&1
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
