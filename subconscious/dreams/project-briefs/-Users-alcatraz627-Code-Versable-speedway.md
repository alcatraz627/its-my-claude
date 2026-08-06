<!-- i-dream project brief · 2026-07-29T02:40:53.152085+00:00 · 2 patterns / 0 insights -->
## What this project is about
A React/JSX frontend codebase under the Versable product umbrella. Working style is iterative and terse — the user sends short continuations and expects immediate forward progress without ceremony.

## Things to do (or keep doing)
- Honor terse continuation signals ('proceed', 'keep going', 'yes') immediately; context is almost never at pressure — just continue
- Before inserting conditional rendering in JSX, scan 10 lines of surrounding siblings to match the local pattern (inline prop, plain const, ternary) before reaching for an IIFE or block scope

## Things to avoid
- Don't pause to ask for clarification on continuation signals unless context is genuinely above 70% pressure or the action is irreversible
- Don't introduce scoped wrappers (IIFE, inner function) for conditional JSX when a peer component uses a simpler form — match the file's idiom first

## Open questions / known gaps
- Very few sessions logged for this project; behavioral patterns are thin — treat the two above as high-confidence but expect surprises on domain conventions until more sessions accumulate
