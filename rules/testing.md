---
brief: Test every non-trivial change scaled to task size; clean-slate checklist; verify each change independently
triggers:
  - topic:testing
  - topic:verification
  - phrase:"it works"
related: []
tier: 1
category: rules
updated: 2026-09-18
stale_after_days: 90
---
# Test every non-trivial change, scaled to the task

- Trivial (rename, string): syntax check. Small (utility): call with 1-2 inputs. Medium (endpoint, transform): smoke test with real data, curl it. Large (pipeline, migration): dry-run 2-3 items, then the full set.
- After writing a function, call it; after a route, fetch it; after a file export, read it back. Edge cases: empty, null, missing fields.
- Clean slate first: no stale processes on the port, no leftover temp files, no env from another context.
- Verify each of N changes independently; flag any you could not: "I also changed X, please verify". Never call a value wrong from the number alone without rendering it.
- `NOTE(by human)`, `HACK`, `IMPORTANT` mark a deliberate choice: ask first with reasoning, then verify visually or functionally.
- UI: `rules/ui-visual-verification.md`. The 17 recurring patterns: `rules/testing-patterns.md`.

A halt under this rule needs a genuinely missing thing, information or authority not yet granted; holding both, act (`never-halt-on-authority-you-hold.md`).

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/testing.md`
