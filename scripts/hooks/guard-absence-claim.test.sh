#!/usr/bin/env bash
# Lag-regression tests for guard-absence-claim.sh: the claim is read from the Stop
# input's last_assistant_message, never the one-message-stale transcript tail.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/guard-absence-claim.sh"
T=$(mktemp -d)
export WARN_LOG_STORE="$T/warn.jsonl"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
if [ -f "$HOME/.claude/.no-absence-claim-gate" ]; then echo "mute file present, test would pass vacuously"; exit 2; fi

BAD_REPLY='The file `scripts/hooks/lag-fixture-missing.sh` does not exist.'
CLEAN_REPLY="Everything in that directory is accounted for."

run() { # run <sid> <reply> <transcript-tail-reply>
  local tp="$T/$1.jsonl"
  { jq -nc '{type:"user", message:{role:"user", content:"does it exist?"}}'
    jq -nc --arg t "$3" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
  jq -nc --arg s "$1" --arg m "$2" --arg tp "$tp" --arg cwd "$T" \
    '{session_id:$s, transcript_path:$tp, cwd:$cwd, last_assistant_message:$m}' | bash "$HOOK" 2>/dev/null
}
fires() { printf '%s' "$1" | jq -e '.decision == "block" or (.systemMessage // "" | test("absence-claim"))' >/dev/null 2>&1; }
ids="lagab001 lagab002 lagab003"
cleanup() { for s in $ids; do rm -f /tmp/claude-absence-claim-$s; done; }
cleanup

out=$(run lagab001 "$BAD_REPLY" "$CLEAN_REPLY")
fires "$out" && ok "current reply asserts an ungrounded absence, clean tail: fires" || bad "current bad, clean tail: fires ($out)"

out=$(run lagab002 "$CLEAN_REPLY" "$BAD_REPLY")
[ -z "$out" ] && ok "current reply clean, absence-claiming tail: silent" || bad "current clean, bad tail: silent ($out)"

tp="$T/lagab003.jsonl"
{ jq -nc '{type:"user", message:{role:"user", content:"x"}}'
  jq -nc --arg t "$BAD_REPLY" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
out=$(jq -nc --arg tp "$tp" --arg cwd "$T" '{session_id:"lagab003", transcript_path:$tp, cwd:$cwd}' | bash "$HOOK" 2>/dev/null)
fires "$out" && ok "no last_assistant_message: falls back to the transcript" || bad "fallback to transcript ($out)"

# Path C: a skill claimed absent is checked on disk. adversarial-review is a real
# user skill (the founding case); zz-no-such-skill-x exists nowhere.
[ -f "$HOME/.claude/skills/adversarial-review/SKILL.md" ] || { echo "fixture skill missing"; exit 2; }
blocks() { printf '%s' "$1" | jq -e '.decision == "block"' >/dev/null 2>&1; }
ids="$ids skab0001 skab0002 skab0003 skab0004 skab0005 skab0006 skab0007"
cleanup
out=$(run skab0001 "There is no /adversarial-review skill installed here, so I ran an ad-hoc reviewer." "$CLEAN_REPLY")
blocks "$out" && ok "skill: '/adversarial-review' claimed absent while on disk: blocks" || bad "skill on disk: blocks ($out)"
out=$(run skab0002 'The `adversarial-review` skill is not installed in this session.' "$CLEAN_REPLY")
blocks "$out" && ok "skill: backticked name 'is not installed': blocks" || bad "backticked skill: blocks ($out)"
out=$(run skab0003 "The adversarial-review skill isn't in my skill listing, so I can't run it." "$CLEAN_REPLY")
printf '%s' "$out" | rg -q 'not installed|on disk at' && ok "skill: 'isn't in my skill listing' names the on-disk path" || bad "listing phrasing ($out)"
out=$(run skab0004 "There is no /zz-no-such-skill-x skill installed, so I did it by hand." "$CLEAN_REPLY")
blocks "$out" && bad "skill: unknown name blocked ($out)" || ok "skill: a name found nowhere stays silent"
out=$(run skab0005 "I ran /adversarial-review and it found two issues." "$CLEAN_REPLY")
[ -z "$out" ] && ok "skill: using a skill (no absence claim) is silent" || bad "plain skill mention silent ($out)"
out=$(run skab0006 "There is no /adversarial-review skill installed here." "$CLEAN_REPLY")
out2=$(run skab0006 "There is no /adversarial-review skill installed here." "$CLEAN_REPLY")
{ blocks "$out" && ! blocks "$out2"; } && ok "skill: same claim twice blocks once, then steps aside" || bad "loop safety ($out2)"
out=$(run skab0007 "The adversarial-review skill does not exist on this machine." "$CLEAN_REPLY")
blocks "$out" && ok "skill: 'does not exist' phrasing blocks" || bad "does-not-exist phrasing ($out)"

cleanup
echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
