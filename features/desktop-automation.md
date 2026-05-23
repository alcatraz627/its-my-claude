---
brief: macOS GUI control via screencapture/osascript/cliclick; vision loop; focus-steal confirm; hard-stop on failure
triggers:
  - tool:desktop.sh
  - tool:cliclick
  - tool:screencapture
  - topic:macos-windows
  - topic:screenshots
  - topic:gui-automation
related: []
tier: 2
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Desktop Automation
macOS GUI control via `screencapture`, `osascript`, and `cliclick` (brew).

## Quick reference

- **Screenshots:** `bash ~/.claude/scripts/desktop.sh screenshot display 1` or `screenshot app Slack`
- **Annotate for coordinates:** `bash ~/.claude/scripts/desktop.sh annotate PATH` — overlays pixel grid. `--grid 50` for dense UIs. `--marks X,Y` to highlight planned click positions
- **Window list:** `bash ~/.claude/scripts/desktop.sh windows` → App | Title | X Y W H
- **Click / type:** `bash ~/.claude/scripts/desktop.sh click X Y` / `type "text"` / `key cmd+c`
- **Space switch:** `bash ~/.claude/scripts/desktop.sh space 2` (waits 400ms)
- **Environment check:** `bash ~/.claude/scripts/desktop.sh check` — diagnoses Accessibility, Screen Recording, cliclick, Pillow

## Vision loop

screenshot → annotate → `Read` the annotated PNG → identify exact coordinates → act → screenshot again to verify.

## Storage

Always `~/.claude/assets/images/` with timestamped names — never `/tmp` (deny-listed). Log the saved path in WAL and core-dump notes.

## MANDATORY — Focus-stealing confirmation

Before ANY focus-stealing operation (`click`, `type`, `key`, `space`, `focus`), call `mcp__inputs__confirm` to ask the user first. Never silently steal focus mid-task.

**Exception:** if the user has already explicitly approved the full automation sequence in their prompt ("go ahead", "run the tests"), a single pre-sequence confirmation is enough — don't ask before each individual click.

## MANDATORY — Hard STOP on any failure

If any desktop automation command fails, **STOP immediately** and report the exact failure. Do NOT:
- Assume a blank/tiny screenshot shows the expected content
- Hallucinate what the screen probably looks like
- Skip verification and guess the action worked
- Continue with unverified state

**Failure signals:** `desktop.sh` exits non-zero · screenshot < 5KB · empty window bounds · `cliclick` fails silently · annotated coordinates don't match expected UI.

On failure: state what failed, show the error output, ask the user how to proceed.

## Permission required

`ghostty` must have Accessibility + Screen Recording in System Settings.

## Full reference

See `~/.claude/skills/shared/desktop-automation.md` for Phase 2 upgrade spec and extended examples.
