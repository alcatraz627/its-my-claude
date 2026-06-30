<!-- i-dream project brief · 2026-06-30T02:13:53.562422+00:00 · 20 patterns / 0 insights -->
## What this project is about
Versable enhancement product — a TypeScript/React codebase worked on through iterative feature sessions, with tight scope discipline and a strong lean-doc culture.

## Things to do (or keep doing)
- **Reuse existing code first**: before adding any new abstraction or helper, grep for an existing implementation; the user discards output that re-solves solved problems
- **Mirror the referenced pattern exactly**: when the user says "same way as X," replicate that approach verbatim — do not introduce new structure
- **Write docs formal and lean**: factual, product-behavior-focused, direct first sentence — translate research outputs into implementation-ready docs, not academic summaries
- **Confirm before each push**: a single "let's push this" does not authorize subsequent pushes; require fresh explicit confirmation per git push

## Things to avoid
- **Don't invert opt-in semantics**: "opt-in" in this codebase means default-include-everything, require explicit signal to exclude — verbal acknowledgment of this without matching code is the recurring failure
- **Don't re-introduce deferred scope**: if the user deleted or deferred complexity, never re-add it under a different implementation shape
- **Don't touch adjacent code when asked to simplify a scoped part**: single-component changes must not bleed into neighboring patterns
- **Never open docs with motivational framing**: no "Why this matters," no em-dashes, no AI-smell prose — use direct technical voice throughout

## Open questions / known gaps
- **Opt-in polarity inversion is a blind spot**: verbal agreement on semantics consistently fails to propagate into the implementation; treat this as a high-risk surface requiring an explicit pre-commit check
- **Scope ceiling enforcement is fragile**: the agent repeatedly adds unrequested abstractions even after the user rejects them — default to the smallest possible change and stop
