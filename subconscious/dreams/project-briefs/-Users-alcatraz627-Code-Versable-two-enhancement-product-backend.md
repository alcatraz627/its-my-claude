<!-- i-dream project brief · 2026-06-26T16:50:05.637746+00:00 · 6 patterns / 0 insights -->
## What this project is about
A Python backend for a B2B SaaS enhancement product. Work style is precise and scope-constrained — the user has strong opinions about architecture and will discard over-engineered output.

## Things to do (or keep doing)
- **Plan before writing complex components** — when told to hand-roll something, draft a plan and cross-check against existing similar implementations before writing any code
- **Verify implementations match stated semantics** — if you said "opt-in," confirm the default in code is off, not on; verbal acknowledgment is not enough
- **Keep scratch/checkpoint files out of project root** — browser extensions, npm packages, and similar artifact-loaded dirs will fail to load if a `_*.claude.md` lands there; write them to `/tmp` or `.claude/`

## Things to avoid
- **Don't exceed the declared scope** — adding unrequested abstractions, patterns, or architectural layers causes the user to discard the entire output; implement exactly what was asked
- **Don't remove working user-authored code** — if a solution already exists, extend or wrap it; never delete it, re-implement it, and credit yourself
- **Don't let internal uncertainty bleed into docs** — documentation must use neutral, confident tone; investigation caveats and agent-analysis hedges belong in the WAL, not in user-facing output

## Open questions / known gaps
- **Opt-in/opt-out semantic drift** — the pattern of verbally agreeing on a behavioral default then inverting it in code has occurred; a precheck before every feature-flag or default-value write would help
