<!-- i-dream project brief · 2026-08-08T10:27:19.913686+00:00 · 8 patterns / 2 insights -->
## What this project is about
UI package for a job-tracking/recruiting product (versable-builder). Work is data-heavy with scored outputs, decision pages, and sub-agent pipelines; sessions are long and edit-dense.

## Things to do (or keep doing)
- **Reconcile the Task list before stopping** — in edit-heavy sessions, task state drifts; sync it to reality at every natural pause, not just at session end.
- **Trace every claim back to the raw source** — never treat an agent-produced summary, derivative doc, or "I read through it" assertion as authoritative; re-read the original rows/records before acting.
- **Verify filter criteria conjunctively against real output** — after implementing any multi-criteria filter or exclusion rule, spot-check actual results to confirm ALL criteria fire together, not just the last one touched.
- **Handle null/missing fields before numeric ops** — any field that feeds a score, sort, or display calculation needs an explicit null guard first; silent coercion produces wrong aggregates.

## Things to avoid
- **Don't fix one instance of a pattern-level bug** — when you find a broken pagination, unenforced criterion, or missing link in one place, grep for all surfaces with the same shape before closing the task.
- **Don't batch sub-agent output verification** — when a sub-agent is told to write incrementally, confirm it honored that contract (check file size / record count mid-run); don't assume batching didn't happen.
- **Don't wholesale inherit a dead agent's plan** — when triaging a prior session's PENDING list, evaluate each item against the current state independently; stale plans contain superseded work.

## Open questions / known gaps
- Deferred user-directed actions (emails, posts) accumulate in PENDING lists across sessions without executing — unclear whether the block is tooling, auth, or scope creep each time.
