<!-- i-dream project brief · 2026-05-26T00:57:05.045424+00:00 · 20 patterns / 10 insights -->
## What this project is about
A Notion sync pipeline (archive/unarchive, link handling, image uploads) with recurring fragility. Work style is terse-directive: single words like "ahead", "again", "done" mean execute, not discuss.

## Things to do (or keep doing)
- **Treat terse one-word messages as execution directives** — continue the active task without asking for clarification
- **Trace every emitted value to a source line** before writing it; if you can't cite `file:line`, stop and ask
- **Use project-provided utilities** (e.g. `isDevelopment`) everywhere rather than inlining raw env checks
- **Re-read ground truth before any side-effect** (git push, file write, API call) — never carry forward session assumptions

## Things to avoid
- **Never commit or push without fresh per-push approval** — prior approval in the same session does not carry forward; this has been violated multiple times and is a hard rule
- **Never write credentials to any file**, even temporarily; acknowledge receipt in-context only
- **Don't match on error message strings** for flow control — use structured error codes/fields
- **Don't attempt a second fix on the same block without diagnosing root cause first** — re-read the error log, form a hypothesis, then edit once

## Open questions / known gaps
- Notion sync scripts have recurring fragility across sessions (archive/unarchive bugs, link handling failures, image uploads) — root causes appear systemic, not one-off; treat any new failure in these areas with suspicion rather than a quick patch
- The no-push rule has been violated multiple times despite reinforcement — consider whether a pre-push hook would mechanically enforce what the rule cannot
