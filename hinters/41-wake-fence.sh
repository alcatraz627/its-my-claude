#!/usr/bin/env bash
# 41-wake-fence.sh — UserPromptSubmit hinter: a cron wake while the owner is
# mid-conversation picks nothing.
#
# The wake skill's step-2 fence (2026-09-08) says exactly this, as prose inside
# the cron payload. A cron armed before that day carries the old payload until
# the lane re-arms it, and on 2026-09-08 forge-console's transcript held 76 wake
# prompts and zero copies of the fence: the owner asked "What are you doing?"
# two minutes after a wake started a button-sizing row with eight of his gates
# open. This hinter is the fence on the ENGINE: it reads the wake prompt itself,
# checks the transcript for the owner's last typed prompt, and injects the
# fence when he spoke inside the window, whatever text the cron carries.
#
# State: none. Mute: touch ~/.claude/.no-wake-fence  (machine-wide until removed)
set -uo pipefail
PROMPT=$(cat 2>/dev/null || echo "")
[ -f "$HOME/.claude/.no-wake-fence" ] && exit 0
case "$PROMPT" in "Wake check"*|"Heartbeat"*) ;; *) exit 0 ;; esac
SID="${CLAUDE_HINT_SID:-${CLAUDE_CODE_SESSION_ID:-}}"; [ -n "$SID" ] || exit 0
IDLE_S="${WAKE_FENCE_IDLE_S:-1800}"
TP="${CLAUDE_HINT_TRANSCRIPT:-}"
if [ -z "$TP" ]; then
  for cand in "$HOME"/.claude/projects/*/"$SID".jsonl; do [ -f "$cand" ] && { TP="$cand"; break; }; done
fi
[ -n "$TP" ] && [ -f "$TP" ] || exit 0
quiet=$(python3 "$HOME/.claude/scripts/session-mgmt/owner-quiet.py" "$TP" 2>/dev/null)
case "$quiet" in ''|unknown|*[!0-9]*) exit 0 ;; esac
[ "$quiet" -lt "$IDLE_S" ] || exit 0
m=$((quiet / 60))
printf '%s\n' "[wake-fence] The owner typed in this session ${m} min ago. This wake picks NOTHING: reconcile the board if the payload asks, then say in one line that he is mid-conversation and stop. A wake that starts a row while he is talking pulls the lane off what he is asking for right now (wake SKILL.md step 2, 2026-09-08). This fence binds whatever text your armed cron carries. (mute: touch ~/.claude/.no-wake-fence)"
