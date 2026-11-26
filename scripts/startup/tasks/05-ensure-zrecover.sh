#!/usr/bin/env bash
# 05-ensure-zrecover.sh: std::claude::startup task.
#
# Starts the memory guard at login if nothing else did. macOS's Login Items switch can stop
# launchd from loading the guard's own entry, which silently left it off from 2026-10-11 to
# 2026-11-05, so a guard must not depend on that one switch. A job turned off on purpose,
# from Switchboard or with launchctl disable, stays off.

set -uo pipefail

LABEL="com.alcatraz.zrecover"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
TARGET="gui/$(id -u)"

[[ -f "$PLIST" ]] || { echo "zrecover: not installed"; exit 0; }
if launchctl print "$TARGET/$LABEL" >/dev/null 2>&1; then
  echo "zrecover: already running"
  exit 0
fi
if launchctl print-disabled "$TARGET" | /usr/bin/grep -q "\"$LABEL\" => disabled"; then
  echo "zrecover: turned off on purpose, left off"
  exit 0
fi
[[ "${1:-}" == "--dry-run" ]] && { echo "zrecover: would start"; exit 0; }
launchctl bootstrap "$TARGET" "$PLIST" && echo "zrecover: started"
