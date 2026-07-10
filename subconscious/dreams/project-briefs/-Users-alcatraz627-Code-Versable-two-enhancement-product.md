<!-- i-dream project brief · 2026-07-10T08:25:45.847660+00:00 · 20 patterns / 0 insights -->
## What this project is about
Versable enhancement product — a TypeScript/React codebase. Work style is scope-constrained feature development where the user enforces strict "ceiling not floor" discipline on every task.

## Things to do (or keep doing)
- When the user says "same way as X", replicate that exact pattern — no new abstractions
- Translate research/design phases into lean, behavior-focused implementation docs before starting code
- Confirm push permissions fresh per-push; repo CLAUDE.md git gates take absolute precedence over default behavior
- Check whether existing code already handles a request before building new infrastructure

## Things to avoid
- Don't re-introduce deferred scope under any guise — "not now", "defer", "for later" is a hard stop, even when implementing it would be trivial
- Don't verbally acknowledge the correct semantics then implement the inverse in code; verbal agreement is not verification
- Stop writing em-dashes, "Why this matters" openers, or promotional framing in docs — formal, direct, factually grounded only
- Never add complexity adjacent to a scoped simplification request; touching unrequested patterns causes the user to discard the entire output

## Open questions / known gaps
- Opt-in/opt-out polarity is a recurring slip even after explicit correction — treat any "opt-in" feature description as "default-on, explicit signal to exclude" before writing a line
- Scope ceiling violations correlate with the agent "completing" a partial spec; when a spec feels incomplete, stop and ask rather than fill gaps autonomously
