<!-- i-dream project brief · 2026-07-18T06:39:35.398596+00:00 · 6 patterns / 0 insights -->
## What this project is about
A theme management or browsing tool for the Ghostty terminal emulator, built with multi-agent coordination and a shared UI layer. Work sessions are often resumed across handoffs and run alongside peer agents.

## Things to do (or keep doing)
- **Update the task list after each logical unit** — never batch at session end; a drifted task list silently misdirects resumed sessions
- **Verify planning and handoff docs are current** before acting on them — superseded plans are silent traps at resume time
- **Implement shared UI elements (nav, shells) from a single source component** — per-page replicas diverge immediately and are expensive to resync

## Things to avoid
- **Don't send IPC messages to a peer alias without verifying it maps to the live peer ID** — aliases are not authoritative; check live peers first
- **Don't absorb or push commits created by concurrent sibling sessions** — in a shared local repo, leave other sessions' commits alone; only push your own
- **Don't attribute a zero-conversion hook to implementation bugs before checking the event type** — a high fire-rate with zero conversions almost always means the hook is wired to the wrong event

## Open questions / known gaps
- Hook event-type mismatches have burned time here; no automated guard exists to catch wrong-event-type registration at hook-authoring time
- Multi-agent IPC coordination is load-bearing but peer alias resolution is manual — a stale alias silently sends to the wrong session
