---
brief: Run the code in the state that matters before declaring done — collecting/compiling/linting is not running. Enforced by the declared-ready Stop hook.
triggers:
  - topic:verification
  - topic:declared-ready
  - phrase:"all tests passing"
  - phrase:"it works now"
  - tool:guard-declared-ready
related:
  - rules/testing.md
  - features/declared-ready-stop-hook.md
  - scripts/hooks/declared-ready-stop.sh
tier: 1
category: rules
updated: 2026-06-15
stale_after_days: 365
---

# Exercise the change before you call it done

A change is "done" when you have **run the affected code path in the state that
matters and read the actual result** — not when it looks right, type-checks, or
compiles. Inspection is not verification. The strongest, most-recurring failure
in this account's history is declaring success off an artifact that was never
executed.

Graduated from atone slug `declared-ready-without-runtime-exercise` — **S3, 5–6×
recurrence** across unrelated projects and models (a Swift menu-bar that shipped
a guaranteed crash with the test target commented out; a TS refactor; a release
script; a not-on-PATH CLI; an S3 suite called "green" after `pytest
--collect-only`). The pattern survived a purely-advisory regime for ~90 warnings,
which is why it is now a **rule with a mechanical gate**, not a topic-tag.

## The rule

Before writing/saying done · works · fixed · passing · verified · shipped:

1. **Run it.** Execute the path you changed — the test, the endpoint, the
   command, the UI interaction — and read the pass/fail line.
2. **`collect ≠ run`.** `pytest --collect-only`, `tsc --noEmit`, an import-check,
   a lint, a dry-compile — **none of these execute a single assertion.** They
   tell you the code *parses*, not that it *works*. Never report a suite
   "green"/"validated" off a collect or a compile.
3. **Induce the state that matters.** If the behavior only manifests under a
   condition (warning-level memory pressure, a network fault, an empty list,
   warm-vs-cold), induce that condition and observe — don't assert the happy path
   and infer the rest.
4. **Mark the un-exercisable honestly.** If you genuinely cannot run something
   (throttled sandbox, missing hardware), write `UNCONFIRMED — <reason>`, not a
   checkmark. An honest gap is worth more than a false pass.

## The enabling half — make running cheap (see the convention)

This rule binds painlessly only when verifying is cheap. The companion
[`conventions/run-and-observe-affordance.md`](../conventions/run-and-observe-affordance.md)
asks every project to expose a one-command run-and-observe affordance (`make
verify`, a `--self-test` flag, an env-gated debug hook). Lower the cost and
exercise-by-default becomes the path of least resistance instead of a tax.

## Enforcement (mechanical, not advisory)

`scripts/hooks/declared-ready-stop.sh` (Stop hook) blocks a turn that edited
source/test files and claims success when no run signal appears that turn. It is
loop-safe (blocks once per claim, then steps aside) and proportional (silent on
docs-only edits, renames, pure conversation). Mute for a session:
`touch ~/.claude/.no-declared-ready-gate`. Design:
[`features/declared-ready-stop-hook.md`](../features/declared-ready-stop-hook.md).

## What this rule does NOT mean

- Not every keystroke needs a full suite — scale the run to the change (a typo
  fix gets a syntax check; a transform gets a smoke test with real data). The
  scale ladder lives in `rules/testing.md`.
- "Run it" is satisfied by any real execution that exercises the change, not
  necessarily the whole test suite.

## Diagnostic signal

You're about to type "done"/"works"/"passing" and the last thing you actually
*ran* was a collect, a compile, a lint, or nothing at all. Stop — run the path.

## Related
- `rules/testing.md` — scale-to-task ladder + `[collect-not-run]`, `[declared-ready]`
- Atone lineage: `bash ~/.claude/scripts/atone.sh search declared-ready`
