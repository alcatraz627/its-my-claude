<!-- i-dream project brief · 2026-06-19T17:53:04.287288+00:00 · 12 patterns / 0 insights -->
## What this project is about
Versable is an enhancement product (likely a browser extension or web app) where the dominant work style is careful, structured implementation — plan before code, always review against existing patterns before writing new components.

## Things to do (or keep doing)
- **Plan before implementing** any non-trivial or hand-rolled UI component; review existing similar implementations first, then code — never one-shot complex custom UI
- **Verify current toolchain state** before referencing environment setup (e.g., version managers, installed models); assume the environment may have changed since last session
- **Critically evaluate and synthesize** ideas from external AI tools rather than copying verbatim; the user expects improvement, not transcription

## Things to avoid
- **Don't use marketing or flowery language in docs** — no "why this matters," no hyperbolic framing, no promotional voice; technical docs must be formal, direct, and factually grounded
- **Don't leak internal uncertainty into user-facing output** — agent suspicion notes, investigation caveats, "this claim may be wrong" phrasing must never appear in docs or UI copy
- **Don't cache externally-mutable service state with a TTL** — availability/warm-cold status toggled by the user out-of-band will produce stale UI; read live instead
- **Don't place scratch or checkpoint files in the project root** — extension/npm package loaders treat the root as an artifact directory and will fail to load with unexpected files present

## Open questions / known gaps
- Recurring tension between agent research uncertainty and the requirement for confident, neutral doc tone — needs a consistent internal-vs-external output split discipline
- atone S3 RCA files require YAML frontmatter on line 1; this has caused add-command failures — verify frontmatter format before writing RCA files
