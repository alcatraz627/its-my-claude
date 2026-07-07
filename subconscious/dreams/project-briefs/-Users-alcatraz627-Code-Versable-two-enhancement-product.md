<!-- i-dream project brief · 2026-07-06T09:29:25.270805+00:00 · 20 patterns / 0 insights -->
## What this project is about
A full-stack product enhancement application (Versable) where the dominant working style is tight scope control — the user aggressively rejects unrequested complexity and enforces strict git-push discipline.

## Things to do (or keep doing)
- When the user says "same way as X", replicate that exact pattern — no novel abstractions
- Translate research/design output into lean, behavior-focused implementation docs before closing a phase
- Write docs in formal, direct prose: no "why this matters" openers, no em-dashes, no promotional framing
- Surface the exact git commands for the user to run manually; never push without fresh per-push confirmation

## Things to avoid
- Don't re-introduce deferred scope — if the user said "not now", treat it as a hard exclusion even when implementation is trivial
- Don't add abstractions, wrappers, or new infrastructure when existing code already handles the case; check first
- Don't mistake verbal acknowledgment for correct implementation — verify the code matches the stated semantics (opt-in vs opt-out, inclusion vs exclusion default)
- Stop touching adjacent patterns when asked to simplify one part; scope ceiling applies to the exact surface named

## Open questions / known gaps
- Recurring tension between "professional but lean" doc style and the agent's default toward enterprise-heavy or academic framing — needs active suppression each session
- Atone RCA files must begin with `---` YAML frontmatter on line 1; the agent repeatedly forgets this, causing silent event-write failures
