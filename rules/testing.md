---
brief: Test every non-trivial change scaled to task size; clean-slate checklist; verify each change independently
triggers:
  - topic:testing
  - topic:verification
  - phrase:"it works"
related: []
tier: 1
category: rules
updated: 2026-07-28
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

For UI or frontend changes, start the dev server and use the feature in a browser. Test golden path AND edge cases. Type checking and test suites verify code correctness, not feature correctness — if you can't test the UI, say so explicitly rather than claim success. For a *verified* UI claim, **read the screenshot back and judge it visually** — drive headless Chrome (puppeteer / Chrome-for-Testing) and inspect the rendered image, not just the assertion count. A green test run with a zero exit code is not the same as having seen the pixels.

**[design-mocks] Before implementing any user-facing UI feature** (labels, creation flows, module structure, form layouts), grep for design mocks or Figma specs for the surface. If they exist, consult them before writing a line of UI code. Shipped UI that ignores existing mocks is a known S3 recurrence.

**Multi-state surfaces: one state is not verification.** If the surface has theme/appearance states (dark AND light), open/closed variants, or responsive breakpoints, exercise the changed surface in EACH state before claiming verified — or scope the claim to what you actually saw ("verified in dark only"). Dark-only sign-offs that shipped a broken light theme are a recurring S3 (`declared-ready-without-runtime-exercise`, 2026-07-02 and 2026-07-07). Cheap second reader: run `lm see` on the screenshot alongside your own judgment.

## Topic-tagged rules (from recurring mistake patterns)

Scanned from `~/.claude/mistake-patterns.md`. Each rule has happened enough times to be worth flagging up-front.

- `[root-cause]` — Don't patch symptoms. When a fix doesn't work, stop and investigate WHY before trying another patch. "Fix attempt without root cause" thrashes the tree without progress. Prefer a **runnable probe** that *proves* the mechanism before you touch the fix — a throwaway `probe-*.js`/script isolating the one unknown (the opaque-origin, the missing host, the vanished row). Establish the cause by experiment, not hypothesis: **probe → confirm → fix**, not read → guess → fix. And before you attribute a failure to the code you changed, rule out the harness first — a network / abort / timeout error (ECONNABORTED, ERR_NETWORK, a killed in-flight request) is environmental until proven otherwise, and a stale reload, a leftover process, or a `.pyc` write masquerades as a product bug.
- `[re-edit-thrash]` — Editing the same function/block 3+ times in a row means you don't understand it yet. Stop editing, re-read the surrounding context, form a hypothesis, then edit once.
- `[pagination]` — API responses that look "done" may be paginated/truncated. Check for `next_cursor`, `has_more`, response length hitting a round cap (50, 100, 1000). Don't assume complete.
- `[truncation]` — Tool-result truncation is silent. A 200-line file shown via `head -50` reads as complete if you forget the flag. Verify with `wc -l` or re-read full.
- `[binary-rebuild]` — Fix committed ≠ fix applied. For compiled artifacts (Swift binaries, Go builds, Rust, bundled JS), re-run the build before claiming done.
- `[render-before-judge]` — Don't call a value "wrong" based on its number alone. Render it — visually, in the browser, in stdout — then judge.
- `[human-note]` — `NOTE(by human)`, `HACK`, `IMPORTANT` comments mark tested deliberate choices. Changing without asking breaks an invariant you don't see.
- `[post-compact]` — After a `/compact`, state you held in conversation is gone. Re-verify process/file/branch state before acting, even for things you "just did" pre-compact.
- `[declared-ready]` — Never announce a feature/fix as done without running the code path at least once. "Tests pass" is not "I ran it." Start the server, call the endpoint, trigger the flow. If you can't run it, say so explicitly. (Now mechanically gated — see [`rules/exercise-based-verification.md`](exercise-based-verification.md) + the declared-ready Stop hook.)
- `[collect-not-run]` — Collecting, type-checking, or dry-compiling a suite is NOT running it. `pytest --collect-only`, `tsc --noEmit`, an import-check, a lint — none execute a single assertion. Never report "green"/"passing"/"validated" off a collect or compile; run it and read the pass/fail line. (Sibling of `[declared-ready]`.)
- `[known-gap-tripwire]` — Ship a deliberate gap (a bug you're not fixing yet, a behavior not wired) as a STRICT failing marker asserting the desired end-state, not a skip. In pytest: `@pytest.mark.xfail(reason="<tracked item>", strict=True)`. It documents the gap AND self-retires — the day the gap closes it flips xpass→FAIL, forcing the marker's removal. A plain skip rots silently; a strict-xfail tracks the bug's lifecycle for you.
- `[test-as-spec]` — When a test simulates a process that will run for real elsewhere (a migration, a batch job, a protocol), make the simulator encode the REAL decision rules so the test doubles as the executable spec, and derive its magic numbers from the fixtures (`len([x for x in SEED if x.copies])`, not `== 6`). MANDATORY guardrail: the simulator's docstring must state what it deliberately does NOT model (delta passes, >5GB branches, real checksums) — a simulator that hides its own scope is worse than none, because "the test passed" gets misread as "the real job is proven."
- `[negative-checker-blind-to-omission]` — A validator built only of prohibitions (`should_not_contain`, "must not", deny-lists) is vacuously true on empty, missing, or truncated output: it detects bad-presence, never good-absence. Any gate that must actually hold a line needs at least one positive assertion (a required field is present, a value is in range), not only "X must not appear." A config entry that only shapes and never gates is the same trap. This is about the check's *shape*; testing against unrepresentative data is a separate failure.
- `[mutation-test-the-guard]` — A guard is not done until you have **watched it fail**. A green suite says nothing about a guard — only that it didn't fire. Break the exact thing it protects, confirm THAT test goes red, restore (copy-based — never `git checkout`/`stash`, which wipes uncommitted work), confirm green again. Mutation-test each guard **individually**: if reverting one fix alone stays green, that fix is unpinned. A mutation that stays green means the TEST is the bug, not the code. Five ways a guard passes while broken (four in one session, jegs-jul-14): the test calls the helper directly so the real call site is never exercised; two fixes cover one case so neither is individually pinned; the test row errors either way so it cannot tell fix from bug; a "drift guard" pins a constant against a literal in the SAME file, so it only agrees with itself instead of READING the other side; and a no-op mutation (a term that could never match) is read as a pass. A fixture can make the guarded behavior untestable BY CONSTRUCTION (an all-opaque alpha fixture makes compositing and alpha-drop byte-identical) — that is not bad luck, it is a blind fixture.
- `[generated-artifact-scan]` — After generating a CSS file, codegen output, migration artifact, or any file other code references by content: read the generated output against the referencing code before calling done. A green build proves the generation ran, not that the output is correct.
