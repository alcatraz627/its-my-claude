<!-- i-dream project brief · 2026-06-29T18:04:12.095014+00:00 · 20 patterns / 0 insights -->
## What this project is about
Versable enhancement product — feature development on a product codebase. Work is tightly scoped; the user enforces a hard ceiling on complexity and actively discards outputs that exceed it.

## Things to do (or keep doing)
- When user cites an existing implementation as the model ("same way as X"), replicate it exactly — don't introduce new abstractions
- Write docs in a professional, lean, behavior-focused register; neutral and factual, never promotional or motivational-framing
- After a research/design phase, translate findings into a product-focused implementation doc before closing the phase
- Confirm per-push before any `git push`, even when the session already approved an earlier push

## Things to avoid
- Don't invert opt-in polarity: "opt-in feature" means everything is included by default, explicit signal excludes — never the reverse
- Don't re-introduce complexity the user deleted or deferred; verbal acknowledgment of the correct semantics is not a substitute for coding the correct branch
- Don't add new helpers, wrappers, or abstractions when the user asks for data access or a display function — grep for existing code first
- Don't use em-dashes, "why this matters" openers, or AI-smell phrasing in any human-facing prose (PRs, docs, changelogs)

## Open questions / known gaps
- Recurring blind spot: agent agrees on the right semantics in prose but implements the logical inverse in code — add a pre-commit self-check: "does the default branch match what I said it would?"
- Scope creep on simplification requests: user asks to reduce one piece, agent touches adjacent patterns — always verify the blast radius matches the stated scope before editing
