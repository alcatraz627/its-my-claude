#!/usr/bin/env bash
# Tests for push-approve-ask.sh, the ask-tool approval channel of the push gate.
#
# The 2026-07-13 incident: a stubbed osascript made every dialog test pass while
# the real binary auto-approved pushes to main. So the end-to-end case here runs
# the REAL gate against a real repo on main and feeds its own printed nonce to the
# real answer hook; the only thing not exercised is the human click, which the
# harness alone can produce. HOME is redirected so the sentinel and nonce files
# land in a temp dir and never touch the live session's.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ASK="$HERE/push-approve-ask.sh"
GATE="$HERE/guard-git-push.sh"
T=$(mktemp -d)
export HOME="$T"
mkdir -p "$T/.claude"
SID="test-sess-1234"
NONCE_FILE="$T/.claude/.push-nonce-$SID"
SENTINEL="$T/.claude/.push-approved-$SID"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

mint() { # mint <nonce> [ts]
  jq -cn --arg n "$1" --argjson ts "${2:-$(date +%s)}" '{nonce:$n, target:"/x", why:"t", ts:$ts}' > "$NONCE_FILE"
}
ask() { # ask <sid> <tool> <option-label-1> <option-label-2> <answer> [question-text]
  # tool_input carries the options the agent wrote; tool_response carries the
  # answer the harness recorded, in the shape observed in transcript fabc7070.
  local q="${6:-Push main to origin?}"
  jq -nc --arg sid "$1" --arg tool "$2" --arg o1 "$3" --arg o2 "$4" --arg a "$5" --arg q "$q" '{
    session_id:$sid, tool_name:$tool, hook_event_name:"PostToolUse",
    tool_input:{questions:[{header:"Push", question:$q, options:[{label:$o1,description:"a"},{label:$o2,description:"b"}]}]},
    tool_response:{questions:[{header:"Push", question:$q, options:[{label:$o1,description:"a"},{label:$o2,description:"b"}]}],
                   answers:{($q):$a}}
  }' | bash "$ASK" 2>/dev/null
}
reset() { rm -f "$SENTINEL" "$NONCE_FILE"; }

echo "== the documented shape approves =="
reset; mint abcd1234
out=$(ask "$SID" AskUserQuestion "Approve push abcd1234" "Do not push" "Approve push abcd1234")
[ -f "$SENTINEL" ] && ok "right nonce picked: sentinel written" || bad "right nonce picked: no sentinel"
[ ! -f "$NONCE_FILE" ] && ok "nonce consumed" || bad "nonce file survived an approval"
printf '%s' "$out" | rg -q 'sentinel is written' && ok "agent told to re-run the push" || bad "no approval context emitted"

echo "== everything else writes nothing =="
reset; mint abcd1234
ask "$SID" AskUserQuestion "Approve push abcd1234" "Do not push" "Do not push" >/dev/null
[ ! -f "$SENTINEL" ] && ok "other option picked: no sentinel" || bad "decline wrote a sentinel"
[ -f "$NONCE_FILE" ] && ok "decline keeps the nonce for a fresh ask" || bad "decline dropped the nonce"

reset; mint abcd1234
ask "$SID" AskUserQuestion "Approve push ffff0000" "Do not push" "Approve push ffff0000" >/dev/null
[ ! -f "$SENTINEL" ] && ok "wrong nonce: no sentinel" || bad "wrong nonce wrote a sentinel"

reset; mint abcd1234
ask "$SID" AskUserQuestion "Approve push abcd1234x" "Do not push" "Approve push abcd1234x" >/dev/null
[ ! -f "$SENTINEL" ] && ok "altered label (suffix): no sentinel" || bad "altered label wrote a sentinel"

reset; mint abcd1234
out=$(ask "$SID" AskUserQuestion "Approve push abcd1234" "Approve push abcd1234" "Approve push abcd1234")
[ ! -f "$SENTINEL" ] && ok "stacked deck (nonce on two options): no sentinel" || bad "stacked deck wrote a sentinel"
printf '%s' "$out" | rg -q 'exactly one' && ok "stacked deck: agent told why" || bad "stacked deck: silent"

