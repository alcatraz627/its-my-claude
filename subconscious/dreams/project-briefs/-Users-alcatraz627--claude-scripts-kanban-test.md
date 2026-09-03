<!-- i-dream project brief · 2026-08-31T03:34:16.267941+00:00 · 10 patterns / 0 insights -->
## What this project is about
This project involves GitHub PR automation, CI integration, and kanban/review tooling. Work centers on agentic PR workflows, codex sub-agent dispatch, and shell scripting for comment/review pipelines.

## Things to do (or keep doing)
- **Verify CI job results directly** before declaring a PR green — local test runs are not sufficient when CI runs a different suite
- **Write a self-contained script** when an inline shell command fails repeatedly; retrying variants is a thrash signal
- **Pull findings from sub-agent return text** when a codex sandbox refuses to write output files, then persist them yourself as the parent agent
- **Treat `/skeptical-review` requests as genuine adversarial gates** — if the user invokes it before implementation, the plan has gaps worth finding

## Things to avoid
- **Don't declare a fix resolved across sessions without mechanical verification** — the same failure recurring means the fix was never confirmed
- **Don't post duplicate PR comments** — verify exactly one comment is being posted and that each comment's source is identifiable
- **Don't assert cost reasoning without checking** — never claim a simpler path is cheaper without verifying which option actually costs less
- **Don't assume a simpler integration design** (e.g. one-shot vs loop) without first checking whether the alternative was ever actually tried

## Open questions / known gaps
- Recurring pattern of "declared safe without verification" across multiple sessions suggests a gap in end-to-end CI check discipline — no mechanical gate yet enforces this
- GitHub comment deduplication has no automated guard; agent must self-enforce
