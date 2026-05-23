---
brief: Before asserting how a subsystem works (authority, data flow, hot path), name the file:line that proves it — or read the code first
triggers:
  - topic:architectural-claim
  - topic:authority
  - phrase:"is the authority"
  - phrase:"source of truth"
  - phrase:"hot path"
  - phrase:"just a JWT"
related:
  - rules/communication.md
tier: 1
category: rules
updated: 2026-05-15
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