reset; mint abcd1234
ask "$SID" AskUserQuestion "Yes" "No" "Yes" "Approve push abcd1234 ?" >/dev/null
[ ! -f "$SENTINEL" ] && ok "nonce only in the question text: no sentinel" || bad "question-text nonce wrote a sentinel"

reset
ask "$SID" AskUserQuestion "Approve push abcd1234" "Do not push" "Approve push abcd1234" >/dev/null
[ ! -f "$SENTINEL" ] && ok "no nonce pending: no sentinel" || bad "no nonce pending but a sentinel appeared"

reset; mint abcd1234 $(( $(date +%s) - 4000 ))
ask "$SID" AskUserQuestion "Approve push abcd1234" "Do not push" "Approve push abcd1234" >/dev/null
[ ! -f "$SENTINEL" ] && ok "stale nonce: no sentinel" || bad "stale nonce wrote a sentinel"
[ ! -f "$NONCE_FILE" ] && ok "stale nonce file cleared" || bad "stale nonce file kept"

reset; mint abcd1234
ask "other-sess-9999" AskUserQuestion "Approve push abcd1234" "Do not push" "Approve push abcd1234" >/dev/null
[ ! -f "$SENTINEL" ] && [ ! -f "$T/.claude/.push-approved-other-sess-9999" ] && ok "another session's answer: no sentinel" || bad "cross-session answer wrote a sentinel"

reset; mint abcd1234
ask "$SID" Bash "Approve push abcd1234" "Do not push" "Approve push abcd1234" >/dev/null
[ ! -f "$SENTINEL" ] && ok "not AskUserQuestion: no sentinel" || bad "non-ask tool wrote a sentinel"

echo "== typed under Other still counts =="
reset; mint abcd1234
ask "$SID" AskUserQuestion "Yes" "No" "  Approve push abcd1234 " >/dev/null
[ -f "$SENTINEL" ] && ok "owner typed the token (trimmed): sentinel written" || bad "typed token not accepted"

echo "== end to end against the real gate =="
reset
git init -q -b main "$T/repo" && (cd "$T/repo" && git commit -q --allow-empty -m x)
gate() { jq -nc --arg c "git push origin main" --arg w "$T/repo" --arg s "$SID" '{tool_input:{command:$c}, cwd:$w, session_id:$s}' | bash "$GATE" 2>/dev/null; }
b1=$(gate)
n1=$(printf '%s' "$b1" | rg -o 'Approve push [0-9a-f]{8}' | head -1 | sed 's/Approve push //')
[ -n "$n1" ] && ok "gate blocks and prints a nonce ($n1)" || bad "gate printed no nonce: $b1"
[ "$(jq -r .nonce "$NONCE_FILE" 2>/dev/null)" = "$n1" ] && ok "nonce file matches the printed nonce" || bad "nonce file disagrees with the block"
b2=$(gate)
n2=$(printf '%s' "$b2" | rg -o 'Approve push [0-9a-f]{8}' | head -1 | sed 's/Approve push //')
[ "$n2" = "$n1" ] && ok "re-blocked push reuses the fresh nonce" || bad "second block minted a new nonce while the first was fresh"
ask "$SID" AskUserQuestion "Approve push $n1" "Do not push" "Approve push $n1" >/dev/null
[ -f "$SENTINEL" ] && ok "owner's pick of the gate's nonce writes the sentinel" || bad "gate nonce not accepted by the answer hook"
b3=$(gate)
[ -z "$b3" ] && ok "gate allows the push after the pick" || bad "gate still blocks after approval: $b3"
[ ! -f "$SENTINEL" ] && ok "sentinel consumed by the one push" || bad "sentinel survived the push"
b4=$(gate)
n4=$(printf '%s' "$b4" | rg -o 'Approve push [0-9a-f]{8}' | head -1 | sed 's/Approve push //')
[ -n "$n4" ] && [ "$n4" != "$n1" ] && ok "next push blocks again with a fresh nonce" || bad "second push not re-gated with a new nonce"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
