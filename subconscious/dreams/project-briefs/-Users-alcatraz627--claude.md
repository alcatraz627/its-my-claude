<!-- i-dream project brief · 2026-09-03T09:02:24.686302+00:00 · 20 patterns / 6 insights -->
## What this project is about
This is the `~/.claude` global configuration repository — rules, skills, hooks, conventions, and agent infrastructure for this account. Work here is predominantly meta: authoring behavioral rules, building TUI scripts, and improving the harness that governs all other sessions.

## Things to do (or keep doing)
- **Enumerate the full set before acting** — audit every sibling file, every affected surface, every member of a component family before writing a single line; per-page divergence is a recurring defect here.
- **Verify the artifact, not the signal** — read the file, run the search, check the source; notifications and structural assumptions are not evidence.
- **Route prose quality to a fresh seat** — self-correction of AI-smell fails repeatedly in this project; mechanical check or sub-agent pass is the only reliable gate.
- **Treat state surfaces as live instruments** — task list, agent roster, resource locks must be reconciled against reality before reporting from them.

## Things to avoid
- **Don't re-raise deferred topics** — if the user skipped or parked something, it stays parked until they resurface it; three skips is a hard stop.
- **Don't claim UI or runtime fixes without exercising on the running app** — false assurance cycles are a documented pattern here; screenshot the render, read the pixels.
- **Don't regenerate AI-smell after a hook fires** — em-dashes and bold-span excess recur in the very next reply after correction; rewrite before sending, not after.
- **Don't pause on terse continuations** — "keep going" means execute, not clarify; context well below 70% with pending work is a proceed signal.

## Open questions / known gaps
- Prose self-correction is structurally broken: the agent cannot reliably detect its own AI-smell even after being corrected, suggesting the mechanical hook needs to block (not warn) before this improves.
- The two-agent peer-review workflow is valued but underspecified — no canonical skill or dispatch template exists yet for it.
