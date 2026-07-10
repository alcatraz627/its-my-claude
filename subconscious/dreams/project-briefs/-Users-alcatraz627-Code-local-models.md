<!-- i-dream project brief · 2026-07-10T08:38:27.530560+00:00 · 20 patterns / 0 insights -->
## What this project is about
Local LLM tooling suite (`q`/`imagine`/`warm`/`lm fleet`) — CLI-first, agent-drivable tools. Sessions mix research, persona/model design, and tooling work; primary deliverables are lean, behavior-focused implementation docs and working scripts.

## Things to do (or keep doing)
- Always surface actual command output when claiming a test or feature succeeded; the user judges correctness from raw output, not your assertion.
- Hand exact git commands for the user to run manually — this repo has a `guard-user-commit.sh` gate; never execute commits or pushes directly.
- Translate research/analysis phases into lean, behavior-focused implementation docs before the session ends; raw synthesis is not a deliverable.
- Execute explicitly invoked skills (`/atone`, `/affirm`) immediately and completely before continuing other work — deferral compounds the mistake.

## Things to avoid
- Don't re-introduce complexity the user explicitly deleted; when asked for a simpler replacement, deliver exactly that and nothing more.
- Don't open docs with "Why this matters" framing, em-dashes, or motivational phrasing — formal, direct, factually grounded only; no AI-smell.
- Don't use `rm` (hook blocks it; use `trash`). Don't write todos to a file when "update todos" is said — call the Task tool.
- Don't declare test success without showing output; asserting success without evidence is treated as a failure.

## Open questions / known gaps
- Sessions risk completing peripheral exploratory sub-tasks (research, design, persona work) before the primary ask; pin the primary deliverable at session start to avoid drift.
