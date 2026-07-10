<!-- i-dream project brief · 2026-07-10T08:39:50.000555+00:00 · 6 patterns / 0 insights -->
## What this project is about
Personal tooling and document-production work under `~/.claude`; sessions mix iterative drafting with autonomous file operations, with strong editorial standards on any customer-facing output.

## Things to do (or keep doing)
- Always check `git log --oneline -10` before introducing any new mechanism for storing or retrieving an ID, config value, or module version — the commit may already have settled it
- Prefer user-facing utility metrics (workflow value, time saved) over hardware/throughput metrics when suggesting augmentations to personal tools
- Follow the filename-dot-stop rule: always place a word, comma, or space after any file path — never let a sentence period immediately follow a backtick-wrapped path

## Things to avoid
- Don't open PRs or push commits mid-session during iterative draft-and-feedback cycles; PR creation is a terminal act requiring explicit user sign-off, not a continuation step
- Don't suggest version changes (upgrade, revert, pin) without first scanning recent git history for deliberate version decisions — a recent revert is a hard constraint, not a candidate for re-reverting
- Don't let AI-register phrasing survive in any customer-facing or professional document — strip openers like "Good news first:", apologies like "That is on us", and leading-question closers before sending

## Open questions / known gaps
- Iterative sessions frequently leave PRs or pushes queued mid-feedback-loop; no lightweight checkpoint signal exists to distinguish "autonomous continuation" from "terminal shared-state action"
