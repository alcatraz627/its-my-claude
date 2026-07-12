<!-- i-dream project brief · 2026-07-12T04:39:41.962572+00:00 · 5 patterns / 0 insights -->
## What this project is about
A Ghostty terminal theme browser/picker tool — shell scripts or a TUI that lets users preview and apply Ghostty color themes. Work style: interactive CLI with explicit save semantics.

## Things to do (or keep doing)
- Prefer explicit save/apply actions — selection previews only; never auto-commit a theme change on cursor movement or single keystroke
- Sequence edits to the same file serially; parallel `Edit` calls to one file silently clobber each other (only the last write survives)
- Use fenced `diff` blocks for any color output in PR comments — ANSI escape codes render as literal text on GitHub

## Things to avoid
- Don't conflate "runtime variables" with deploy-time env vars — ask whether the user means live-configurable globals or build-time config before proceeding
- Don't fabricate stub doc body content — scaffold with goal statement + `TODO(human)` placeholders only; never fill sections to look complete

## Open questions / known gaps
- _(no signal yet)_
