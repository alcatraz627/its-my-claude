#!/usr/bin/env bash
# Keeps agents from spawning stray copies of Ghostty and from closing the owner's.
#
# Owner ruling 2026-11-02. `open -na Ghostty` starts a second copy of the app that
# restores the owner's tabs, so every open goes through ghostty-open, which adds a
# tab to the owner's window. Killing or quitting Ghostty takes every live session
# with it, and no agent has a reason to do that.
#
# PreToolUse on Bash. Only commands the shell would really run are judged, so a
# mention in an echo or a commit message passes.
# Mute: touch ~/.claude/.no-ghostty-gate
set -uo pipefail
[ -f "$HOME/.claude/.no-ghostty-gate" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

deny() {
  jq -cn --arg r "⛔ ghostty: $1 Mute: touch ~/.claude/.no-ghostty-gate" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}'
  exit 0
}

[ "$(printf '%s' "$input" | jq -r '.tool_name // empty')" = "Bash" ] || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# Cheap exit: a command that names neither Ghostty nor a kill cannot be judged here.
printf '%s' "$cmd" | rg -qi 'ghostty|\bkill\b' 2>/dev/null || exit 0

if norm=$(printf '%s' "$cmd" | python3 "$HOME/.claude/scripts/hooks/shellparse.py" lines 2>/dev/null); then
  lines="$norm"
else
  lines="$cmd"
fi

while IFS= read -r line; do
  [ -n "$line" ] || continue
  if printf '%s' "$line" | rg -qi '^\s*(\S*/)?open\s+(.*\s)?(-[a-z]*n[a-z]*|--new)\s(.*\s)?\S*ghostty' 2>/dev/null \
     || printf '%s' "$line" | rg -qi '^\s*(\S*/)?open\s+.*ghostty\S*\s+(.*\s)?(-[a-z]*n[a-z]*|--new)(\s|$)' 2>/dev/null; then
    deny "open -n starts a second copy of Ghostty that restores the owner's tabs. Use ~/.claude/scripts/ghostty/ghostty-open --cwd DIR -- COMMAND, which adds a tab to the owner's window."
  fi
  # The binary itself starts a copy, except its +actions (ghostty +version, +list-fonts).
  if printf '%s' "$line" | rg -q '^\s*(\S*/)?[Gg]hostty(\s|$)' 2>/dev/null \
     && ! printf '%s' "$line" | rg -q '^\s*(\S*/)?[Gg]hostty\s+\+' 2>/dev/null; then
    deny "running the ghostty binary starts a separate copy. Use ~/.claude/scripts/ghostty/ghostty-open --cwd DIR -- COMMAND."
  fi
  if printf '%s' "$line" | rg -qi '^\s*(\S*/)?(pkill|killall)\b.*ghostty' 2>/dev/null \
     || printf '%s' "$line" | rg -qi '^\s*(\S*/)?kill\b.*ghostty' 2>/dev/null; then
    deny "this would kill Ghostty and every session in it."
  fi
  if printf '%s' "$line" | rg -qi 'osascript.*ghostty.*\b(quit|close|delete)\b|osascript.*\b(quit|close)\b.*ghostty' 2>/dev/null; then
    deny "this would close the owner's Ghostty window or tab."
  fi
  # A bare `kill 80803` names no app, so look the numbers up.
  if printf '%s' "$line" | rg -q '^\s*(\S*/)?kill\b' 2>/dev/null; then
    for pid in $(printf '%s' "$line" | rg -o '\b[0-9]{2,}\b' 2>/dev/null); do
      name=$(ps -o comm= -p "$pid" 2>/dev/null)
      case "$name" in
        *[Gg]hostty*) deny "pid $pid is Ghostty; killing it closes every session." ;;
      esac
    done
  fi
done <<< "$lines"
exit 0
