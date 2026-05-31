#!/usr/bin/env bash
# cleanup-comments-nudge.sh — Stop hook. Suggests /cleanup-comments when the
# code edited this session carries comment-hygiene findings (em dashes,
# [claude@] tags, decorative banners, plan refs).
#
# Fires on SUBSTANCE, never on edit volume. It runs the cleanup-comments
# detector over exactly the files touched this session; a large but clean
# refactor produces zero findings and stays silent. This is deliberate: the
# old volume-based Stop nudge nagged on big clean batches and was removed
# (see review-gate-stop.sh). One nudge per fresh batch of findings, deduped by
# count so it never re-nags every turn.
#
# Non-blocking: emits a systemMessage, never blocks the turn.
# Mute: touch ~/.claude/.no-cleanup-comments-nudge
# Tune the floor: CLEANUP_NUDGE_MIN (default 4).
set -uo pipefail

[ -f "$HOME/.claude/.no-cleanup-comments-nudge" ] && exit 0

DETECT="$HOME/.claude/skills/cleanup-comments/detect.py"
[ -f "$DETECT" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null) || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
sid8="${sid:0:8}"

EDITED="/tmp/claude-edited-files-${sid8}"
MARK="/tmp/claude-cleanup-nudge-${sid8}"
[ -f "$EDITED" ] || exit 0

MIN="${CLEANUP_NUDGE_MIN:-4}"

# Code files edited this session that still exist on disk.
files=()
while IFS= read -r f; do
  case "$f" in
    *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs | *.py)
      [ -f "$f" ] && files+=("$f")
      ;;
  esac
done < <(sort -u "$EDITED")
[ "${#files[@]}" -gt 0 ] || exit 0

# Total tier1 (strip) + tier2 (voice) findings across those files.
total=$(python3 "$DETECT" "${files[@]}" 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print(0); sys.exit(0)
t = d.get("totals", {})
print(int(t.get("tier1_strip", 0)) + int(t.get("tier2_voice", 0)))
' 2>/dev/null)
case "$total" in '' | *[!0-9]*) exit 0 ;; esac
[ "$total" -ge "$MIN" ] || exit 0

# Dedup: nudge on the first crossing, then only on a fresh batch (growth >= MIN).
last=0
[ -f "$MARK" ] && last=$(cat "$MARK" 2>/dev/null || echo 0)
case "$last" in '' | *[!0-9]*) last=0 ;; esac
if [ "$last" -ne 0 ] && [ "$((total - last))" -lt "$MIN" ]; then
  exit 0
fi
printf '%s' "$total" >"$MARK" 2>/dev/null || true

msg="cleanup-comments: ${total} comment findings in code you wrote this session (em dashes, [claude@] tags, banners, plan refs). Run /cleanup-comments to preview and clean them. Mute: touch ~/.claude/.no-cleanup-comments-nudge"
jq -cn --arg m "$msg" '{systemMessage:$m}' 2>/dev/null || true
exit 0
