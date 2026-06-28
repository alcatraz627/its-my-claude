<!-- i-dream project brief · 2026-06-28T12:38:22.556497+00:00 · 12 patterns / 0 insights -->
## What this project is about
Versable enhancement-product backend — a structured TypeScript/Python codebase where scope discipline and implementation fidelity to stated intent are the dominant working challenges.

## Things to do (or keep doing)
- **Plan before implementing** any complex component, especially hand-rolled ones; review existing similar implementations before writing new code
- **Write to a new path** whenever generating derived/filtered outputs — never overwrite the source file
- **Treat scratch files as invisible to the runtime** — keep `_*.claude.md` and checkpoint files out of any directory loaded as a package (Chrome extension, npm module, etc.)
- **Match docs tone to neutral confidence** — strip investigation caveats and uncertainty markers before any user-facing documentation lands

## Things to avoid
- **Don't invert opt-in semantics** — when user says "opt-in", default is include-all; explicit signal opts out. Verbal acknowledgment of the correct polarity does not count — check the branch condition in code
- **Don't widen scope when asked to simplify** — a scoped simplification request is not permission to refactor adjacent patterns or introduce new abstractions
- **Don't remove working user-authored solutions** and re-implement them — if existing code already solves the problem, extend it, don't replace it
- **Don't add architectural wrappers** where a direct call or existing primitive suffices; the user discards oversized outputs entirely

## Open questions / known gaps
- Repeated opt-in/opt-out polarity inversions suggest a systematic check is missing — consider a pre-submit read of every new boolean default against the user's stated intent
- `/atone` flow is frequently invoked but not completed end-to-end; the gate blocks the turn and wastes context — complete slug → `atone.sh add` → RCA in one shot or don't invoke at all
