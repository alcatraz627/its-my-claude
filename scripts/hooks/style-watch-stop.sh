#!/usr/bin/env bash
# style-watch-stop.sh — Stop hook, collector half of the style watcher.
#
# Gathers files this session edited (the /tmp/claude-edited-files-<sid8>
# tracker), drops everything the watcher must not touch (critic-gated
# deliverables, scratch, machine-written digests, unchanged-since-last-look),
# and hands survivors to a DETACHED background worker. Exits 0 immediately —
# zero latency on the user's turn; the worker's verdict reaches the agent at
# the NEXT turn via hinters/02-style-watch.sh.
#
# Division of labor (audit P19, mig 0035): prose-smell-stop.sh owns the CHAT
# message; this stack owns FILES. Deliverables the readers-advocate already
# gated are skipped via the sha-keyed voice-passed marker (style-log.sh
# --check) — the watcher never re-nags what the critic passed or what the user
# is about to review themselves.
#
# Mute: touch ~/.claude/.no-style-watch (machine-wide) · STYLE_WATCH_OFF=1 (process)
set -uo pipefail

[ -f "$HOME/.claude/.no-style-watch" ] && exit 0
[ "${STYLE_WATCH_OFF:-0}" = "1" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null || echo "{}")
SID=$(echo "$INPUT" | jq -r '.session_id // empty'); [ -n "$SID" ] || exit 0
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
SID8="${SID:0:8}"
TRACKER="/tmp/claude-edited-files-$SID8"
[ -f "$TRACKER" ] || exit 0

STYLE_DIR="$HOME/.claude/style"
PROCESSED="$STYLE_DIR/.watch-processed-$SID8"
LOGGER="$HOME/.claude/scripts/style/style-log.sh"
CANDIDATES=""

while IFS= read -r f; do
  [ -f "$f" ] || continue
  case "$f" in
    */style/derived/*|*/_*.claude.md|*.jsonl|*/.git/*) continue ;;
    *.md|*.ts|*.tsx|*.js|*.jsx|*.py|*.sh) ;;
    *) continue ;;
  esac
  sha=$(shasum -a 256 "$f" 2>/dev/null | cut -d' ' -f1); [ -n "$sha" ] || continue
  grep -q "^$f:$sha$" "$PROCESSED" 2>/dev/null && continue   # unchanged since last look
  bash "$LOGGER" --check "$f" >/dev/null 2>&1 && continue    # critic already gated this exact content
  CANDIDATES="$CANDIDATES$f"$'\n'
done < <(sort -u "$TRACKER")

[ -n "$CANDIDATES" ] || exit 0
printf '%s' "$CANDIDATES" | head -20 > "/tmp/style-watch-batch-$SID8"
nohup bash "$HOME/.claude/scripts/style/style-watch-worker.sh" "$SID8" "$CWD" \
  "/tmp/style-watch-batch-$SID8" >/dev/null 2>&1 &
exit 0
