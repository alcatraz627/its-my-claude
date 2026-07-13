<!-- i-dream project brief · 2026-07-13T00:44:56.066393+00:00 · 20 patterns / 0 insights -->
## What this project is about
A web app (JSX/React) for data transformation and document generation, with customer-facing outputs and GitHub PR integration. Work is UI-heavy with mutation flows, pickers, and document scaffolding.

## Things to do (or keep doing)
- **Navigate to the actual URL and exercise the primary flow** before claiming any UI or server change works — inspection and type-checking are not verification.
- **Sequence all edits to the same file** — parallel `Edit` calls silently clobber each other; both return success but only one survives.
- **Check recent git log before implementing a new mechanism or changing a version** — deliberate decisions (reverts, pinned versions, recently added patterns) are invisible without a log scan.
- **Invalidate client-side caches explicitly after any mutation** — cache staleness after a write is a silent correctness bug.

## Things to avoid
- **Don't auto-apply on picker selection** — selection must preview only; an explicit save/apply action is required before state commits.
- **Don't place a period immediately after a file path** in terminal output — Ghostty swallows the period into the auto-link, breaking clickability.
- **Don't launch expensive multi-agent workflows until research and user Q&A are complete** — running a debate over incomplete inputs wastes tokens and produces wrong answers.
- **Don't use AI-register phrasing in customer-facing docs** (`Good news first:`, reflexive apologies, leading-question closers) — purge these on generation.

## Open questions / known gaps
- `"runtime variables"` is ambiguous between deploy-time env vars and on-the-fly app globals — always clarify before proceeding.
- UI reskins validated on one state (e.g. dark only) repeatedly ship broken alternate states; end-to-end UX validation across scroll, background, responsive layout, and navigation is a recurring gap.
