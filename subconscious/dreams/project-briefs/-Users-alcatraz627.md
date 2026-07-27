<!-- i-dream project brief · 2026-07-19T23:22:54.476621+00:00 · 20 patterns / 8 insights -->
## What this project is about
`~/.claude` global configuration and tooling for a heavy multi-agent, multi-session Claude Code setup. Dominant work style: orchestration, hook/script authoring, IPC coordination, and iterative dogfooding of the harness itself.

## Things to do (or keep doing)
- **Verify at the output layer**, not the send/compile/cache layer — a successful send, green test, or cached re-run proves nothing about the actual outcome; require a round-trip reply or observed artifact.
- **Explore and ground in the existing codebase before editing** — surface a recommendation first; jumping directly to edits without that grounding is the primary friction trigger.
- **Default to DENY for unknown inputs in any gate** — access gates, command dispatchers, and fallback handlers must treat unrecognized input as DENY, never ALLOW.
- **Run the affected code path to claim it works** — runtime exercise catches bugs that 99+ test suites miss; coverage is not correctness.

## Things to avoid
- **Don't build per-page variants of globally-shared shell components** — audit sibling pages before writing any shell/sidebar/modal code.
- **Don't convert absence into a concrete value** — missing fields, empty results, and unknown commands must emit UNCERTAIN/DENY, never a zero-default or success.
- **Don't let the Task list drift** — call `TaskUpdate` incrementally; 20 edits with no task update is a session failure, not a milestone.
- **Don't present deferred decisions without prior context + two concrete options** — omitting that forces a follow-up round-trip.

## Open questions / known gaps
- IPC architecture has no budget-exhaustion escape hatch: when the orchestrator hits its usage limit, waiting sub-agents block indefinitely — no recovery path designed yet.
- Proxy-evidence substitution recurs across unrelated domains (IPC, gates, data, tests) suggesting the pattern isn't landing from rules alone; a mechanical gate may be needed.
