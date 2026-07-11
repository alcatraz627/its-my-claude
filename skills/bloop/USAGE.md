# /bloop — Usage Guide

## What it does

Drives a non-trivial build through six stages — **plan → build → review → validate → fix
→ docs** — with an adversarial sub-agent validation gate that independently tries to break
the work. Produces the change, a persisted validation report, and updated docs.

## Usage

```
/bloop [task] [--from <stage>]
```

| Argument         | Type     | Description                                                                               |
| ---------------- | -------- | ----------------------------------------------------------------------------------------- |
| `task`           | optional | What to build, in a sentence. Omit to run the loop on the change already in progress.     |
| `--from <stage>` | optional | Resume at `plan` / `build` / `review` / `validate` / `fix` / `docs` instead of the start. |

## Examples

### Example 1: full loop on a new task

```
/bloop add a token-bucket rate limiter to the API middleware
```

Plans it (surfacing any fork), builds in committed units tests-first, self-reviews by
exercising the limiter under real load, dispatches an adversarial validator (which tries
to break it — burst traffic, clock skew, the empty-config path), fixes what it finds and
adds a regression test for it, then updates the docs and commits.

### Example 2: validate an in-flight change

```
/bloop --from validate
```

Skips planning/building — runs the adversarial gate on the diff you already have, then
fix → docs. Use when you've built something and want the rigorous check before shipping.

### Example 3: no-arg, current change

```
/bloop
```

Applies the whole loop to whatever is currently in progress (uncommitted diff / current
branch), inferring the task from the change.

## Caveats

- **The validate gate is not skippable** — it is the point of the skill. A change trivial
  enough to skip validation should not go through /bloop; just make it.
- **Not a fleet.** /bloop is structured single-threaded build with ONE adversarial
  validator (right-sized per `contain-subagent-token-sprawl`), not parallel fan-out.
- **Never pushes on its own.** Commits per unit locally; every push/deploy is a fresh ask.
- **Sub-agent report persistence is parent-side.** A gcc guard blocks sub-agents from
  writing report files, so the validator returns findings inline and /bloop writes them to
  `.claude/output/`. Verify the file exists before relying on it.
- **Needs a runnable surface to review/validate.** For pure-docs or config changes with no
  runtime path, the review/validate stages degrade to a read-through — say so.

## Dependencies

| Dependency                             | Type         | Notes                                             |
| -------------------------------------- | ------------ | ------------------------------------------------- |
| `GUIDELINES.md`                        | Shared rules | Read at start of every run                        |
| `rules/structure-over-one-shotting.md` | Rule         | Phase 1 (plan before execute)                     |
| `rules/exercise-based-verification.md` | Rule         | Phases 3 & 5 (run, don't inspect)                 |
| `rules/model-tier-routing.md`          | Rule         | Phase 4 (pin the validator's model)               |
| `rules/sub-agent-outputs.md`           | Rule         | Phase 4 (persist the report) + the guard conflict |
| `rules/pushback-and-self-criticism.md` | Rule         | Phase 5 (non-defensive fix)                       |
| `Task` tool                            | Tool         | Phase 4 dispatches the adversarial validator      |
| feature branch + git                   | State        | Phase 2 commits per unit                          |

## Tips

- The validator earns its cost most when you feel done — that's exactly when the
  plausible-but-wrong bug hides. Don't skip it because self-review looked clean.
- Give the validator the load-bearing CLAIMS to attack ("the guard holds for identical
  input", "the $0 layer is model-independent"), not just "review this" — targeted
  adversarial prompts find real bugs; vague ones rubber-stamp.
- When a finding is "the rule is unenforceable prose," the fix is a **mechanism** (a
  checkable step), not a firmer sentence. Prose doesn't bind a model.
- Pair with `/skeptical-review` for a lighter pass when the full six-stage loop is overkill.
