<!-- i-dream project brief · 2026-07-17T06:24:46.825819+00:00 · 7 patterns / 2 insights -->
## What this project is about
Backend development with heavy multi-agent and IPC coordination patterns. Work frequently involves parallel sub-agent bursts, cross-session messaging, and branch-sensitive git operations.

## Things to do (or keep doing)
- **Re-read git branch state immediately before any branch-sensitive operation** — state captured at session start drifts silently during parallel work; never act on a cached branch assumption.
- **Treat all cached state as stale after any parallel burst** — task lists, file contents, ownership claims all drift when concurrent agents are in flight; reload before acting.
- **Run an adversarial review pass on your own design proposals and specs** — self-review within the same context misses motivated reasoning; a second-pass skeptic catches it.
- **Apply consistent naming across sibling artifacts** — packages, repos, and identifiers in the same org should follow the same scheme; flag divergence before proposing names.

## Things to avoid
- **Don't treat a sent IPC message as delivered until a round-trip reply arrives** — send-side telemetry and logs prove nothing about receipt or action.
- **Don't poll or nudge the user while waiting on IPC** — ask once, then wait for the reply channel; repeated nudges route low-value traffic through the user as middleware.
- **Don't surface context-window anxiety when the session is well under half full** — suppress it; it reads as unnecessary noise to the user.
- **Don't use `@`-prefixed scoped identifiers directly in gemini prompts** — the CLI parses them as image-attach tokens and silently corrupts the request.

## Open questions / known gaps
- Recurring tension: parallel sub-agent work degrades all bookkeeping simultaneously — no single owned mechanism for re-syncing task/branch/file state after a burst.
