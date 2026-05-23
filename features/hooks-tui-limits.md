---
brief: Claude Code TUI alternate-screen-buffer limitation; what hooks CAN and CANNOT display
triggers:
  - topic:hooks
  - topic:terminal-display
  - phrase:"SessionStart hook"
related: []
tier: 2
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Hooks Tui Limits
Claude Code's TUI uses an alternate screen buffer (since v2.1.89) that overwrites any external `/dev/tty` writes.

## The rule

**Do not attempt to display custom content in the terminal from SessionStart hooks** or any hook that tries to write to the main conversation area. Banners, ASCII art, any visual output will always be corrupted or overwritten by the TUI. Known open issue: anthropics/claude-code#42340.

## What hooks CAN do

- `additionalContext` → inject text into Claude's system context (not visible in terminal)
- `sessionTitle` → set the session name
- Async side-effects that don't write to the main terminal area:
  - Tab title via OSC escape sequence
  - macOS notifications
  - Logging to files

## What hooks CANNOT do

Display visual content in the conversation/terminal area. Period.

## Practical implication

If you want a hook to surface information to Claude, use `additionalContext`. If you want to surface it to the human, use a macOS notification or log file + statusline widget. Never try to `printf` to `/dev/tty` expecting the user to see it.
