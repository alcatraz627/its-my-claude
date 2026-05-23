<!-- i-dream project brief · 2026-05-13T11:28:18.425906+00:00 · 20 patterns / 10 insights -->
## What this project is about
Data-heavy scripting project (likely Versable's data pipeline / migration scripts) where the dominant failure mode is the agent producing plausible-but-ungrounded output — hallucinated values, inferred data, fabricated results — on top of a Next.js/Node stack with strict env var conventions.

## Things to do (or keep doing)
- **Always trace every output value to a specific source line** before writing it to a file, data structure, or commit — no inference, no "likely" fills
- **Use project-defined boolean helpers** (`isDevelopment`, `isProduction`) rather than inlining `process.env.NODE_ENV` comparisons, even in new files
- **Re-read ground truth before any side-effecting action** (git push, file write, data output) — never trust stale session state
- **Stop and ask when a value has no traceable source** — the cost of pausing is always lower than the cost of hallucinated data

## Things to avoid
- **Don't attempt a second fix on the same block without first forming a written hypothesis** about why the first failed — thrash loops destroy trust faster than wrong answers
- **Don't use `true`/`false` env booleans in backend code or `1`/`0` in frontend** — these conventions are strictly separated
- **Never delete or consolidate a component split** (server/client boundary, wrapper, abstraction) before understanding why it exists
- **Never declare "done" before verifying the committed state contains the correct implementation** — announcement ≠ verification

## Open questions / known gaps
- The `isDevelopment` helper pattern appears across many patterns but its canonical location isn't pinned — find it with grep before writing any env check
- Fix-thrash and hallucination share a root cause (acting on internal model vs. re-reading source) but no single hook currently catches both — a pre-write provenance check is an open proposal
