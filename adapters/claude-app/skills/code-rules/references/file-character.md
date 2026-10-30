# Check a file's character before applying a general rule to it

A general rule is written for the common case. Before you apply one to a
particular file, by moving code into it or by invoking a rule that would
forbid what you are about to do, take ten seconds to check whether the rule
fits this file. Files have a character: types only, hooks only, helpers only,
a contract anchor. A rule that is right in general can be wrong here, and
applying it blindly produces a change that looks correct and slips past
review.

## Two shapes

**1. The destination's character.** Before any "move X to Y", "consolidate
into Y" or "extract to Y" where Y already exists, read the first 20 or so
lines of Y. If Y is single-purpose (pure types, say) and X would break that
(dragging hook code in), pick another destination or split the move.

**2. Whether the rule applies at all.** Sometimes a general rule, read
literally, forbids what you are about to do, but the local case has a
load-bearing difference. A URL-contract anchor is not a speculative
abstraction. A runtime gate is not static config. Then:

1. name the rule,
2. state the difference in one sentence,
3. hand the decision to the user.

## An illustration

Say a rule reads "no constant without two callers". A module exports
`ROUTE_PATHS.settings = "/settings"` with one caller. Applied literally, the
rule says inline it. But the constant is the contract that external links and
tests key on, so it is an anchor, not a speculative abstraction. The right
move is one line: "This looks like the one-caller case, but it is a route
contract. Keep it?" Then the user decides.

## Why naming it and handing it back matters

Skipping the rule silently leaves the question open for the next agent.
Applying it silently looks like you ignored your own rule. Arguing past it in
a paragraph is talking yourself into it. Naming the tension makes the
deviation visible and revocable by the user.

## What this does not mean

- Not every edit needs an audit. The trigger is moving code into an existing
  file, or a general rule meeting an unusual case.
- Not a license to invent exceptions. The audit decides whether a rule
  applies. It never lets you excuse yourself from one that does.
