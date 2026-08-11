<!-- i-dream project brief · 2026-08-11T00:25:53.499025+00:00 · 20 patterns / 10 insights -->
## What this project is about
A multi-session Claude instance monitoring dashboard with aggregated data pipelines, shared UI components, and inter-agent IPC coordination. Work frequently spans multiple surfaces and agents running in parallel.

## Things to do (or keep doing)
- **Grep all consumers before fixing any one** — shared components (drawers, pagination, sidebars) appear on N pages; fix all N in one response, never patch the instance you can see and ignore the rest
- **Verify receive-side, not send-side** — after any IPC send, file write, or sub-agent dispatch, confirm arrival (read the file, check the round-trip reply) before calling it done
- **Persist coordination state to disk** — peer aliases, task ownership, and multi-agent state go in the checkpoint file; assume context will die mid-session
- **Include full paths in all output** — never use a basename alone; Ghostty auto-links full paths and a bare filename forces the user to hunt

## Things to avoid
- **Don't build per-page UI variants** — if a component exists on more than one page, the implementation must be globally shared; audit all pages before writing any code
- **Don't claim success without exercising the running app** — "looks right" and "compiles" are not verification; test against the actual running service and check all visual modes (dark AND light)
- **Don't use zero-defaults in data extraction** — `bb.get('x', 0)` fabricates plausible numbers when data is missing; surface the absence explicitly instead
- **Don't default-ALLOW on unknown inputs in any gate** — access gates, CLI filters, and command routers must default to DENY for unrecognized inputs

## Open questions / known gaps
- Deferred decision queues consistently lose their context (prior constraint + options) before the user reviews them — no durable format for deferred items yet
- Parallel agent bursts leave task lists, branch state, and file contents stale simultaneously; no reconciliation step is consistently run after burst completion
