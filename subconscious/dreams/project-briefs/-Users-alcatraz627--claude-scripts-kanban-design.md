<!-- i-dream project brief · 2026-08-31T03:32:20.985593+00:00 · 10 patterns / 0 insights -->
## What this project is about
Kanban/design tooling scripts within the `~/.claude` ecosystem — shell scripts, GitHub integration, and agent workflow infrastructure. Work is iterative and correction-heavy, with recurring verification gaps.

## Things to do (or keep doing)
- **Verify CI, not just local tests** — before declaring a PR green, check actual CI job results with `gh pr checks`, not only the local test run
- **Write a script when inline commands fail twice** — repeated parse errors or missing-file failures mean the command isn't safe to run inline; write a self-contained script instead
- **Pull codex sub-agent output from return text** — when a codex sandbox can't write files, persist findings yourself from the agent's returned text before losing them

## Things to avoid
- **Don't declare a fix resolved across sessions without mechanical verification** — if the user reports the same problem after a prior "fixed" claim, treat the prior verification as failed and prove it mechanically this time
- **Don't assert cost/complexity trade-offs without checking** — never claim one option is cheaper or simpler without verifying; the user will catch it and it erodes trust
- **Don't post duplicate GitHub comments** — verify exactly one comment will be posted before running `gh pr comment`; duplicates are high-severity and the GitHub agent marker rule still applies

## Open questions / known gaps
- Recurring pattern of multi-session "fixed" claims that weren't verified mechanically — the gap between "looks right locally" and "actually works" keeps reopening
- One-shot vs looping integration design assumptions haven't been grounded in actual prior implementation history
