---
brief: Before asserting how a subsystem works (authority, data flow, hot path), name the file:line that proves it — or read the code first; same precheck for process-completion claims ("the migration ran", "the deploy succeeded") — name the artifact that proves it
triggers:
  - topic:architectural-claim
  - topic:authority
  - phrase:"is the authority"
  - phrase:"source of truth"
  - phrase:"hot path"
  - phrase:"just a JWT"
related:
  - rules/communication.md
  - rules/exercise-based-verification.md
tier: 1
category: rules
updated: 2026-07-28
stale_after_days: 90
---

# Architectural claims require file:line citation

Before stating how a subsystem works — its authority, cost model, data flow, "hot path" — **name the file:line that proves the claim, or read the code first**. Pattern-matching from prior projects is not evidence.

Graduated from atone slug `structural-claim-without-reading-code` (S3, **same-conversation repeat** after correction 2026-05-08).

## Why this gets its own rule

Pattern-matching feels like knowing. The agent confidently asserts "JWT verify is the only cost on the auth path" or "Python BE is the final authority on token validity" — both turned out wrong in adjacent subsystems of the same conversation. The first correction *didn't* prevent the second instance because the agent narrowed the lesson ("verify auth subsystem X") instead of broadening it ("verify before asserting").

## The rule

Before typing any of these phrasings, **pause and require a file:line citation in the response**:

- "X is the authority on Y"
- "X is the source of truth"
- "X is the final check"
- "X is the hot path"
- "Y is just a [JWT / cookie / cache hit / single function]"
- "X writes / owns / minted / refreshes Z"

If you cannot name a file:line that proves it, **read the code that decides X first**. Don't type the claim until you have.

**Precheck (answer before typing the claim):** Can I name the exact file:line that proves this statement right now? YES → include the citation. NO → read the code first, then type the claim. This is the same gate the atone event format records as `precheck`; treat it as a decision point, not a reminder.

## Name the instrument, and ask whether it measures the claim

The precheck above asks whether you can cite the line. Two failures pass that check
and are still wrong, and both were live on 2026-08-26. First, the citation resolves but
the value there has moved: a count quoted from a report written three days ago, a
"validated" instrument that was never on disk (audit P7, citation currency). Second,
the instrument is real and current and measures a different thing: `git status`
porcelain read as "someone is mid-edit", IPC recency read as "the peer is silent", a
200 read as a rendered page (RCA `mist-20260826-091157-3c`, thirteen instances in one
warden lane). So the fuller precheck:

> Before asserting any state, name the instrument that told you, in one clause, and
> ask two things: does that instrument measure the thing I am about to claim, and is
> its reading current? If either answer is no, say what you actually checked instead.

A citation that still resolves is not a claim that is still current. A check and a
claim about different things, with nothing in the output saying so, is the shape.

## Process-completion claims get the same precheck

The rule above covers *how a subsystem works*. The same verification failure
happens one layer up, on *what a process did*: "the migration ran", "the deploy
succeeded", "the test passed", "the cron fired". Before writing that a step is
done / succeeded / passed, **name the artifact that proves it** — a log line, an
exit code, a row count, a file timestamp, elapsed time (the clock, not your sense
of how long it felt) — or run the check first.

Boundary with `rules/exercise-based-verification.md`: that rule binds when *you*
changed code and must run the changed path before claiming done. This clause
binds when you assert the outcome of any process — yours, a cron's, a deploy
pipeline's, another agent's — without holding the evidence. Same precheck, same
gate: can I name what proves this right now?

## Document provenance gets the same precheck

When asserting a document is "the spec", "the contract", or "the source of
truth": also check its provenance — is it human-authored, or Claude-generated
documentation downstream of the application? A Claude-authored doc treated as a
spec produces a circular review.

## "Is this deliberate?" is answered by the tests, not by the comments

A distinct question from how a subsystem works: whether some existing behavior
was CHOSEN or merely landed. Reading the code is not enough here, because the
artifact that holds the answer is usually the test.

**A comment names the intent behind one line. A test names the contract.** A
considered comment sitting next to a check tells you someone thought about why
the check exists. It tells you nothing about whether its current tier, threshold,
or placement was decided. Treating a thoughtful comment as evidence that the
whole question was settled is the specific error.

Before calling an existing behavior deliberate or accidental:

1. Grep the test file for the behavior, not just the source.
2. Read the test NAMES. A name like "a body missing the shape ships, with each
   omission noted" states a contract outright.
3. Only then read the comments, as intent rather than as ruling.

**Worked case, 2026-08-15, and both parties made the same mistake.** A CI peer
and I separately examined a guard where two positive shape assertions sat in the
non-blocking tier. A comment three lines above justified why the assertions
existed. I read that comment and withdrew a finding. They read it and ruled the
tier was an open question. The test file pinned it as deliberate, in a test whose
name said so, one grep away from both of us. They found out by implementing the
change and watching three tests go red.

Note the asymmetry that makes this worth a rule: the comment was accurate about
what it described. It simply did not describe the thing either of us needed. A
correct comment is not a wrong one, so nothing about it reads as a warning.

**A weaker form to watch for.** In that same test, the case matching the contract
asserted only that a note appeared, never that the body shipped. The contract
lived in the test's NAME and in a neighbouring assertion. A test whose name
carries a guarantee its assertions do not fully pin is a weaker guard than it
looks, and it is the `[negative-checker-blind-to-omission]` shape wearing a
different costume. When a test name is your evidence, check that an assertion
backs it.

## What this rule does NOT mean

- Don't bury every sentence in citations. The rule fires on *authority/control-flow* assertions, not on uncontroversial descriptive prose.
- Loose summaries are fine: "the worker handles deliveries" doesn't need a citation. "The worker is the only writer to the deliveries table" does.

## When the same correction lands twice in one session

The second instance is the **same overconfidence** in a neighboring subsystem. Treat any in-session repeat of this pattern as auto-S3 and write the RCA — the system is screaming.

## Diagnostic signal

User responds with "did you actually read X?" or "show me where" — for any sentence that asserts authority. That's the pattern firing.

## Related

- `rules/communication.md` § "state verification"
- Atone event: `bash ~/.claude/scripts/atone.sh search structural-claim`
