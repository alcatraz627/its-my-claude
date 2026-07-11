<!-- i-dream project brief · 2026-07-11T18:14:43.215027+00:00 · 2 patterns / 0 insights -->
## What this project is about
A Ghostty terminal theme management tool — scripts or config for generating, previewing, or applying color themes. Working style: targeted, sequential file edits with preference verification before assuming intent.

## Things to do (or keep doing)
- Always sequence edits to the same file; never batch parallel `Edit` calls targeting the same path — only one survives
- Verify what "runtime" means in context before proceeding: deploy-time env vars vs. live-configurable globals are distinct

## Things to avoid
- Don't parallelize writes to the same file even when changes look independent — silent clobber, both calls return success
- Don't assume "runtime variables" means environment variables; ask if the distinction matters before designing the solution

## Open questions / known gaps
- _(no signal yet)_
