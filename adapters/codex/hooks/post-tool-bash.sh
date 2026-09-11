#!/usr/bin/env bash
# post-tool-bash.sh — codex PostToolUse[Bash], async: land queued gcc calls now,
# hand the receipts back mid-turn, and tell the seat when its brief changed.
#
# Registered with "async": true, so codex does not wait on it. Codex delivers a
# background hook's additionalContext at the next safe point of the running
# turn (proven 2026-09-10 with receipts), which is the only channel that reaches
# a headless seat mid-run: UserPromptSubmit never fires during `codex exec`.
# So the brief-changed check lives here (review finding B4). The brief path
# arrives in GCC_BRIEF from codex-gcc exec --brief; its mtime at first sight
# is remembered per session and any later change is announced once per change.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
gcc_read_input
bash "$CODEX_GCC_ROOT/hooks/drain-outbox.sh" "$SID" >/dev/null 2>&1 || true

parts=()
r=$(bash "$CODEX_GCC_ROOT/hooks/receipts.sh" "$SID" 2>/dev/null)
[ -n "$r" ] && parts+=("[gcc·codex] receipts for calls you queued through gcc:
$r")

if [ -n "${GCC_BRIEF:-}" ] && [ -f "$GCC_BRIEF" ]; then
  seen="$GCC_OUTBOX_DIR/$SID.brief.mtime"; mkdir -p "$GCC_OUTBOX_DIR" 2>/dev/null
  now=$(stat -f %m "$GCC_BRIEF" 2>/dev/null || stat -c %Y "$GCC_BRIEF" 2>/dev/null || echo 0)
  if [ ! -f "$seen" ]; then printf '%s' "$now" > "$seen"
  elif [ "$(cat "$seen")" != "$now" ]; then
    printf '%s' "$now" > "$seen"
    parts+=("[gcc·codex] your brief changed at $(date -r "$now" '+%H:%M:%S' 2>/dev/null || echo "$now"): $GCC_BRIEF. Re-read it before your next step; the planner steered you mid-run.")
  fi
fi

[ "${#parts[@]}" -gt 0 ] || exit 0
jq -cn --arg t "$(printf '%s\n\n' "${parts[@]}")" '{hookSpecificOutput:{hookEventName:"PostToolUse", additionalContext:$t}}'
exit 0
