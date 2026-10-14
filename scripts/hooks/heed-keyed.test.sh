#!/usr/bin/env bash
# Tests for hook_heed_note (hook-common.sh) and for the five hooks that use it:
# guard-cluster-e-smells, guard-prose-quality, guard-ai-signature,
# warn-git-add-enumeration and prefer-ripgrep. For each, a fire followed by a clean
# run on the same key records heeded:true, and a fire followed by the same fire
# records heeded:false. Markers and the warn store are private to the test.
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
RIPGREP_HOOK="${RIPGREP_HOOK:-$HOME/.claude/scripts/prefer-ripgrep.sh}"
T=$(mktemp -d)
export WARN_LOG_STORE="$T/warn.jsonl"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

SID="heedk0001-0000-0000-0000-000000000000"
SID8="heedk000"
rm -f /tmp/claude-heedkey-*-"$SID8"-* 2>/dev/null

# Count heed rows for a hook with the given verdict.
heeds() { # heeds <hook> <true|false>
  [ -f "$WARN_LOG_STORE" ] || { echo 0; return; }
  jq -r --arg h "$1" --arg v "$2" 'select(.kind=="heed" and .hook_id==$h and .heeded==$v) | .id' "$WARN_LOG_STORE" | wc -l | tr -d ' '
}
reset() { rm -f /tmp/claude-heedkey-*-"$SID8"-* "$WARN_LOG_STORE" 2>/dev/null; }
expect() { # expect <label> <hook> <true-count> <false-count>
  local t f; t=$(heeds "$2" true); f=$(heeds "$2" false)
  if [ "$t" = "$3" ] && [ "$f" = "$4" ]; then ok "$1"; else bad "$1 (heed true=$t want $3, false=$f want $4)"; fi
}

# ---- the helper itself ----
. "$D/hook-common.sh"
reset
hook_heed_note unit-hook "$SID" key-a clean
expect "helper: a clean run with nothing pending records nothing" unit-hook 0 0
hook_heed_note unit-hook "$SID" key-a fired
hook_heed_note unit-hook "$SID" key-a clean
expect "helper: fired then clean on the same key is heeded true" unit-hook 1 0
hook_heed_note unit-hook "$SID" key-a clean
expect "helper: the marker is consumed, a second clean adds nothing" unit-hook 1 0
reset
hook_heed_note unit-hook "$SID" key-a fired
hook_heed_note unit-hook "$SID" key-a fired
expect "helper: fired twice on the same key is heeded false" unit-hook 0 1
reset
hook_heed_note unit-hook "$SID" key-a fired
hook_heed_note unit-hook "$SID" key-b clean
expect "helper: a clean run on another key settles nothing" unit-hook 0 0
hook_heed_note unit-hook "othersess-xxxx" key-a clean
expect "helper: another session never settles this session's fire" unit-hook 0 0

# ---- guard-cluster-e-smells (block-level IIFE in JSX) ----
bad_tsx='const x = <div>{(() => { return 1; })()}</div>;'
ok_tsx='const x = <div>{1}</div>;'
cluster() { jq -nc --arg s "$SID" --arg c "$1" '{tool_name:"Write", session_id:$s, cwd:"/tmp", tool_input:{file_path:"/tmp/heedk/App.tsx", content:$c}}' | bash "$D/guard-cluster-e-smells.sh" >/dev/null 2>&1; }
reset; cluster "$bad_tsx"; cluster "$ok_tsx"; sleep 0.3
expect "guard-cluster-e-smells: fire then clean edit of the same file is heeded" guard-cluster-e-smells 1 0
reset; cluster "$bad_tsx"; cluster "$bad_tsx"; sleep 0.3
expect "guard-cluster-e-smells: fire then the same smell again is not heeded" guard-cluster-e-smells 0 1

