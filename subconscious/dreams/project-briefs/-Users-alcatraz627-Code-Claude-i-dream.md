<!-- i-dream project brief · 2026-07-27T20:04:26.831823+00:00 · 20 patterns / 4 insights -->
## What this project is about
A dream-tracking dashboard (i-dream) with UI components, widgets, and pm2-backed services. Work is primarily frontend feature development with frequent sub-agent use for gap analysis and review.

## Things to do (or keep doing)
- **Consult design mocks first** before writing any UI labels, page names, or creation flows — internal naming conventions are wrong by default
- **Audit all sibling pages** before implementing any shared UI component (drawer, sidebar, modal, pagination) — always breadth-first before depth
- **Ground gap assessments in source code** — read the files; never estimate completion from memory or session context
- **Surface auth blocks explicitly** — when a sub-agent hits a credential wall, provide the exact command the user must run and hold there

## Things to avoid
- **Don't claim a bug is fixed** without exercising it on the running dev server — false assurance on UI bugs is the top trust destroyer here
- **Don't patch only the immediate instance** — when a pattern violation is found on one page, fix the entire class across all pages in the same response
- **Don't derive spec authority from agent-authored documents** — gap audits must reference the original user-authored spec, not a formalization downstream of it
- **Don't write essay-length comments** on self-evident changes — strip to one terse WHY-only line or nothing

## Open questions / known gaps
- Recurring tension between breadth-first audit discipline and session token cost — large surface surveys get skipped under time pressure, causing the sibling-page miss pattern to repeat
- Design mock consultation is affirmed in every session but still misses on creation flows specifically; unclear if mocks are consistently accessible or just not being checked
