#!/usr/bin/env bash
# One-shot launchd target: open Ghostty and resume the statusline-fix Claude
# session on 2026-06-02 15:00 IST, then self-unload so it never fires again.
#
# Why a date guard: launchd's StartCalendarInterval has no Year key, so
# Month=6 Day=2 would fire EVERY June 2 forever. The guard + self-unload
# below make this a true one-shot.

set -uo pipefail

SESSION_UUID="5da7133c-3e35-46de-95c2-f1d50b5fb715"
PROJECT_DIR="$HOME/.claude"
LABEL="com.alcatraz.statusline-fix-resume"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
FIRE_DATE="2026-06-02"

today=$(date '+%Y-%m-%d')
if [[ "$today" != "$FIRE_DATE" ]]; then
  echo "[$today] not the intended fire date $FIRE_DATE — exiting without action"
  exit 0
fi

# Launch a fresh Ghostty window. `-e` runs a command inside; we wrap in a
# login zsh so ~/.zshenv loads (STATUSLINE_WIDTH_DEBUG=1, PATH, etc).
echo "[$today $(date '+%T')] opening Ghostty + claude --resume $SESSION_UUID"
open -na 'Ghostty.app' --args -e \
  zsh -l -c "cd \"$PROJECT_DIR\" && exec claude --resume $SESSION_UUID"

# Self-clean: bootout + delete plist so this never fires again.
echo "[$today $(date '+%T')] self-unloading $LABEL"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$PLIST"

exit 0
