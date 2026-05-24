<!-- i-dream project brief · 2026-05-23T23:31:53.361662+00:00 · 20 patterns / 10 insights -->
## What this project is about
A Notion sync pipeline (likely exporting/importing structured data between Notion and another system). Work is iterative and data-heavy, with recurring fragility in archive/unarchive, link handling, and image uploads.

## Things to do (or keep doing)
- **Treat terse single-word messages** (`ahead`, `again`, `done`, `looks`) as execution directives — continue without asking for clarification
- **Trace every emitted value to a source line** before writing it to a file, commit, or data structure; apply a provenance check at every data boundary
- **Use project-defined utilities** (e.g. `isDevelopment`, named env helpers) everywhere rather than inlining the raw expression they abstract
- **Re-read actual schema/source code** before asserting which system is authoritative on any data field or state value

## Things to avoid
- **Never commit or push without fresh per-instance approval** — prior approval in the same session does not carry forward; this rule has been violated repeatedly
- **Never infer, guess, or extrapolate data values** not directly present in source data; flag gaps explicitly rather than filling them with plausible values
- **Never write credentials to any file** — not even temporarily for testing; acknowledge and proceed in-memory only
- **Don't attempt a second fix on the same block without identifying root cause** — re-read the error log and form a hypothesis first

## Open questions / known gaps
- Notion sync scripts have recurring fragility across sessions (archive/unarchive bugs, link failures, image upload issues) — no durable fix has landed yet; treat each session as potentially re-encountering these known failure modes
