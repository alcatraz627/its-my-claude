<!-- i-dream project brief · 2026-07-19T02:16:10.814371+00:00 · 20 patterns / 8 insights -->
## What this project is about
A staging environment for an enhancement product — full-stack web app with multi-agent coordination via IPC, list/detail UI surfaces, and parallel sub-agent workflows. Work style is autonomous-execution-first with minimal user interrupts.

## Things to do (or keep doing)
- **Scope fixes to the full class**: when a report names one page/component/endpoint, grep siblings for the same pattern and fix all of them in one pass
- **Apply sibling patterns proactively**: if a list page lacks pagination and peer pages have it, add it without being told
- **Batch sequential work autonomously**: halt only at genuine decision points or destructive gates — never for rubber-stamp go-aheads
- **Count-based state persistence**: update task list every ~5 edits or 3 tool calls, not only at milestones; parallelism degrades milestone-triggered bookkeeping reliably

## Things to avoid
- **Don't convert absence to assertion**: when a probe returns empty (no IPC reply, no data, cache hit), emit `unconfirmed/unknown` — never fabricate a negative claim from silence
- **Don't accept proxy evidence as verification**: send-success logs ≠ message delivered; test-collect ≠ test-passed; always require a real round-trip or observable outcome
- **Don't route internal state through the user**: waiting-for-IPC, progress polls, context anxiety — never surface these unless the user must take an action
- **Don't suggest diverging names across sibling artifacts**: default to the org's existing naming scheme

## Open questions / known gaps
- IPC round-trip confirmation discipline keeps recurring — there may be a missing affordance for detecting peer-reply vs send-success that agents reach for by default
- Parallelism/sub-agent bursts reliably cause state drift (task list, branch state, file ownership) — no systematic post-burst reconciliation step is established yet
