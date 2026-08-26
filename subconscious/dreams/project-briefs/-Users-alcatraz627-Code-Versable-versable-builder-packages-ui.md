<!-- i-dream project brief · 2026-08-21T19:19:37.116741+00:00 · 15 patterns / 3 insights -->
## What this project is about
UI package work within the Versable builder monorepo — component-level changes, data display, and job/report pipelines. Work is iterative and session-heavy, with frequent multi-file edits and sub-agent delegation.

## Things to do (or keep doing)
- **Show actual data when asked** — when the user says "show me", include the real rows/output in the reply, not a summary of what you did
- **Enumerate all instances before fixing one** — when a pattern is wrong on one component, list every sibling affected before writing any code
- **Reconcile the task list before stopping** — after 10+ edits, sync completed/new work into the Task tool; a frozen task list after 50 edits is a known failure mode here
- **Verify coverage dimensions explicitly** — before claiming a filter/UI/check is done, name the data sources, visual modes, and edge states actually exercised vs. assumed

## Things to avoid
- **Don't count regression fixes as progress** — correcting a same-session breakage is net-zero recovery; don't surface it as a finding or forward movement
- **Don't treat your own output as external validation** — "I authored X" is not evidence X is correct, received, or complete; seek an independent signal
- **Don't reference PR/issue numbers without verifying they exist** — confirm the artifact is real in the target repo before citing it
- **Don't deliver multi-criteria filters without testing all criteria conjunctively** against real (not fixture) data

## Open questions / known gaps
- Deferred user-named actions (emails, posts) accumulate in PENDING lists across sessions without ever executing — no clear resolution pattern established
- Sub-agent incremental-write contracts are frequently violated (batching instead of per-item); parent verification of the contract is inconsistent
