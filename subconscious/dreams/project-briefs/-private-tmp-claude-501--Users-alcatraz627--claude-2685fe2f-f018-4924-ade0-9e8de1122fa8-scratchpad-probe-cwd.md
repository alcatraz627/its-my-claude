<!-- i-dream project brief · 2026-07-11T18:15:01.639447+00:00 · 2 patterns / 0 insights -->
## What this project is about
Temporary scratchpad and probe working directory under `/private/tmp`; used for exploratory, diagnostic, and one-off investigative work rather than a persistent codebase.

## Things to do (or keep doing)
- Sequence edits to the same file — never batch parallel `Edit` calls targeting one path; both return success but only the last survives.
- Clarify "runtime variables/config" before implementing — ask whether the user means deploy-time env vars or on-the-fly application globals; the two solutions diverge significantly.

## Things to avoid
- Don't issue parallel `Edit` tool calls to the same file in a single turn — the silent clobber is undetectable until the user spots missing changes.
- Don't assume "runtime config" means environment variables; stop and confirm the intended mutability surface before writing any scaffolding.

## Open questions / known gaps
- No persistent project structure — each session may be starting fresh with a different probe goal; re-orient on the current task rather than assuming continuity from prior scratchpad work.
