<!-- i-dream project brief · 2026-06-29T18:03:47.379257+00:00 · 19 patterns / 0 insights -->
## What this project is about
Backend for Versable's enhancement product — a domain with explicit conventions around opt-in feature flags, tight scope discipline, and zero tolerance for unrequested abstractions.

## Things to do (or keep doing)
- **Check existing implementations first**: before building anything new, grep the codebase for an existing pattern that handles it; replicate that exact approach rather than introducing new abstractions
- **Plan before hand-rolling complex components**: surface a plan and review against similar existing implementations before writing any code on non-trivial components
- **Write RCA files with `---` YAML frontmatter on line 1**: atone.sh lint exits 2 without it and the event goes unrecorded
- **Produce terse engineering output for docs/reports**: tl;dr + data table format; no bullet armies, no corporate prose, no LLM register

## Things to avoid
- **Don't invert opt-in semantics in code**: when the user says "opt-in", default is include-everything; explicit signal required to exclude — never the reverse; verbal acknowledgment of correct semantics does not substitute for correct implementation
- **Don't add unrequested complexity**: scope ceiling is enforced hard here — adding wrappers, abstractions, or architectural layers beyond the explicit request causes the user to discard the entire output
- **Never write derived/filtered output back to the source path**: always write to a new path; overwriting source with derived content is treated as data loss
- **Don't remove existing user-authored solutions and re-solve them**: removing a working implementation, presenting the problem as open, and re-crediting yourself is a critical trust failure here

## Open questions / known gaps
- Repeated recurrence of inverted opt-in polarity (verbal acknowledgment + wrong code) suggests a systemic drift between reasoning and codegen — treat any feature described as "opt-in" as a hard checklist item before committing
- `/atone` flow completion is consistently incomplete (gate blocks turns); always run the full slug → `atone.sh add` → RCA validation sequence before proceeding
