<!-- i-dream project brief · 2026-07-27T00:45:05.826722+00:00 · 20 patterns / 3 insights -->
## What this project is about
A dream-tracking dashboard (i-dream) with widgets, pm2 services, and Anthropic API integration; dominant work is UI feature building and multi-agent orchestration with a strong emphasis on correctness over speed.

## Things to do (or keep doing)
- **Always exercise the fix on the running dev server** before claiming done — false assurance on UI bugs compounds trust debt faster than anything else
- **Audit all sibling pages/routes before touching any shared UI component** (sidebar, drawer, modal) — per-page patches always turn into global fixes in the next message
- **Use full relative or absolute paths in every output and report** — basenames are not clickable in this user's terminal
- **Surface the exact command the user must run when hitting an auth/credential block** — hold explicitly, never attempt workarounds

## Things to avoid
- **Don't produce gap assessments or completion tables without reading the source first** — code-ungrounded assessments consistently overestimate what's built
- **Don't add fallback flexibility or self-gating generalization to an explicit scope constraint** — when the user says "only X, not Y," enforce it literally with no softening
- **Don't verify a multi-state UI surface in only one theme or mode** — dark-only sign-offs ship broken light themes; scope the claim to what was actually exercised
- **Don't patch the named instance when the user corrects a class of output** (pipe-delimited dumps, essay comments, format leaks) — apply the correction to the whole class

## Open questions / known gaps
- Design mocks are repeatedly skipped before shipping module labels and creation flows — unclear where mocks live or how to surface them at implementation time
- Review grouping preference (by domain, not severity) is affirmed but not yet mechanically enforced — findings drift back to severity-ordered tables under time pressure
