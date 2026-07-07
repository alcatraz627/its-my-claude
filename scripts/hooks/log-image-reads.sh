#!/bin/bash
# Log every Claude Code native image read (Read tool on an image file) so image-tool
# token cost + usage can be reviewed against the alternatives (`see` ≈ free local,
# gemini ≈ abundant separate budget). One JSONL line per image read:
#   {ts, session_id, file, bytes, w, h, est_tokens}
# est_tokens ≈ (w*h)/750 — the Claude vision sizing rule of thumb; a proxy, not billing.
# Companion streams: lm see-history / imagine-history / (future) gem-history.
# Review cadence: gcc-schedule `image-tools-review` (one-shot 2026-07-28T15:00).
# Mute: touch ~/.claude/.no-image-read-log
[ -f "$HOME/.claude/.no-image-read-log" ] && exit 0

payload="$(cat)"
file=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
case "$(printf '%s' "$file" | tr 'A-Z' 'a-z')" in
  *.png|*.jpg|*.jpeg|*.gif|*.webp|*.bmp|*.tiff|*.heic) : ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

sid=$(printf '%s' "$payload" | jq -r '.session_id // "unknown"' 2>/dev/null)
bytes=$(stat -f %z "$file" 2>/dev/null || echo 0)
dims=$(sips -g pixelWidth -g pixelHeight "$file" 2>/dev/null | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w+0, h+0}')
w=${dims%% *}; h=${dims##* }
est=$(( w * h / 750 ))

mkdir -p "$HOME/.claude/logs"
jq -cn --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg sid "$sid" --arg f "$file" \
  --argjson b "$bytes" --argjson w "${w:-0}" --argjson h "${h:-0}" --argjson t "$est" \
  '{ts:$ts, session_id:$sid, file:$f, bytes:$b, w:$w, h:$h, est_tokens:$t}' \
  >> "$HOME/.claude/logs/image-reads.jsonl" 2>/dev/null
exit 0
