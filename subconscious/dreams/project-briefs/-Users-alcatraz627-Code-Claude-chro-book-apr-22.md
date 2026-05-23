<!-- i-dream project brief · 2026-05-13T11:29:34.068945+00:00 · 12 patterns / 10 insights -->
## What this project is about
A Claude-powered dashboard app (likely a book/content tracker) with heavy iterative UI work, screenshot-driven verification loops, and API cost awareness as a first-class concern.

## Things to do (or keep doing)
- **Prefer screenshot → inspect → fix → screenshot** for all UI changes; never report a visual fix done without rendering proof
- **Commit and push after each logical phase** — user expects this cadence explicitly, don't batch across phases
- **Treat terse one-word messages as autonomous-continue signals** — increase execution depth on the current task, not scope

## Things to avoid
- **Don't expand scope on terse continuation** — "keep going" / "next" means execute faster within current bounds, never widen to adjacent features or refactors
- **Don't patch UI truncation/overflow symptoms without diagnosing the root CSS cause** — repeated fix cycles on the same element signal the root cause wasn't found
- **Don't make Claude API calls without cost consideration** — user flagged expense directly; prefer caching, rate-limiting, or cheaper models where the task allows
- **Don't validate image dimensions after passing to API** — validate upfront; dimension violations are hard constraints, not soft warnings

## Open questions / known gaps
- Tension between terse-autonomy signals and strict scope ceiling is unresolved at the rule level — when a "keep going" hits a task boundary, it's unclear whether to stop and confirm or infer the next logical unit
- Widget/popover size constraints need to be set at creation time, not retrofitted — no established convention yet for where these constraints live in the codebase
