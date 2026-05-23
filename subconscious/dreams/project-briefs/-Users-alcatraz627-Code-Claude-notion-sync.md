<!-- i-dream project brief · 2026-05-22T22:13:43.076037+00:00 · 20 patterns / 10 insights -->
## What this project is about
A Notion sync pipeline (scripts/tooling domain) that repeatedly surfaces data extraction, credential handling, and git push discipline as high-friction areas. Working style is terse directives; the user expects autonomous execution within tight boundaries.

## Things to do (or keep doing)
- **Treat single-word continuations as execution directives** — "ahead", "done", "again" means proceed, not clarify.
- **Trace every emitted value to a source line** before writing it to a file or data structure; present the source reference alongside the value.
- **Re-read file/git/env state immediately before any side-effect** — session context goes stale; assume nothing carried forward.

## Things to avoid
- **Never commit or push without explicit per-instance approval** — prior approval in the same session does NOT carry forward; ask fresh every time.
- **Never infer, guess, or extrapolate missing data values** — if a field has no source-traceable value, surface the gap and ask; do not fill it.
- **Don't write credentials to any file, even temporarily** — acknowledge receipt in conversation only, never persist.
- **Don't branch on error message strings** — use structured error codes/flags; string matching is fragile and was explicitly rejected.

## Open questions / known gaps
- Notion sync scripts have recurring fragility (archive/unarchive bugs, link handling, image uploads) across multiple sessions — root causes appear unresolved; treat any sync failure as likely a known category before assuming it's novel.
