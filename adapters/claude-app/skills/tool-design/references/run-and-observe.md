# One command to run it and see the result

The biggest lever for getting more verification is less friction, not more
pressure. A change gets inspected instead of exercised mostly because
exercising is expensive: build, launch, induce a state, read logs. Lower that
cost and running the thing becomes the easy path. Raise it and even a careful
builder settles for "the code looks right".

## The convention

1. **Every project has one command that runs the thing and shows the
   result.** Pick the cheapest shape that fits:
   - `make verify` or `make check`, a thin target over the real run
   - a `--self-test` or `--smoke` flag on the project's own CLI
   - an environment-gated debug hook that induces a state and reports it in
     one command (`MYAPP_TEST_HOOKS=1 myapp --induce warn-level`)
   - a `scripts/verify.sh` that boots the minimum, exercises the change and
     prints pass or fail
2. **It induces the states that matter, not only the happy path.** A command
   that only walks the golden path rebuilds the blind spot it exists to remove.
   Make it cheap to drive the warning level, the injected fault, the empty
   input, and cold start against warm.
3. **Ask early.** At the start of a build, ask "what is the cheapest way to
   actually run this?" and build that before the feature, so every later
   "done" has a one-command check behind it.

## Why it cannot backfire

A new rule is context every session carries, and a new gate can over-fire and
get muted. An affordance only removes a tax. It sits unused until needed and
costs nothing when idle, which makes it the first and safest verification
lever, ahead of any rule or gate.

## What it does not require

- A CI rig or a coverage target. The bar is one cheap command that runs the
  change and shows a result.
- A framework. A ten-line `scripts/verify.sh` counts.
- New ceremony. A library whose `make test` really runs already has it.

## In chat

In claude.ai the sandbox is the place to run it. When you build a script or a
small tool there, write the run command alongside it and run it before saying
it works. When the tool runs only on the user's machine, hand them the one
command and say what output means pass.

## The signal

You are building something and there is no single command that shows your
change working. Make one before going further.
