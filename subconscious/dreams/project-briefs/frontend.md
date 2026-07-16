<!-- i-dream project brief · 2026-07-16T07:37:22.290839+00:00 · 20 patterns / 2 insights -->
## What this project is about
Frontend codebase with multi-agent and IPC-adjacent tooling; dominant working style is breadth-first sweeps followed by targeted deep work, with the agent expected to run autonomously between genuine decision points.

## Things to do (or keep doing)
- Explore and ground in the existing codebase first; surface a recommendation before touching any code.
- Prefer breadth-first v1 passes across all surfaces before polishing individual items — complete the sweep, then circle back.
- Batch sequential work into autonomous runs; halt only at genuine decision points or blocking reviews, not at every short-distance progress step.
- Treat state-ledger writes (TaskUpdate, IPC replies, commits) as blocking obligations — execute immediately after completing each unit of work, never defer as "bookkeeping."

## Things to avoid
- Don't use `rg -rn` — `-r` is `--replace`, not recursive; use `rg -n` for line numbers in recursive searches.
- Don't patch a specific instance of a structural problem (e.g., one CLI in a fallback list) without fixing the underlying class; instance patches leave the structural default intact and suppress investigation.
- Don't include internal banter, critique of stakeholders, or conversational framing in any document that may be shared externally — strip those before writing.
- Don't ask a decision question without enough background and tradeoffs to make it self-contained; questions that require follow-up before the user can answer are wasted round-trips.

## Open questions / known gaps
- Task list hygiene degrades under parallelism; TaskUpdate calls lag edits, leaving the TUI blind. No structural fix confirmed yet.
- Access-gate defaults (ALLOW vs DENY for unrecognized input) have been patched at instance level but the structural audit across all gate surfaces is unresolved.
