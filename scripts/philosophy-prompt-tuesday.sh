#!/bin/bash
# Fires once on 2026-05-19 11:30 local time via launchd.
# Opens Ghostty, runs `claude` with an initial prompt that points the
# session at the philosophy-prompt workflow (improvement-ideas.md last
# section). Self-deletes plist + this script after firing.
#
# Caveats:
# - Requires Accessibility permission for launchd's "System Events"
#   keystroke action. First fire may prompt for it.
# - Assumes `claude` is on PATH (via ~/.zshrc).
# - Assumes Ghostty is installed at /Applications/Ghostty.app.

set -uo pipefail

LOG="$HOME/.claude/logs/philosophy-prompt-tuesday.log"
mkdir -p "$(dirname "$LOG")"
exec >> "$LOG" 2>&1
echo "=== $(date -Iseconds) firing ==="

INITIAL_PROMPT="Read the LAST section of ~/.claude/improvement-ideas.md (titled \"Prompt design with structured-goals → N-subagent generation → voting + independent pick\") and start the workflow on TaskList #53 — the philosophy poem/prose prompt for the mock pipeline llm arg. Meta-prompt first, then 5 subagents, then voting, then independent pick. Show both picks at the end."

# Activate (or launch) Ghostty
osascript <<APPLESCRIPT
tell application "Ghostty"
    activate
end tell
delay 1
tell application "System Events"
    -- New window in Ghostty (Cmd+N is the default)
    keystroke "n" using {command down}
    delay 0.6
    keystroke "claude " & quote & "$INITIAL_PROMPT" & quote
    delay 0.2
    keystroke return
end tell
APPLESCRIPT

echo "ghostty + claude launched, scheduling self-cleanup"

# Self-cleanup in a detached subshell so it survives our own removal.
PLIST="$HOME/Library/LaunchAgents/com.alcatraz.philosophy-prompt-tuesday.plist"
SELF="$0"
(
    sleep 5
    /bin/launchctl unload "$PLIST" 2>/dev/null
    /bin/rm -f "$PLIST" "$SELF"
    echo "$(date -Iseconds) cleaned up plist + self" >> "$LOG"
) &
disown
