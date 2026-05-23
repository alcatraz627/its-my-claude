#!/usr/bin/env bash
# notify.sh — macOS notification for Claude Code hooks
#
# Usage: notify.sh <title> <subtitle> <message> [sound] [group]
#
# Uses terminal-notifier with Ghostty icon and click-to-focus.
# Falls back to osascript if terminal-notifier is unavailable.
#
# group: notification dedup key. Default is subtitle-based (replaces previous).
#        Pass a unique value (e.g. timestamp) to prevent clobbering.

set -uo pipefail

TITLE="${1:-Claude Code}"
SUBTITLE="${2:-}"
MESSAGE="${3:-}"
SOUND="${4:-Ping}"
GROUP="${5:-claude-${SUBTITLE// /-}}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ICON_PNG="$SCRIPT_DIR/ghostty-icon.png"
ICON_ICNS="/Applications/Ghostty.app/Contents/Resources/Ghostty.icns"

# Convert .icns → .png once (terminal-notifier needs PNG/URL for -appIcon)
if [[ ! -f "$ICON_PNG" && -f "$ICON_ICNS" ]]; then
  sips -s format png "$ICON_ICNS" --out "$ICON_PNG" &>/dev/null || true
fi
APP_ICON="$([[ -f "$ICON_PNG" ]] && echo "$ICON_PNG" || echo "$ICON_ICNS")"

if command -v terminal-notifier &>/dev/null; then
  (
    terminal-notifier \
      -title "$TITLE" \
      -subtitle "$SUBTITLE" \
      -message "$MESSAGE" \
      -sound "$SOUND" \
      -activate com.mitchellh.ghostty \
      -appIcon "$APP_ICON" \
      -group "$GROUP" \
      -timeout 30 \
      2>/dev/null
    # terminal-notifier blocks until clicked/dismissed/timeout.
    # On click it returns the activation bundle ID — focus Ghostty.
    osascript -e 'tell application "Ghostty" to activate' 2>/dev/null || true
  ) &
  disown
else
  esc() { printf '%s' "$1" | sed 's/"/\\"/g'; }
  osascript -e "display notification \"$(esc "$MESSAGE")\" with title \"$(esc "$TITLE")\" subtitle \"$(esc "$SUBTITLE")\" sound name \"$SOUND\"" 2>/dev/null || true
fi
