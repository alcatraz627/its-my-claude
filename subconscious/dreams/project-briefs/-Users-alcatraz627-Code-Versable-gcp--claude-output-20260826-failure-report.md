<!-- i-dream project brief · 2026-08-28T07:43:43.618218+00:00 · 8 patterns / 1 insights -->
## What this project is about
GCP-related Versable development with heavy agent-assisted coding; work centers on multi-session feature builds with visual design, deployment, and review bot interactions.

## Things to do (or keep doing)
- **Verify at the destination, not the source** — check the file on disk, the deploy logs, the peer's reply; never trust a send log or non-zero exit as sufficient success proof
- **Run ignore-transparent searches** (`rg --no-ignore`) before claiming a file or code path doesn't exist
- **Execute the path before calling it done** — lint/type-check/collect-only runs are not execution; the stop hook fires repeatedly here
- **Read decision page answers literally** — "Neither" means none of the options are approved; do not interpret rejection as partial approval

## Things to avoid
- **Don't dispatch sub-agents at the wrong model tier** — when a ruling specifies a tier (e.g., "one fable planning seat"), dispatching at any other tier violates the standing order
- **Don't re-surface explicitly deferred tasks** — if the user said "don't ask me again", mark it deferred and drop it from all subsequent blockers and questions
- **Don't ship design variants that only diff on details** — variants must represent meaningfully different directions (color language, motif, composition), not micro-adjustments
- **Don't reply to the PR review bot with plain text** — use the tagged invocation syntax or the bot ignores the reply entirely

## Open questions / known gaps
- Recurring tension between "deployment succeeded" (exit 0) and actual deploy state — silent downgrade warnings in logs go unread
- Model-tier discipline at sub-agent dispatch is a repeat failure point; the ruling is set but not consistently honored
