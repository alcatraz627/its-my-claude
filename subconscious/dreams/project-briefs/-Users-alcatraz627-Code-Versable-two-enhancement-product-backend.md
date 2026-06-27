<!-- i-dream project brief · 2026-06-27T01:01:50.555143+00:00 · 8 patterns / 0 insights -->
## What this project is about
A backend for a product-enhancement SaaS (Versable). Dominant working style: scoped, surgical changes with zero tolerance for unrequested scope expansion.

## Things to do (or keep doing)
- **Plan before hand-rolling complex components**: review existing similar implementations first, then write code — one-shot attempts on complex UI/component work consistently fail
- **Match verbal semantics to code semantics**: if you say "opt-in default," implement `false` by default — double-check the boolean polarity before committing
- **Keep user-facing docs confident and neutral**: strip internal uncertainty markers, caveats, and agent-analysis hedges before writing to any doc the user will read

## Things to avoid
- **Don't expand scope on a scoped request**: if the user asks to simplify one part, touch only that part — adding unrequested abstractions or refactoring neighbors causes the entire output to be discarded
- **Never remove a working user-authored solution**: if a solution already exists, extend or preserve it; removing it, re-solving the same problem, and presenting it as new is a trust-destroying pattern
- **Don't place scratch or checkpoint files in the project root**: directories loaded as packages (npm, Chrome extensions) will fail to load if they pick up stray `.claude.md` or temp files

## Open questions / known gaps
- Recurring tension between planning discipline (plan first) and scope ceiling (don't touch more than asked) — resolve by scoping the plan tightly to the requested change before writing any code
- `/atone` invocations frequently stall without completing the full slug→`atone.sh add`→RCA flow; treat the gate block as a hard stop, not a formality to skip
