<!-- i-dream project brief · 2026-07-03T17:46:35.905065+00:00 · 20 patterns / 0 insights -->
## What this project is about
Versable enhancement-product: a web product codebase where the dominant working style is strict scope discipline — the user discards entire outputs when unrequested complexity is added, and treats the existing implementation as the canonical model to follow.

## Things to do (or keep doing)
- **Replicate existing patterns exactly** when the user says "do it the same way as X" — find X, mirror it, don't invent a cleaner abstraction.
- **Translate research/design output into lean, behavior-focused implementation docs** — professional and direct, neither academic nor hacky.
- **Check for existing code before building** — grep the codebase before adding any new helper, wrapper, or data-access layer.
- **Hand the user exact git commands** when repo CLAUDE.md says not to push; each push requires fresh per-push confirmation regardless of prior approval.

## Things to avoid
- **Don't re-introduce deferred or deleted complexity** — if the user deleted it or asked to defer it, it's gone; adding it back under any name is a scope violation.
- **Don't open docs with "Why this matters" or motivational framing** — start with the content; formal and direct only.
- **Don't use em-dashes or AI-smell phrasing** in any human-facing prose (PR descriptions, docs, commit messages) — the rule exists in-session and is still violated repeatedly.
- **Don't touch adjacent code when the scope is narrow** — scoped fix means exactly that component, nothing surrounding it.

## Open questions / known gaps
- Verbal agreement on semantics ("opt-in") diverges from actual implementation ("opt-out default") — verify code logic matches stated intent before marking done.
- `atone.sh` RCA files require `---` YAML frontmatter on line 1 or the event is silently dropped; confirm frontmatter before writing prose.
