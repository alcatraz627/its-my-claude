#!/usr/bin/env bash
# reply-lede-stop.sh — Stop hook, DRY-RUN tier: position 1 of a substantial
# owner-facing reply belongs to the lede block (box/close.sh), not to narrative.
#
# Sweep evidence (20260820-regfric): buried asks are answered 1/19; the lede
# block is the consumption-order fix the owner approved (D1). This hook fires a
# WOULD-BLOCK systemMessage when a long reply carries owner-owed language but no
# renderer-emitted lede signature near the top. A real decision:block waits for
# fire-rate telemetry (REPLY_LEDE_ENFORCE=1), the prose-smell promotion path.
#
# Mute: REPLY_LEDE_OFF=1 (process) · touch ~/.claude/.no-reply-lede-gate (machine-wide).
set -uo pipefail
[ "${REPLY_LEDE_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.no-reply-lede-gate" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty'); tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
[ -n "$sid" ] && [ -f "$tp" ] || exit 0
sid8="${sid:0:8}"
tail_json=$(tail -n 400 "$tp" 2>/dev/null) || exit 0
text=$(printf '%s\n' "$tail_json" | jq -rc 'select(.type=="assistant")' 2>/dev/null | tail -1 | jq -r '.message.content[]? | select(.type=="text") | .text' 2>/dev/null)
[ -n "$text" ] || exit 0
plen=$(printf '%s' "$text" | wc -c | tr -d ' ')
[ "$plen" -ge 1200 ] || exit 0
# owner-owed: the reply asks/holds something for the owner (vocab mined from the sweep)
printf '%s' "$text" | rg -qi 'your call|say the word|on your say-so|waiting on you|still yours|your read|needs you|shall i|want me to|which (option|one)|pick (one|a number)|\?\s*$' || exit 0
head400=$(printf '%s' "$text" | head -c 400)
# pass: the renderer's signature near the top, with the CURRENT nonce
nf="/tmp/claude-lede-$sid8/nonce"
if [ -f "$nf" ] && printf '%s' "$head400" | rg -q "── lede·$(cat "$nf")"; then exit 0; fi
# loop-safety: identical message never re-fires
h=$(printf '%s' "$text" | shasum | cut -c1-12); marker="/tmp/claude-lede-$sid8/fired-$h"
mkdir -p "/tmp/claude-lede-$sid8"; [ -f "$marker" ] && exit 0; touch "$marker"
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook reply-lede --sid "$sid8" --decision would-block 2>/dev/null || true
jq -n --arg m "[reply-lede WOULD-BLOCK · dry-run] This reply is ${plen}c, carries owner-owed language, and position 1 is not the lede block. Compose it with: bash ~/.claude/scripts/box/close.sh --sid $sid8 --verdict '<what is true>' --next '<one action>' [--ask 'tag|text|draft'] [--tasks] and open the reply with its output. (Enforce: REPLY_LEDE_ENFORCE=1 · mute: touch ~/.claude/.no-reply-lede-gate)" '{systemMessage: $m}'
exit 0
