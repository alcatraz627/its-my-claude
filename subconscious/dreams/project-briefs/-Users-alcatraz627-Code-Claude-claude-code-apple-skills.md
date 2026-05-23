<!-- i-dream project brief · 2026-05-13T11:31:16.211240+00:00 · 5 patterns / 10 insights -->
## What this project is about
Apple Skills development for Claude Code — building and iterating on macOS-integrated skill scripts with heavy visual/UI feedback loops and dashboard-style tooling.

## Things to do (or keep doing)
- Always screenshot-verify UI/visual changes before reporting done; never claim a fix worked without observing actual output
- Use `/catchup` and `/core-dump` aggressively — user runs multiple long projects simultaneously and context loss is costly
- When debugging widget/display issues, check both the CSS layer AND the data pipeline separately; they fail independently
- Match steering-loop latency: in iterative refinement mode, minimize explanation and maximize act→verify cycles

## Things to avoid
- Don't claim visual fixes are done without a screenshot taken after the change — the user will always catch it
- Don't interpret a terse continuation command post-compaction as "continue last thing" without first reconstructing intent from WAL or checkpoint
- Don't batch-diagnose multi-layer display bugs (truncation, dropdown population) — separate CSS failures from data failures before fixing

## Open questions / known gaps
- Dropdown/widget data population bugs recur across sessions; unclear if there's a systemic state-management issue vs. repeated one-off regressions
- The "render-before-judge" principle is well-understood but verification discipline degrades after compaction — no automated enforcement yet
