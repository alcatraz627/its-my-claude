<!-- i-dream project brief · 2026-07-05T12:50:52.201219+00:00 · 20 patterns / 0 insights -->
## What this project is about
A Next.js/TypeScript enhancement product (Versable) with a strongly opinionated working style: the user enforces strict scope ceilings and rejects any complexity beyond what was explicitly requested.

## Things to do (or keep doing)
- When the user says "opt-in," default to including everything and require an explicit signal to exclude — never implement opt-out by default
- Replicate existing patterns exactly when the user says "the same way you would for X" — read the reference implementation before writing new code
- Translate research/design phases into lean, behavior-focused implementation docs — professional and direct, neither academic nor enterprise-heavy
- Hand the user exact git commands and stop before pushing; repo-specific CLAUDE.md git rules take absolute precedence over default behavior

## Things to avoid
- Don't re-introduce deferred scope: if the user said "not now" or deleted something, it stays out even when the implementation is "trivially easy"
- Don't add abstractions, wrappers, or new infrastructure when existing code already handles the request — check first, build only if nothing fits
- Don't write em-dashes, "why this matters" intros, or promotional framing in any human-facing prose; docs open with a direct statement of fact
- Don't treat verbal acknowledgment of correct semantics as verification — confirm the implemented logic matches the agreed behavior before declaring done

## Open questions / known gaps
- Scope ceiling enforcement is the single most recurring failure: verbal agreement + wrong code happens repeatedly, suggesting a missing pre-commit self-check habit
- The boundary between "deferred" and "just not yet wired" is consistently ambiguous; the user's intent on deferral needs to be surfaced and confirmed explicitly before implementation begins
