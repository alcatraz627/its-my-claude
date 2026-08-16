<!-- i-dream project brief · 2026-08-13T02:34:49.464452+00:00 · 20 patterns / 4 insights -->
## What this project is about
Instagram/social media scraping and download pipeline with a multi-source aggregation UI. Work runs in long autonomous sessions with external dependencies (auth, quotas, rate limits).

## Things to do (or keep doing)
- Prefer fully async deployment flows; never block the session waiting on interactive auth steps
- Always surface which pages/endpoints were checked when a scraper returns zero results — zero count alone forces a follow-up
- Update Task tool status after each logical unit during autonomous sessions, not in batch at the end
- When correcting any pattern (UI component, prose, data handling), enumerate sibling instances that share the same structure and apply the fix to all of them in the same turn

## Things to avoid
- Don't write em-dashes, excessive bold spans, or Label:fragment rows — the prose-smell hook will fire and the correction will stick; a surface-level rewrite that regenerates the same tells wastes a full round trip
- Don't make structural claims about where functionality lives without reading the relevant source file:line first
- Don't declare a page or endpoint "done" without an actual HTTP fetch confirming it renders; visual review of source is not verification
- Don't silently stall when an external wall hits (quota, credential block, rate limit) — surface the exact blocker and the exact user action needed immediately

## Open questions / known gaps
- Multi-source filter UI has a known gap: any newly added scraping source must immediately get a per-source filter; the pattern has been missed once already
- External-wall failures (usage limits, auth) go silent mid-autonomous-session; no reliable graceful-degradation pattern established yet
