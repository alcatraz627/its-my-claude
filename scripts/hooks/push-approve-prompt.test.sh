#!/usr/bin/env bash
# Tests for push-approve-prompt.sh, the typed-line approval channel of the push gate.
# The end-to-end case runs the REAL gate against a real repo on main and feeds its
# printed nonce to the real prompt hook; only the human typing is not exercised.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PH="$HERE/push-approve-prompt.sh"
GATE="$HERE/guard-git-push.sh"
T=$(mktemp -d)
export HOME="$T"
mkdir -p "$T/.claude"
SID="test-sess-5678"
NONCE_FILE="$T/.claude/.push-nonce-$SID"
SENTINEL="$T/.claude/.push-approved-$SID"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
mint() { jq -cn --arg n "$1" --argjson ts "$(date +%s)" '{nonce:$n, target:"/repo", why:"t", ts:$ts}' > "$NONCE_FILE"; }
say() { # say <sid> <prompt> → hook stdout
  jq -nc --arg s "$1" --arg p "$2" '{session_id:$s, prompt:$p, hook_event_name:"UserPromptSubmit"}' | bash "$PH" 2>/dev/null
}
reset() { rm -f "$SENTINEL" "$NONCE_FILE"; }

echo "== the typed line approves, from any client =="
reset; mint abcd1234
out=$(say "$SID" "approve push abcd1234")
[ -f "$SENTINEL" ] && ok "the exact line writes the sentinel" || bad "no sentinel after the exact line"
[ -f "$NONCE_FILE" ] && ok "the nonce stays until the push consumes it" || bad "nonce dropped before the push"
printf '%s' "$out" | rg -q 'Re-run the same push now' && ok "the agent is told to push" || bad "no push instruction"
reset; mint abcd1234
say "$SID" "Approve Push ABCD1234 and then carry on with #43" >/dev/null
[ -f "$SENTINEL" ] && ok "case and surrounding words do not matter" || bad "mixed case or extra words refused"

echo "== everything else writes nothing =="
reset; mint abcd1234
out=$(say "$SID" "approve push ffff0000")
[ ! -f "$SENTINEL" ] && ok "wrong nonce: no sentinel" || bad "wrong nonce wrote a sentinel"
printf '%s' "$out" | rg -q 'not the pending one' && ok "wrong nonce: the agent is told to show the line again" || bad "wrong nonce: silent"
reset; mint abcd1234
out=$(say "$SID" "keep going with #43")
[ ! -f "$SENTINEL" ] && ok "an unrelated message: no sentinel" || bad "unrelated message wrote a sentinel"
printf '%s' "$out" | rg -q 'approve push abcd1234' && ok "and the nag carries the line to type" || bad "no nag on an unrelated message"
printf '%s' "$out" | rg -q 'never call AskUserQuestion' && ok "the nag tells the agent not to halt on it" || bad "no non-halt instruction"
reset
out=$(say "$SID" "approve push abcd1234")
[ ! -f "$SENTINEL" ] && [ -z "$out" ] && ok "no push pending: silent, no sentinel" || bad "no nonce pending but something happened: $out"
reset; mint abcd1234
say "other-sess-9999" "approve push abcd1234" >/dev/null
[ ! -f "$SENTINEL" ] && [ ! -f "$T/.claude/.push-approved-other-sess-9999" ] && ok "another session's message: no sentinel" || bad "cross-session message wrote a sentinel"
reset; mint abcd1234
out=$(say "$SID" "<task-notification>approve push abcd1234</task-notification>")
[ ! -f "$SENTINEL" ] && [ -z "$out" ] && ok "a machine turn carrying the token is ignored" || bad "a machine turn approved the push"

echo "== the pending states nag differently =="
reset; mint abcd1234; : > "$SENTINEL"
out=$(say "$SID" "what is left?")
printf '%s' "$out" | rg -q 'approved \(sentinel present\) and not yet run' && ok "sentinel present: the agent is told to push, not to ask" || bad "sentinel present but the nag asked again"
reset; mint abcd1234
out=$(say "$SID" "cancel push please")
[ ! -f "$NONCE_FILE" ] && [ ! -f "$SENTINEL" ] && ok "cancel push clears the pending push" || bad "cancel left files behind"
printf '%s' "$out" | rg -q 'cancelled' && ok "and the agent is told not to push" || bad "cancel: silent"

echo "== end to end against the real gate =="
reset
git init -q -b main "$T/repo" && (cd "$T/repo" && git commit -q --allow-empty -m x)
gate() { jq -nc --arg c "git push origin main" --arg w "$T/repo" --arg s "$SID" '{tool_input:{command:$c}, cwd:$w, session_id:$s}' | bash "$GATE" 2>/dev/null; }
b1=$(gate)
n1=$(printf '%s' "$b1" | rg -o 'approve push [0-9a-f]{8}' | head -1 | sed 's/approve push //')
[ -n "$n1" ] && ok "gate blocks and prints the typed line ($n1)" || bad "gate printed no typed line: $b1"
printf '%s' "$b1" | rg -qi 'do not call AskUserQuestion' && ok "the block text says not to halt on an ask" || bad "block text still points at the ask tool first"
touch -t 202601010000 "$NONCE_FILE"
b2=$(gate)
n2=$(printf '%s' "$b2" | rg -o 'approve push [0-9a-f]{8}' | head -1 | sed 's/approve push //')
[ "$n2" = "$n1" ] && ok "a nonce never expires on the owner: a re-blocked push after a day prints the same one" || bad "the nonce rotated under the owner ($n1 -> $n2)"
say "$SID" "approve push $n1" >/dev/null
[ -f "$SENTINEL" ] && ok "the typed line with the gate's nonce writes the sentinel" || bad "gate nonce not accepted by the prompt hook"
b3=$(gate)
[ -z "$b3" ] && ok "gate allows the push after the typed line" || bad "gate still blocks after approval: $b3"
[ ! -f "$SENTINEL" ] && [ ! -f "$NONCE_FILE" ] && ok "sentinel and nonce consumed by the one push" || bad "files survived the push"
b4=$(gate)
n4=$(printf '%s' "$b4" | rg -o 'approve push [0-9a-f]{8}' | head -1 | sed 's/approve push //')
[ -n "$n4" ] && [ "$n4" != "$n1" ] && ok "next push blocks again with a fresh nonce" || bad "second push not re-gated with a new nonce"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
