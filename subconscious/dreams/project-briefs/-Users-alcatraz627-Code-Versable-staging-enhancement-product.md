<!-- i-dream project brief · 2026-06-25T00:52:14.622254+00:00 · 2 patterns / 0 insights -->
## What this project is about
A staging/enhancement product (likely Next.js frontend + Python backend) where work is iterative and feature-scoped — the dominant style is incremental PRs with explicit scope ceilings and careful migration discipline.

## Things to do (or keep doing)
- **Always keep the Task list reconciled** — when file edits accumulate over many turns without a Task update, stop and reconcile before continuing; the TUI list is the only live source of truth
- **Scan existing patterns before writing** — check env var access patterns, auth module placement, and domain naming conventions before introducing a new file or config read
- **Flag client env var exposure proactively** — any `NEXT_PUBLIC_` var that doesn't need browser access should be called out before the PR is cut
- **Prefer flag-driven error classification** — never branch on `err.message` string content; route a stable `code`/`kind` field instead

## Things to avoid
- **Don't re-introduce deferred scope under a new name** — when the user explicitly deferred a feature, treat it as off-limits until they re-open it; re-adding under a different implementation is still scope creep
- **Don't delete or consolidate a component split without reading why it exists** — architecture splits in this codebase are intentional; investigate before merging
- **Don't mix frontend/backend env var boolean conventions** — frontend uses `"true"/"false"` strings; backend uses `1/0`; never cross-use

## Open questions / known gaps
- **Migration review discipline** — migration scripts have a known gap in review rigor; there's no enforced checklist before they land, and bugs there are high-blast-radius
