---
brief: Test every non-trivial change scaled to task size; clean-slate checklist; verify each change independently
triggers:
  - topic:testing
  - topic:verification
  - phrase:"it works"
related: []
tier: 1
category: rules
updated: 2026-04-24
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

## UI/frontend verification

For UI or frontend changes, start the dev server and use the feature in a browser. Test golden path AND edge cases. Type checking and test suites verify code correctness, not feature correctness — if you can't test the UI, say so explicitly rather than claim success.

## Topic-tagged rules (from recurring mistake patterns)

Scanned from `~/.claude/mistake-patterns.md`. Each rule has happened enough times to be worth flagging up-front.

- `[root-cause]` — Don't patch symptoms. When a fix doesn't work, stop and investigate WHY before trying another patch. "Fix attempt without root cause" thrashes the tree without progress.
- `[re-edit-thrash]` — Editing the same function/block 3+ times in a row means you don't understand it yet. Stop editing, re-read the surrounding context, form a hypothesis, then edit once.
- `[pagination]` — API responses that look "done" may be paginated/truncated. Check for `next_cursor`, `has_more`, response length hitting a round cap (50, 100, 1000). Don't assume complete.
- `[truncation]` — Tool-result truncation is silent. A 200-line file shown via `head -50` reads as complete if you forget the flag. Verify with `wc -l` or re-read full.
- `[binary-rebuild]` — Fix committed ≠ fix applied. For compiled artifacts (Swift binaries, Go builds, Rust, bundled JS), re-run the build before claiming done.
- `[render-before-judge]` — Don't call a value "wrong" based on its number alone. Render it — visually, in the browser, in stdout — then judge.
- `[human-note]` — `NOTE(by human)`, `HACK`, `IMPORTANT` comments mark tested deliberate choices. Changing without asking breaks an invariant you don't see.
- `[post-compact]` — After a `/compact`, state you held in conversation is gone. Re-verify process/file/branch state before acting, even for things you "just did" pre-compact.
