<!-- i-dream project brief · 2026-07-04T23:56:34.517321+00:00 · 14 patterns / 0 insights -->
## What this project is about
Versable staging-enhancement-product is a full-stack product codebase with active feature work. The dominant working style is tight-scope, incremental — the user defers frequently and treats scope violations as high-severity failures.

## Things to do (or keep doing)
- **Honor every explicit deferral** — "not now / park that / for later" means zero implementation, including trivial setup; mark the task deferred and move on
- **Read CLAUDE.md before any git operation** — this repo has mandatory stop-and-hand-off rules for commits/pushes; never run git mutating commands autonomously
- **Update the Task list proactively** — reconcile after every 2-3 edits; don't let it drift while files accumulate
- **Verify /atone writes landed** — after invoking the skill, confirm the event file was written before continuing

## Things to avoid
- **Don't add unrequested abstractions** — when the user asks to expose data or add a simple field, no wrapper functions, no status-derivation logic, no intermediate layers
- **Don't re-introduce deferred scope under a different shape** — a feature the user parked is parked regardless of how natural the reimplementation looks
- **Don't remove a user-authored solution, flag it as a trade-off, then re-solve it** — that sequence erases the user's work twice; if an existing pattern looks like a limitation, verify it doesn't already solve the stated problem first
- **Don't flag a working user pattern as a "problem"** without reading it carefully — `satisfies` annotations, type narrowing, deliberate constraint logic may be load-bearing

## Open questions / known gaps
- **Scope creep is the dominant recurring failure** — nearly every corrective pattern traces back to the agent adding complexity the user explicitly excluded; the default must be "do exactly what was asked, nothing more"
- **Git operation boundaries are a persistent gap** — repo-specific rules override defaults but agents keep reverting to autonomous git behavior after context compaction
