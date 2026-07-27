<!-- i-dream project brief · 2026-07-24T10:14:18.560126+00:00 · 20 patterns / 2 insights -->
## What this project is about
A SaaS enhancement product (likely Next.js frontend + backend) with active feature development, code review workflows, and UI/logging constraints. Work style is incremental, scope-tight, and review-heavy.

## Things to do (or keep doing)
- **Always use full file paths** in reports and output — basenames are not clickable and waste the user's time hunting
- **Verify sub-agent output files exist on disk** before using their findings — the completion notification is not proof the file was written
- **Group review/audit findings by logical domain**, not severity; mark severity only when high, inline markdown only (never HTML, never pipe-delimited dumps)
- **Treat narrow scope as a hard ceiling** — when the user says "only for X", implement with explicit hardcoded conditions, not runtime self-gating that could generalize

## Things to avoid
- **Don't claim "verified" without exercising the code path** — checking types/lint/build is not running; if you can't run it, say so explicitly
- **Don't put runtime config / feature flags in backend env config** — the user has a separate runtime config system; env config and runtime toggles are architecturally distinct
- **Don't include Co-Authored-By lines or AI-prose register in commit messages** — these are audited with a style tool and must read human-authored
- **Don't treat a user correction as permission to move on all axes** — "narrow scope" means ceiling on scope only, not a signal to add flexibility elsewhere

## Open questions / known gaps
- Sub-agent audit authority: agents keep selecting agent-authored formalization docs as the spec authority instead of the user-authored product spec — needs a standing prompt guard
- Disabled configs (CI triggers, feature flags) get re-enabled without investigating why they were disabled; the disabled state often encodes a deliberate decision
