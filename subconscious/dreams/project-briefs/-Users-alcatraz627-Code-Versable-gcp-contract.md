<!-- i-dream project brief · 2026-08-28T07:43:14.602637+00:00 · 20 patterns / 1 insights -->
## What this project is about
GCP contract/product work with heavy multi-agent orchestration — parallel review panels, sub-agent fleets, shared contract files, and iterative design reviews. Dominant working style is plan-heavy with adversarial verification gates.

## Things to do (or keep doing)

- **Verify state at the destination, not the source** — check files on disk, read actual deploy logs, run `rg --no-ignore` before claiming absence; never trust send-side signals as proof of receive-side truth
- **Pre-filter owner decisions aggressively** — default mechanical choices, surface only genuine judgment calls; use `/decision-wizard` for batches, never prose lists
- **Re-read shared contract/doc files immediately before writing** — concurrent sub-agents drift; stale reads produce conflicting edits
- **Include a maximally adversarial seat in review panels** — one voter whose premise is the product category itself is flawed; surface value-to-effort ratio before presenting findings as action items

## Things to avoid

- **Don't claim code paths work without executing them** — lint/type-check/collect-only is not a run; the stop hook fires here repeatedly
- **Don't dispatch sub-agents at the wrong model tier** — when a ruling specifies a tier (e.g., "one fable planning seat"), violating it ignores an explicit standing constraint
- **Don't re-surface deferred work** — if the user said "don't ask again" or set a concrete trigger condition, mark it deferred and never re-raise it as a question or blocker
- **Don't show a task list without verifying session scope** — a wrong-session task list triggers strong frustration; confirm the session sid before rendering

## Open questions / known gaps

- Multi-voter panel scoping drifts toward the session's presentation goal rather than real product usability gaps — pre-confirm scope explicitly before launching
- Sub-agent completion tracking via idle notifications is unreliable; output files on disk are the ground truth but this pattern keeps being skipped
