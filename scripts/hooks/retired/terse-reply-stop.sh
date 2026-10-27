#!/usr/bin/env bash
# lifecycle: tune-able hook (owner 2026-10-13: "please tone down the word salad, please add a gcc hook to enforce a more terse response")
# instrument: warn-log.sh --hook terse-reply
# review-by: 2026-11-13
# retire-if: heed-rate < 40% over 100 fires
# terse-reply-stop.sh: Stop hook: the final assistant message is short unless the
# owner asked for length.
#
# Prose is the message minus fenced code, inline code, blockquotes and table
# rows, so a long reply made of a file listing or a command block is not
# penalised; the words around them are. Two tiers:
#   over TERSE_WARN chars  (default 1500) → a visible WARN systemMessage
#   over TERSE_LIMIT chars (default 2600) → decision:block, the turn is re-emitted
# A block is skipped when the owner's last message asked for length (detail,
# thorough, full, write-up, document, report, explain, walk me through, essay,
# long) or when the reply is the output of a skill that prints its own box.
# Loop-safe: an identical message never re-fires.
#
# Mute: TERSE_REPLY_OFF=1 (process) · touch ~/.claude/.no-terse-reply-gate
# (machine-wide, ALL sessions until removed). Policy: gates.terse_reply off|warn|enforce.

set -uo pipefail
[ "${TERSE_REPLY_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.no-terse-reply-gate" ] && exit 0
. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null; hook_snoozed terse-reply && exit 0
ENFORCE="${TERSE_REPLY_ENFORCE:-1}"
case "$(bash "${POL_SH:-$HOME/.claude/scripts/pol/pol.sh}" get gates.terse_reply 2>/dev/null)" in
  off) exit 0 ;;
  warn) ENFORCE=0 ;;
  enforce) ENFORCE=1 ;;
esac

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v rg >/dev/null 2>&1 || exit 0
command -v shasum >/dev/null 2>&1 || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0
sid8="${sid:0:8}"

tail_json=$(tail -n 400 "$tp" 2>/dev/null) || exit 0
# The reply that just ended the turn comes from the Stop input; the transcript tail
# lags one message at Stop time (hook_last_assistant_text in hook-common.sh).
text=$(hook_last_assistant_text "$input" "$tp")
[ -n "$text" ] || exit 0

# A skill's completion box or a lede block is a renderer's output, not prose to trim.
printf '%s' "$text" | rg -q '┌─ 🏁 done|── lede·' && exit 0

# The owner's last message, to see whether length was asked for.
last_user=$(printf '%s\n' "$tail_json" | jq -rc 'select(.type=="user")' 2>/dev/null | tail -n 1 \
  | jq -r '.message.content | if type=="string" then . else (.[]? | select(.type=="text") | .text) end' 2>/dev/null)
asked_long=0
printf '%s' "$last_user" | rg -qi '\b(detail(ed|s)?|thorough(ly)?|full(y)?|write[- ]?up|document|report|explain|walk me through|essay|long(er)?|comprehensive|in depth)\b' && asked_long=1

prose=$(printf '%s\n' "$text" \
  | awk 'BEGIN{f=0} /^[[:space:]]*```/{f=!f; next} !f{print}' \
  | sed -e 's/`[^`]*`//g' -e '/^[[:space:]]*>/d' -e '/^[[:space:]]*|/d')
plen=$(printf '%s' "$prose" | wc -c | tr -d ' ')
warn_at="${TERSE_WARN:-1500}"
limit="${TERSE_LIMIT:-2600}"
[ "$plen" -ge "$warn_at" ] || exit 0

h=$(printf '%s' "$text" | shasum | cut -c1-12)
dir="/tmp/claude-terse-$sid8"; marker="$dir/fired-$h"
mkdir -p "$dir"; [ -f "$marker" ] && exit 0; touch "$marker"

msg="This reply carries ${plen} chars of prose (warn ${warn_at}, limit ${limit}). Lead with the one thing the owner must do or know, then at most a handful of short bullets; put detail in the file and link it. (mute: touch ~/.claude/.no-terse-reply-gate · TERSE_LIMIT=<n> to tune)"
if [ "$ENFORCE" = "1" ] && [ "$plen" -ge "$limit" ] && [ "$asked_long" = "0" ]; then
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook terse-reply --action block --heeded unknown 2>/dev/null || true
  jq -cn --arg r "[terse-reply] $msg" '{decision:"block", reason:$r}'
else
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook terse-reply --action soft --heeded unknown 2>/dev/null || true
  jq -n --arg m "[terse-reply WARN] $msg" '{systemMessage: $m}'
fi
exit 0
