#!/usr/bin/env bash
# counter-gate-stop.sh — Stop hook, TELEMETRY tier: measure every substantial
# reply as numbers; never judge taste (regfric D2, owner-approved 2026-08-20).
#
# gcp-fable's evidence: four same-day atones, prose review caught none, counting
# caught all. This hook turns each reply into a numbers row in
# ~/.claude/logs/counter-gate.jsonl: reply chars, prompt words, budget breach,
# first-question position, completion verbs, bare ids lacking subjects. It
# shows nothing: length is judged by terse-reply-stop.sh, voice by prose-smell,
# structure by dense-briefing-shapes.
# Deliberately does NOT re-count what prose-smell owns (em-dash, bold, labels).
#
# Mute: COUNTER_GATE_OFF=1 · touch ~/.claude/.no-counter-gate
set -uo pipefail
[ "${COUNTER_GATE_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.no-counter-gate" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty'); tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
[ -n "$sid" ] && [ -f "$tp" ] || exit 0
sid8="${sid:0:8}"
. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null || exit 0
tj=$(tail -n 600 "$tp" 2>/dev/null) || exit 0
# The reply is the Stop input's last_assistant_message: the transcript tail lags one
# message at Stop time (hook_last_assistant_text in hook-common.sh). The prompt still
# comes from the transcript, where the user's message is already flushed.
text=$(hook_last_assistant_text "$input" "$tp")
[ -n "$text" ] || exit 0
prompt=$(printf '%s\n' "$tj" | jq -rc 'select(.type=="user")' 2>/dev/null | tail -1 | jq -r 'if (.message.content|type)=="string" then .message.content else (.message.content[]? | select(.type=="text") | .text) end' 2>/dev/null | head -c 2000)
rchars=$(printf '%s' "$text" | wc -c | tr -d ' ')
[ "$rchars" -ge 400 ] || exit 0
pwords=$(printf '%s' "$prompt" | rg -v '^<|hook additional context|^  ok ' | wc -w | tr -d ' ')
# budget: <=15-word prompt or pure question earns ~900c; else 400c/word capped 20k
if [ "${pwords:-0}" -le 15 ]; then budget=900; else budget=$(( pwords * 400 )); [ $budget -gt 20000 ] && budget=20000; fi
firstq=$(printf '%s' "$text" | rg -bo '\?' 2>/dev/null | head -1 | cut -d: -f1); firstq=${firstq:--1}
qpos="null"; [ "$firstq" -ge 0 ] && qpos=$(python3 -c "print(round($firstq/$rchars,2))" 2>/dev/null || echo null)
verbs=$(printf '%s' "$text" | rg -cio '\b(done|complete[d]?|verified|passing|green|confirmed|all set)\b' 2>/dev/null || echo 0)
bare=$(printf '%s' "$text" | python3 -c "
import re, sys
n = 0
for line in sys.stdin:
    ms = list(re.finditer(r'#\\d{1,4}\\b', line))
    for i, m in enumerate(ms):
        nxt = ms[i+1].start() - m.end() if i+1 < len(ms) else 999
        trail = line[m.end():m.end()+30]
        glossed = re.search(r'\\b[A-Za-z]{4,}\\b', trail[:nxt if nxt < 30 else 30])
        if nxt < 15 or not glossed: n += 1
print(n)" 2>/dev/null || echo 0)
breach=$([ "$rchars" -gt "$budget" ] && echo true || echo false)
mkdir -p "$HOME/.claude/logs"
printf '{"ts":"%s","sid":"%s","rchars":%s,"pwords":%s,"budget":%s,"breach":%s,"qpos":%s,"verbs":%s,"bare_ids":%s}\n' \
  "$(date -u +%FT%TZ)" "$sid8" "$rchars" "${pwords:-0}" "$budget" "$breach" "$qpos" "${verbs:-0}" "${bare:-0}" >> "$HOME/.claude/logs/counter-gate.jsonl"
# Numbers only: reply length is terse-reply-stop.sh's to judge (2026-10-14), so
# a breach is recorded above and never shown.
exit 0
