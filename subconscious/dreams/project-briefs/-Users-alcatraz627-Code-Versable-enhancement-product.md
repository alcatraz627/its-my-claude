<!-- i-dream project brief · 2026-05-31T12:23:15.279846+00:00 · 20 patterns / 2 insights -->
## What this project is about

Versable enhancement-product is a shared-branch web product (likely Next.js/Node) with established project conventions for config, environment utilities, and terminal output. Work style is iterative feature/fix sessions with strong git hygiene requirements.

## Things to do (or keep doing)

- **Always grep for the project's existing pattern first** — use `isDevelopment`/`isProd` utilities, config modules, and TUI/gum tools rather than inlining raw equivalents
- **Require fresh, explicit per-push approval** — treat every compaction boundary or `/catchup` as implicit revocation of all prior git approvals; one "yes" never carries forward
- **Present structured terminal output with project gum/TUI tools** — never fall back to plain markdown tables when the project has configured display utilities

## Things to avoid

- **Never commit or push without in-turn, per-operation user approval** — this pattern has triggered severe backlash repeatedly; prior session approval is never blanket
- **Never write credentials to any file, note, checkpoint, or commit** — secrets shared for manual testing must stay in-session only
- **Don't bypass project abstractions** — never inline `process.env.NODE_ENV` or raw env reads when a named utility already exists in the codebase

## Open questions / known gaps

- Approval state silently decays across context compaction — no mechanical enforcement exists; agent must self-police after every `/compact` or `/catchup`
