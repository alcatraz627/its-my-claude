# Comments

Comments are for humans first, AI agents second, machines never. A machine
only needs the code to be correct and never reads the prose. So every comment
exists for a person reading the file later, and each rule below follows from
that.

## The rules

1. **The first sentence of a non-trivial docstring is code-agnostic.** It says
   what the thing is in the system, so a non-engineer roughly follows it.
   Mechanism comes after.
2. **Speak from the caller's side, not the machine's.**
   - Bad: "Sets `_draining=True` so the main loop breaks before claiming new
     work."
   - Good: "Ask the worker to stop. Safe to call from a signal handler,
     because the real shutdown work happens in `drain()`."
3. **Never restate what the code does.** The payload is what the next reader
   could not derive from the code alone: the constraint, the reason for a
   workaround, the deliberate surprise, or a mechanism they could not infer
   (an ordering dependency, a trick, a protocol). The test is "could they work
   this out from the code?", not "is this a why or a how?"
4. **Strip anything that rots once the work ships.** Plan references ("Phase
   2.B8", "Track H", "Round 3 #1.2"), before-and-after history ("pre-fix",
   "this used to be X"), TODOs for work that already shipped, "see PR #1234"
   and "as discussed on <date>". History belongs in the commit message, the PR
   or a design doc.
5. **Keep agent notes apart from human comments.** A note that exists only to
   steer a future agent through ongoing work goes in its own block, marked
   `[claude@<date>]`, dense and technical. A human comment never carries that
   tag or any planning narrative.
6. **A docstring over 8 lines is an essay.** Move it to a doc and link to it.
   Per-field comments stay one line.
7. **Stale comments are worse than none.** After changing code, read the
   comments nearby. Update or delete shipped TODOs, "currently X" claims where
   X changed, and references to deleted symbols. When unsure, delete.
8. **Major entrypoints get a 2 to 3 sentence orientation** ("the worker
   process entrypoint", "the request handler for uploads"), so a reader who
   lands there knows where they are.
9. **Context repeated in 3 or more places goes in one doc**, linked from each
   place. Copies drift.

## Shape of a non-trivial docstring

Up to three paragraphs, in this order. Skip any you do not need.

1. Purpose, with no jargon and no code references.
2. Runtime contract: inputs, outputs, side effects.
3. Caveats: races, gotchas, why not the obvious approach. Dense is fine.

A simple helper gets paragraph 1. Most things need 1 and 2. Paragraph 3 is
rare and load-bearing when present.

## Example: a human comment and an agent note side by side

```python
# The breaker bucket is resolved at call time so per-customer scoping
# works without re-decorating. Bucket = module in global mode,
# module:team_id in per-customer mode.

# [claude@2026-05-11] When the consensus PR lands, audit every callsite
# for the resolve_bucket pattern. Any that still cache the breaker at
# decoration time will skip per-customer scoping.
def resilient(name: str, ...):
    ...
```

The first block stays true as long as the code does. The second is
scaffolding for one piece of work and is deleted when that work ships. Mixing
them, a human comment with a tag suffix or a plan reference inside it, is the
failure this rule exists to prevent.

## The project's rubric wins

If the repo has its own comment-style doc, read it first. It supersedes this
file where they disagree.
