<!-- i-dream project brief · 2026-06-25T00:50:38.542973+00:00 · 20 patterns / 0 insights -->
## What this project is about
A product enhancement codebase with heavy documentation and implementation design work. The dominant style is plan-first, batch-validate, lean-doc — research phases must translate into tight behavioral specs, not raw synthesis.

## Things to do (or keep doing)
- Write validation criteria before implementation begins — cover behavior, runtime, code, and intent; recheck after each task and at completion
- Work autonomously in meaningful batches; self-validate internally and surface only substantive checkpoints for user review
- Write docs in formal, direct, neutral language — technical audience, no preamble, no "why this matters" opener
- Track tasks in the Task tool proactively; reconcile when edits accumulate without status updates

## Things to avoid
- Don't re-introduce deferred or deleted complexity under a different name — when the user simplifies or removes scope, treat it as a ceiling, not a suggestion
- Don't let research/analysis uncertainty ("this claim may be wrong", suspicion notes) bleed into user-facing docs — maintain confident, neutral tone throughout
- Don't use em-dashes, label:fragment rows, or marketing voice in prose; and don't overcorrect into warm narrative either — aim for lean, professional, behavior-focused
- Don't cache liveness/availability state with a TTL when an external actor (user command, daemon) can change it out-of-band — read live instead

## Open questions / known gaps
- Prose register calibration keeps slipping: both AI-smell and overcorrected "social science essay" voice recur even after correction — may need a fresh-reviewer sub-agent pass on any doc before delivery
- Scope creep on deferred features is a recurring pattern; need a pre-implementation gate that cross-checks the task against explicitly deferred items before writing code
