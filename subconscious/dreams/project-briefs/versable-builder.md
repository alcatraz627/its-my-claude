<!-- i-dream project brief · 2026-07-29T00:34:18.207801+00:00 · 20 patterns / 7 insights -->
## What this project is about
A multi-page product builder UI (versable-builder) with frequent parallel sub-agent work sessions, design-mock-driven UI development, and IPC-coordinated peer agents.

## Things to do (or keep doing)
- **Read design mocks before any UI label, name, or flow** — org naming and visual hierarchy come from the mocks, never from internal code conventions or prior patterns
- **Audit ALL pages using a shared shell component before touching it** — sidebar, drawer, modal fixes are a class fix, never a single-page fix; enumerate every consumer first
- **Exercise the actual running dev server and take a screenshot before declaring any UI fix done** — green tests and type-checks are not verification; only rendered pixels are
- **Update the Task tool after each logical unit of work**, especially during parallel sub-agent sessions — drift accumulates fastest when velocity is highest

## Things to avoid
- **Don't treat proxy signals as the thing itself** — a send log is not delivery confirmation, a derivative doc is not the source of truth, a compile is not a test run; name what direct evidence would look like and get it
- **Don't emit a synthesized default when a lookup returns empty** — absence of data must propagate as UNCERTAIN/DENY, not as zero, false, or a plausible fabricated value
- **Don't fix one instance of a class-level problem** — find and fix all occurrences in the same pass or explicitly flag the remainder; single-instance fixes signal awareness without resolution
- **Don't use formal agent-style copy in user-facing banners or messages** — natural language only; "This job has not started — it needs its setup." is rejected

## Open questions / known gaps
- Parallelism and bookkeeping hygiene conflict: state-sync rules are known but deprioritized exactly when velocity is highest — no mechanical sync anchor yet
- IPC peer aliasing is unreliable; peer identity must be verified live before send, but the workflow for confirming round-trip delivery is ad hoc
