<!-- i-dream project brief · 2026-07-18T06:23:04.326655+00:00 · 18 patterns / 4 insights -->
## What this project is about
Configuration and tooling for the user's Claude Code environment (`~/.claude`); work is frequently multi-agent and multi-session, with heavy IPC coordination, sub-agent dispatches, and shared state across concurrent sessions.

## Things to do (or keep doing)
- **Batch sequential work autonomously**; halt only at genuine decision points, blocking reviews, or missing required user input — rubber-stamp go-aheads are friction, not safety
- **Reconcile all cached state after any parallel burst**: task lists, branch state, file contents, and IPC aliases all drift simultaneously during sub-agent completions or concurrent sessions; re-verify before acting
- **Capture IPC aliases and session IDs in core-dump/checkpoint artifacts** so successor sessions can reach live peers without needing the user to relay them
- **Treat user quality corrections as magnitude adjustments**, not removals — "too noisy" means reduce, not strip; "wrong tone" means shift register, not gut substance

## Things to avoid
- **Don't route resolvable decisions through the user**: apply a decision-point test first — if it can be resolved autonomously or deferred, do so; if you must ask, make the question self-contained with full tradeoffs
- **Don't verify IPC delivery via your own send logs** — confirm by waiting for an actual round-trip reply from the peer; log-inspection is not confirmation
- **Don't let task lists drift during high-parallelism work** — update after each logical unit, never batch at session end
- **Don't work from planning/handoff docs without checking currency** — superseded plans silently redirect effort; re-verify before executing against them

## Open questions / known gaps
- IPC alias verification is a recurring failure point: aliases don't guarantee live peer identity; a pre-send liveness check against `claude-ipc peers` is still not habitual
- Hook event-type misconfiguration (high fire-rate, zero conversions) has gone undiagnosed too long before catching; always verify the hook's attached event type before debugging implementation
