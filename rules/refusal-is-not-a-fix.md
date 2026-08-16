---
brief: When a tool cannot determine something, refusing and making the human supply it is not a fix, it is moving the cost onto them. Exhaust the derivable signals first, especially ones a reviewer already handed you, and fail closed only after deriving genuinely fails.
triggers:
  - phrase:"cannot determine"
  - phrase:"requires the user to specify"
  - phrase:"no reliable way to"
  - topic:resolution
  - topic:ambiguity
related:
  - rules/right-sized-code.md
  - rules/pushback-and-self-criticism.md
paths:
  # Scoped rather than always-on: it costs ~1k tokens and the always-on budget
  # is already ~44k. The rule's REAL trigger is behavioural (about to add a flag
  # that asks the human something derivable) and paths: cannot express that, so
  # this scopes to the file types where the concrete act happens: writing the
  # code. It will not fire while writing prose about a tool. The triggers: block
  # and the rules/00-index.md brief carry it the rest of the way; read it on
  # demand from there. Revert by deleting this block.
  - "**/*.sh"
  - "**/*.py"
  - "**/*.js"
  - "**/*.cjs"
  - "**/*.ts"
tier: 2
category: rules
updated: 2026-08-16
stale_after_days: 180
---

# Refusal is not a fix

When a tool hits something it cannot determine, adding a flag so the human
supplies the answer is not solving the problem. It is moving the problem onto
the person who asked. A refusal is sometimes the correct FINAL state, but it is
never the correct FIRST answer, and it must not be reported as a fix.

Owner ruling, 2026-08-16, verbatim: "refusal is NOT a fix it is a cope."

## The rule

Before writing "cannot be determined", "requires the user to specify", or a
flag whose only job is to be told the answer:

1. **List the signals that could derive it.** Environment, filesystem, the
   transcript, the artifact's own content, anything a related tool already knows.
2. **Test each one against reality**, not against your model of reality. A signal
   that looks authoritative can be wrong; see the worked case.
3. **Prefer content over names.** Identity questions ("which of these is mine?")
   are usually answerable by asking which candidate CONTAINS what you already
   have. Content-matching is self-verifying in a way name-matching never is.
4. **Only then fail closed**, and when you do, hand back evidence the caller can
   act on rather than a bare error.
5. **Cache the derived answer** so the cost is paid once, not per call.

## The tell

You are writing a caution sentence that explains why you stopped. "I have not
tested this under load." "That is a change to a hook I would rather not make
blind." Real caution names a specific risk and a specific check that would
retire it. A rationalization names a vague risk and no check, and it appears
exactly when deriving the answer would have been more work than refusing.

The second tell: **a reviewer handed you the leads and you did not use them.**
That is the strongest possible evidence the problem was tractable, because
somebody outside your head already saw the path.

## Worked case

`/tasks` could not tell which task store belonged to the live session, because
the store is named for the session that CREATED the tasks and a task list
survives `/clear`. With 231 stores on the machine, the fallback raced them by
modification time and rendered other agents' queues as if they were the user's.

The first attempt shipped a refusal plus a `--pin` flag, making a human identify
an 8-hex id by eye. A peer had already supplied three leads and none were used.
The owner named it a cope, correctly.

What deriving actually looked like, in one probe:

- Subagent ids of the form `<agent>@session-<sid8>` LEAK a store id, and in the
  session under test they leaked the WRONG one, because unmatched harness
  subagents land in the transcript. Trusting the obvious signal would have
  reproduced the bug with more confidence.
- Background-task output paths carry the right store uuid, but only exist if a
  background task ran.
- **Task subjects in the live transcript matched exactly one store, 48 of 48,
  with no runner-up.** Content, not names. Self-verifying, always available,
  and it fails closed on a near-tie rather than picking.

Total cost of deriving it: one probe script and one shared resolver. The refusal
had already cost more than that to write.

## What this rule does NOT mean

- Not a ban on failing closed. Failing closed after deriving fails is correct,
  and is what the worked case does when the evidence is genuinely absent.
- Not a demand for certainty. A decisive-margin test (a clear winner, or refuse)
  is a legitimate answer to ambiguity.
- Not licence to guess. Guessing silently is the defect the refusal was reaching
  for; deriving is the third option that neither guesses nor delegates.

## Diagnostic signal

You are about to add a flag, a prompt, or a required argument whose only purpose
is for the human to tell you something you could work out. Or you are writing a
sentence explaining why you stopped short, and it names no check that would let
you continue.
