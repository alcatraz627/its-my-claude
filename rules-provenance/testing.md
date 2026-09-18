---
brief: Test every non-trivial change scaled to task size; clean-slate checklist; verify each change independently
triggers:
  - topic:testing
  - topic:verification
  - phrase:"it works"
related: []
tier: 1
category: rules
updated: 2026-09-01
stale_after_days: 90
---

# Testing
Every non-trivial code change must be verified. Scale testing to the task.

## Scale testing to task size

- **Trivial** (rename, string change): syntax check only
- **Small** (utility function): call with 1-2 inputs, verify output
- **Medium** (API endpoint, transform): smoke test with real data — curl it, don't assume it works
- **Large** (pipeline, migration): dry-run with 2-3 item test input first, then full dataset

After writing a function, call it. After an API route, fetch it. After file exports, read the file back. Inspect edge cases: empty arrays, null values, missing fields. Skipping this has caused `[object Object]` bugs, silent data corruption, and Excel cell overflow.

## Clean slate checklist before tests/deploys

Before running tests or deploying, verify:
- No stale processes on the same port
- No leftover temp files from previous runs
- No environment variables from a different context

A dirty environment is the #1 cause of "it works on my machine" failures.

## Verify each change independently, not as a batch

When making N distinct changes in one edit, verify each one. Don't check the primary fix and let secondary changes ride along unchecked. If a secondary change can't be verified, flag it: "I also changed X — please verify." Never assume a value "looks wrong" based on the number alone without rendering it.

## Human-commented values require confirmation

Code with `NOTE(by human)`, `HACK`, `IMPORTANT`, or similar comments reflects a deliberate, tested decision. If you think it should change, ask the user first with your reasoning. If approved, make the change AND verify the result visually/functionally.

A halt under this rule needs a genuinely missing thing — information no derivation supplies, or authority not yet granted. Holding both, the rule does not apply: act (`never-halt-on-authority-you-hold.md`).

## UI/frontend verification

Moved 2026-08-27 to `rules/ui-visual-verification.md` (always-on by owner ruling: every project has UI). The short form: render it, read the whole frame before your prepared question, compare siblings, both themes, screenshot path in the claim.

## Topic-tagged patterns — moved to a scoped catalog

The 17 recurring-mistake patterns (`[root-cause]` `[pagination]` `[truncation]`
`[declared-ready]` `[mutation-test-the-guard]` `[real-input-distribution]` and
the rest) live in `rules/testing-patterns.md`, which autoloads when you touch
test files and is readable any time from the index. Corpus citations of
`rules/testing.md § [tag]` resolve there. Split per prime-demotion-0901 D2a,
2026-09-01.
