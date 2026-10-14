---
brief: Claude Code TUI alternate-screen-buffer limitation; what hooks CAN and CANNOT display
triggers:
  - topic:hooks
  - topic:terminal-display
  - phrase:"SessionStart hook"
related: []
tier: 2
category: features
updated: 2026-10-06
stale_after_days: 90
---

# Hooks Tui Limits
Claude Code's TUI uses an alternate screen buffer (since v2.1.89) that overwrites any external `/dev/tty` writes.

## The rule

**Do not attempt to display custom content in the terminal from SessionStart hooks** or any hook that tries to write to the main conversation area. The TUI will always corrupt or overwrite banners, ASCII art and any other visual output. Known open issue: anthropics/claude-code#42340.

## What hooks CAN do

- `additionalContext` injects text into Claude's system context (not visible in the terminal)
- `sessionTitle` sets the session name
- Async side-effects that don't write to the main terminal area:
  - Tab title via OSC escape sequence
  - macOS notifications
  - Logging to files

## What hooks CANNOT do

Display visual content in the conversation/terminal area. Period.

## Mods lift this (2026-10-06)

Claude Code mods draw in the TUI directly. `features/gcc-mods.md` is gcc's mod. Wrap owner-facing hook text with `hook_owner_wrap` (hook-common.sh) and it is drawn on a surface instead of handed to the model. The rule above still holds for a session without the mod.

## Practical implication

To surface information to Claude, use `additionalContext`. To surface it to the human, use a macOS notification or a log file plus a statusline widget. Never `printf` to `/dev/tty` and expect the user to see it.

## Config snapshot vs file swap (deploy behavior)

Hook WIRING (the `settings.json` hooks blocks) is a snapshot taken at session start. Adding or changing a matcher mid-session does nothing until the next session. Hook SCRIPTS are re-executed fresh at every event, so swapping the file at an already-wired path goes live immediately, mid-session, for every running session. Verified empirically 2026-07-02: a newly wired PostToolUse matcher stayed silent in-session, and a swapped Stop-hook file took effect at the next Stop. The deploy consequence is that new-hook wiring is safe by default (it arms next session), and editing a live hook file is the risky operation. Validate before the swap (`scripts/hooks/replay/` is the ship-gate) and keep the `git show HEAD:<path>` restore one command away.

## `additionalContext` requires a synchronous hook (cross-ref)

`"async": true` makes PostToolUse stdout side-effect-only. A warn hook wired async runs, logs telemetry, and reaches nobody (false coverage, worse than a mute). Wire agent-facing warn hooks sync and keep them fast. See the hook-output-contracts memory and the lane-3 adversarial review (assets/reports/20260630-s3-gate-leak/, 2026-06-30).
