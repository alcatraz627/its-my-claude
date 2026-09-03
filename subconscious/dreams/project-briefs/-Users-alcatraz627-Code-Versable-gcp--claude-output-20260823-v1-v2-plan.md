<!-- i-dream project brief · 2026-08-28T07:44:45.707693+00:00 · 8 patterns / 1 insights -->
## What this project is about
GCP/Versable planning and design output work — producing visual design variants, coordinating multi-agent sub-tasks, and managing deployment verification cycles against a PR review bot.

## Things to do (or keep doing)
- Always verify state at the **destination**, not the source — check the file on disk, the peer's reply, or the ignore-transparent search result, never the send log or exit code alone
- Run `rg --no-ignore` (not default search) before asserting a file, route, or code path does not exist
- Read decision page answers **literally** — 'Neither' or any rejection of all options means none can ship; treat rejections as a stop, not a redirection
- Design variants submitted for user review must represent **meaningfully different** design directions; near-identical variants fail the review before the user speaks

## Things to avoid
- Don't claim a code path is done or working without **executing** it — lint, type-check, and collect-only runs are not execution; the declared-ready stop hook will fire
- Don't dispatch sub-agents at a different model tier than the standing ruling specifies — if the ruling says one fable planning seat, don't substitute sonnet or opus without explicit approval
- Don't re-surface a deferred task as a question or blocker after the user has explicitly said "don't ask me again" — mark it deferred and leave it there
- Don't post plain replies to the PR review bot expecting a re-review — use the bot's tagged invocation syntax or the message produces no bot response

## Open questions / known gaps
- Deployment verification is a recurring weak point: non-zero exit is checked but silent downgrade warnings in logs are missed; no established pattern for reading full deploy logs as part of the done check
- Send-side vs. receive-side confusion is the dominant failure shape here — no mechanical gate exists yet to enforce destination-verification across all tool surfaces
