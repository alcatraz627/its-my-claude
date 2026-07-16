<!-- i-dream project brief · 2026-07-14T03:24:14.274462+00:00 · 13 patterns / 3 insights -->
## What this project is about
A data extraction/transformation pipeline (data-forge) where correctness is the dominant concern — data integrity, config validation, and runtime behavior all require ground-truth verification, not inference from test coverage or plausible-looking output.

## Things to do (or keep doing)
- **Always run the affected code path** after implementing complex features; 99+ passing tests is not a correctness signal — dogfooding catches what suites miss
- **Dispatch an adversarial reviewer sub-agent immediately after implementing complex features** — it reliably catches HIGH-severity bugs the main agent just introduced
- **Surface the structural observation behind any local workaround** before applying it (inline CSS, zero-default, silent dep add) — these are signals of systemic gaps, not just fixable symptoms
- **Restate the exact scope of a user signal before acting** — "you said X, which I interpret as Y but not Z" — when social comfort or intensity complaints could be over-broadened

## Things to avoid
- **Don't use `.get('key', 0)` or similar zero-defaults for numeric fields** — fabricated plausible values suppress investigation and corrupt downstream deltas
- **Don't treat user reassurance ("I trust you", "that's fine") as authorization to remove safeguards** — it is social comfort, not a blanket removal mandate
- **Don't let task lists drift across many turns of editing** — reconcile completed vs. open items before stopping, or the list lies about reality
- **Don't silently add a new library/dependency** — surface the constraint and offer a within-existing-dependency alternative first

## Open questions / known gaps
- Config validation fires only at parse time, not write time — missing fields can silently break unrelated features; no systematic write-time guard exists yet
- Recurring tension between intensity-tuning signals ("too noisy") and complete-removal responses — the correct ceiling semantics aren't yet mechanically enforced
