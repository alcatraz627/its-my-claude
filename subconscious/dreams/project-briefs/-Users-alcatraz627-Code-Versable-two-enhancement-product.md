<!-- i-dream project brief · 2026-06-18T00:43:32.640955+00:00 · 6 patterns / 0 insights -->
## What this project is about
A full-stack enhancement product (Versable) where the dominant work is feature development, code review, and technical documentation — with strict conventions on tone, architecture, and implementation discipline.

## Things to do (or keep doing)
- **Plan hand-rolled components first**: before writing any complex UI component the user asked to hand-roll, sketch the approach and cross-check against existing similar implementations in the codebase.
- **Keep docs technical and flat**: use neutral, confident, formal prose — function over narrative, no headers that editorialize, no marketing framing.
- **Read live, don't cache externally-mutable state**: if a service's status can be toggled from outside the process (e.g. `warm on`), read it live on each render; TTL caches will lie.

## Things to avoid
- **Don't write product-marketing documentation**: phrases like "Why this matters", flowery framing, or hyperbolic lead-ins are explicitly rejected — the user will push back and make you rewrite.
- **Don't surface internal uncertainty in user-facing docs**: investigation caveats, agent-analysis hedges, and "we're not sure yet" phrasing must stay internal; published docs use confident, neutral tone.
- **Don't skip YAML frontmatter on RCA files**: any atone S3 event's RCA file must open with `---` frontmatter on line 1 or the `atone add` command exits with error 2 and the event is lost.

## Open questions / known gaps
- No recurring unresolved tensions with enough signal to flag yet — patterns are all single-occurrence.
