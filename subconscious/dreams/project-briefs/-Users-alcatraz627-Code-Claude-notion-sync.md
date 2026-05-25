<!-- i-dream project brief · 2026-05-25T00:57:12.458153+00:00 · 20 patterns / 10 insights -->
## What this project is about
A Notion sync pipeline (likely Node/Python) that extracts, transforms, and pushes structured data to/from Notion — recurring fragility in archive/unarchive, link handling, and image uploads across sessions.

## Things to do (or keep doing)
- **Treat terse single-word messages** (`ahead`, `again`, `done`, `looks`) as execution directives — continue without asking for clarification
- **Trace every emitted value to a source line** before writing it to any output file or data structure; implement provenance checks at trust boundaries
- **Re-read ground truth** (source file, API response, error log) before a second fix attempt on the same block — never patch from internal model alone
- **Use project-provided utilities** (e.g. `isDevelopment`) everywhere rather than inlining raw env checks

## Things to avoid
- **Never commit or push without fresh per-instance approval** — prior approval in the session does not carry forward, ever
- **Never write credentials to files** — not even temporarily; acknowledge receipt and proceed in-memory only
- **Never branch on error message strings** (`includes`, `match`, regex) — error classification must use a structured code field
- **Don't fill data gaps by inference** — if a value cannot be traced to source data, stop and flag it rather than synthesizing a plausible-looking value

## Open questions / known gaps
- Notion sync scripts have recurrent fragility (archive/unarchive bugs, link failures, image uploads) — root causes not durably fixed; expect regression on re-entry
- Git push discipline has been violated multiple times in this project specifically — treat any "we're done" moment as a push-risk trigger and verify approval explicitly before touching git
