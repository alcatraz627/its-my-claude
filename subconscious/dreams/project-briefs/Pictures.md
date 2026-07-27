<!-- i-dream project brief · 2026-07-17T06:23:59.597601+00:00 · 7 patterns / 2 insights -->
## What this project is about
Multi-agent coordination project (likely involving IPC between Claude sessions and sub-agent orchestration). Working style is parallelism-heavy with recurring friction around state drift and user-as-middleware patterns.

## Things to do (or keep doing)
- **Re-read git branch state immediately before any branch-sensitive op** — session-start state silently drifts during parallel work; never act on cached branch assumptions.
- **After any parallel burst (sub-agent completions, concurrent edits), invalidate ALL cached state** — task lists, file contents, ownership claims all drift simultaneously.
- **Run an adversarial review pass on your own synthesis docs** (design proposals, specs, plans) — self-review within the same context misses motivated reasoning; a fresh skeptic catches what you wrote yourself past.
- **Use consistent naming across sibling artifacts** — when proposing package names, repo names, or identifiers, default to the scheme already in use across the organization.

## Things to avoid
- **Don't treat a successful IPC send as delivery confirmation** — only an actual round-trip reply from the peer confirms receipt; send-side logs and telemetry prove nothing.
- **Don't nudge the user while waiting for an IPC peer** — ask once, then wait; repeated status asks route low-value traffic through the user as middleware.
- **Don't suppress context anxiety by expressing it** — if the session is under half-full, don't mention context pressure; it reads as noise.
- **Don't use `@`-prefixed scoped identifiers in gemini prompts** — the CLI parses them as image-attach tokens and silently corrupts the prompt.

## Open questions / known gaps
- IPC delivery confirmation discipline is still landing inconsistently — verify round-trip receipt explicitly every time, not just when it seems uncertain.