# ---- guard-ai-signature ----
sig='Footer line
Co-Authored-By: Claude <noreply@anthropic.com>'
aisig() { jq -nc --arg s "$SID" --arg c "$1" '{tool_name:"Write", session_id:$s, tool_input:{file_path:"/tmp/heedk/notes.md", content:$c}}' | bash "$D/guard-ai-signature.sh" 2>/dev/null; }
reset; out=$(aisig "$sig"); aisig "A clean line." >/dev/null
echo "$out" | jq -e '.decision=="block"' >/dev/null 2>&1 && ok "guard-ai-signature: the signature still blocks" || bad "guard-ai-signature: the signature still blocks"
expect "guard-ai-signature: block then a clean write of the file is heeded" guard-ai-signature 1 0
reset; aisig "$sig" >/dev/null; aisig "$sig" >/dev/null
expect "guard-ai-signature: block then the same signature again is not heeded" guard-ai-signature 0 1

# ---- guard-prose-quality (a verdict-first opener in a .md file) ----
verdict='Done. The work is finished and everything works as intended without any remaining problems at all today.'
clean_prose='The hook reads the file after the edit and counts the lines that start with a time of day.'
prose() { jq -nc --arg s "$SID" --arg c "$1" '{tool_name:"Write", session_id:$s, tool_input:{file_path:"/tmp/heedk/page.md", content:$c}}' | bash "$D/guard-prose-quality.sh" 2>/dev/null; }
reset; out=$(prose "$verdict"); prose "$clean_prose" >/dev/null
echo "$out" | jq -e '.decision=="block"' >/dev/null 2>&1 && ok "guard-prose-quality: a verdict opener still blocks" || bad "guard-prose-quality: a verdict opener still blocks"
expect "guard-prose-quality: block then clean prose in the same file is heeded" guard-prose-quality 1 0
reset; prose "$verdict" >/dev/null; prose "$verdict" >/dev/null
expect "guard-prose-quality: block then the same opener again is not heeded" guard-prose-quality 0 1

# ---- warn-git-add-enumeration ----
# The hook stays quiet while another live session shares the cwd; stub the peer
# lookup so a real sibling session cannot change this test's answer.
mkdir -p "$T/bin"
printf '#!/bin/sh\necho '"'"'{"peers":[]}'"'"'\n' > "$T/bin/claude-ipc"
chmod +x "$T/bin/claude-ipc"
gitadd() { jq -nc --arg s "$SID" --arg c "$1" '{tool_name:"Bash", session_id:$s, tool_input:{command:$c}}' | PATH="$T/bin:$PATH" bash "$D/warn-git-add-enumeration.sh" 2>/dev/null; }
many='git add a/1.ts a/2.ts a/3.ts a/4.ts a/5.ts'
reset; gitadd "$many" >/dev/null; gitadd "git add -A" >/dev/null
expect "warn-git-add-enumeration: enumeration then a short add is heeded" warn-git-add-enumeration 1 0
reset; gitadd "$many" >/dev/null; gitadd "$many" >/dev/null
expect "warn-git-add-enumeration: enumeration twice is not heeded" warn-git-add-enumeration 0 1
reset; gitadd "$many" >/dev/null; gitadd "ls -la" >/dev/null
expect "warn-git-add-enumeration: an unrelated command settles nothing" warn-git-add-enumeration 0 0

# ---- prefer-ripgrep ----
rgcmd() { jq -nc --arg s "$SID" --arg c "$1" '{tool_name:"Bash", session_id:$s, tool_input:{command:$c}}' | bash "$RIPGREP_HOOK" 2>/dev/null; }
reset; rgcmd "grep -rn foo src/" >/dev/null; rgcmd "rg -n foo src/" >/dev/null
expect "prefer-ripgrep: grep then a non-grep command is heeded" prefer-ripgrep 1 0
reset; rgcmd "grep -rn foo src/" >/dev/null; rgcmd "grep -rn bar src/" >/dev/null
expect "prefer-ripgrep: grep twice in a row is not heeded" prefer-ripgrep 0 1
reset; rgcmd 'echo "grep -rn foo"' >/dev/null; rgcmd "ls" >/dev/null
expect "prefer-ripgrep: a mention of grep never arms a marker" prefer-ripgrep 0 0

reset
echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
