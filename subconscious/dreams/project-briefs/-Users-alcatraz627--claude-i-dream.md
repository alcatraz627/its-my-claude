<!-- i-dream project brief · 2026-07-11T18:36:28.821791+00:00 · 8 patterns / 0 insights -->
## What this project is about
A personal dream-tracking dashboard with widgets, pm2 services, and Anthropic API integration. Working style is tool-building with a mix of UI, server-side, and document-generation tasks.

## Things to do (or keep doing)
- Always navigate to the actual URL and exercise the primary flow before claiming a UI or server change works — the user treats skip-and-claim as a critical failure
- Sequence edits to the same file; parallel `Edit` calls silently clobber each other (both return success, only one survives)
- Check `git log` before implementing any new mechanism for storing IDs or configs — the feature may already exist in a recent commit

## Things to avoid
- Don't end a sentence immediately after a file path (bare or backtick) — Ghostty auto-links paths and swallows the trailing period, breaking the link; follow every path with a space, comma, or restructure
- Don't suggest version changes (upgrades, reverts) without scanning recent git history first — deliberate version decisions committed recently mean any re-suggestion is noise
- Don't default to hardware/throughput metrics when the user asks for augmentations to a personal tool — focus on user-facing utility
- Don't proceed on "runtime variables" or "runtime config" without clarifying whether the user means deploy-time env vars or on-the-fly app globals

## Open questions / known gaps
- Ambiguity between env vars and runtime app config surfaces repeatedly — establish a project-level convention and document it once
