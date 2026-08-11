<!-- i-dream project brief · 2026-08-08T10:27:39.724263+00:00 · 8 patterns / 2 insights -->
## What this project is about
A studio/job search pipeline with scored output, decision-page UIs, and multi-agent sub-agent workflows — dominated by data filtering, ranked report generation, and incremental artifact delivery.

## Things to do (or keep doing)
- **Verify filter criteria conjunctively against real output rows** before calling any filter feature done — read actual results, not just the filter logic
- **Trace decisions back to the original source** (raw data, upstream records) not to agent-produced summaries or self-reported reads; the agent's paraphrase is not the authority
- **Reconcile the task list before stopping**, especially after 20+ sequential edits — a frozen task list signals invisible drift
- **Include actionable links** (original posting, company page) alongside any scored/ranked list in reports or decision-page UIs

## Things to avoid
- **Don't claim "I read through the output"** without actually reading rows and acting on what's found — the claim must be backed by observations, not stated as reassurance
- **Don't batch sub-agent output** when the contract says per-item/incremental — verify the sub-agent honored the write contract before consuming results
- **Don't handle null fields implicitly** — null coercion into numeric operations silently distorts scores and rankings; guard every missing field explicitly before arithmetic or display
- **Don't wholesale-inherit a dead agent's pending list** — evaluate each inherited item independently against the current plan

## Open questions / known gaps
- Deferred user-named actions ("send these emails", "post this") accumulate in PENDING lists without ever executing — the mechanism for actually closing them is unresolved
- Pattern-level fixes are applied to the immediate callsite only; the same broken pattern in sibling surfaces is routinely missed until a second correction
