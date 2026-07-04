<!-- i-dream project brief · 2026-07-04T07:15:42.970511+00:00 · 20 patterns / 0 insights -->
## What this project is about
Versable enhancement-product — a full-stack feature development project with strict scope discipline and high standards for lean, professional documentation and implementation.

## Things to do (or keep doing)
- **Replicate existing patterns exactly** when the user says "do it the same way as X" — find the reference impl and mirror it, no new abstractions
- **Translate research/design outputs into lean, product-focused implementation docs** — behavioral and direct, neither academic nor enterprise-heavy
- **Hand the user exact git commands** when this repo's CLAUDE.md requires manual execution; never run pushes autonomously

## Things to avoid
- **Don't re-introduce deferred or deleted complexity** — if the user explicitly removed or simplified something, treat that as a hard constraint, not a suggestion
- **Don't add unrequested abstractions, wrappers, or infrastructure** — when asked for data access or a simple function, use the simplest existing path; new exports need a real caller right now
- **Don't use em-dashes, "Why this matters" openers, or promotional framing** in any human-facing prose — write formal, direct, factually grounded text
- **Don't conflate verbal acknowledgment with correct implementation** — after agreeing on semantics (e.g. "opt-in"), verify the code implements exactly that, not the inverse

## Open questions / known gaps
- Scope ceiling enforcement is a recurring failure mode — the agent repeatedly adds complexity after explicit user simplification requests, suggesting the ceiling check needs to happen at code-write time, not just at planning time
- `atone.sh` RCA files must open with `---` YAML frontmatter on line 1; this has caused silent event-drop failures more than once
