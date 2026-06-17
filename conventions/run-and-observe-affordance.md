---
brief: Every project should expose a one-command run-and-observe affordance so verifying a change is cheap — the friction-reduction half of exercise-based verification.
triggers:
  - topic:verification
  - topic:testing-affordance
  - phrase:"how do I run this"
  - phrase:"cheapest way to run"
related:
  - rules/exercise-based-verification.md
  - rules/testing.md
tier: 2
category: conventions
updated: 2026-06-15
stale_after_days: 365
---

# One-command run-and-observe affordance per project

The headline lever for getting more verification is **not more pressure — it is
less friction.** An agent inspects instead of exercises mostly because exercising
is expensive (build, launch, induce a state, read logs). Lower that cost and
verification becomes the path of least resistance; raise it and even a
well-intentioned agent rationalizes "the code looks right."

This is the enabling companion to [`rules/exercise-based-verification.md`](../rules/exercise-based-verification.md).
That rule says *run it before you call it done*; this convention makes running
**cheap enough that the rule binds without willpower.**

## The convention

1. **Every project exposes a single command that runs the thing and shows the
   result.** Pick the cheapest shape that fits:
   - `make verify` / `make check` (a thin target wrapping the real run)
   - a `--self-test` / `--smoke` flag on the project's own CLI
   - an env-gated debug hook that drills internal state headlessly
     (the sys-monitor `SYSMON_TEST_HOOKS=1` / `SYSMON_DEBUG=1` pattern — induce a
     state and observe it in one command)
   - a `scripts/verify.sh` that boots the minimum, exercises the change, prints
     pass/fail
2. **It induces the states that matter, not just the happy path.** A run-and-
   observe affordance that only exercises the golden path re-creates the very
   blind spot it exists to remove. Make it cheap to drive the warning level, the
   fault injection, the empty input, the cold-vs-warm.
3. **Construction-mode prompt:** at the *start* of a build session, ask **"what's
   the cheapest way to actually RUN this?"** — and build that affordance early,
   before the feature, so every later "done" has a one-command check behind it.

## Why this can't backfire (the safety argument)

Lowering verification friction can **neither kneecap nor overwhelm** the agent —
it only removes a tax. Unlike a new rule (context every session loads) or a new
gate (can over-fire and get muted), an affordance is pure capability: it sits
unused until needed and costs nothing when idle. That is why it is the
**first** and **safest** of the verification levers, ahead of any hook or rule.

## What this convention does NOT require

- Not a full CI rig or coverage target — the bar is *one cheap command that runs
  the change and shows a result*, not a test pyramid.
- Not a new framework — a 10-line `scripts/verify.sh` counts.
- A library with a real test runner already satisfies this if `make test` (or the
  equivalent) actually executes; the convention is about the *affordance existing
  and being cheap*, not about adding ceremony where it already exists.

## Diagnostic signal

You're in a build/feature session and there is no single command you can run to
see your change work. Before going further, make one.
