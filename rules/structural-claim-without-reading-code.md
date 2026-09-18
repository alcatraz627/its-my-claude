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
updated: 2026-09-18
stale_after_days: 90
---
# Architectural and completion claims need a file:line

Before typing "X is the authority / source of truth / final check / hot path", "Y is just a …", "X writes / owns / refreshes Z": **can I name the file:line that proves it right now?** No → read the code that decides X first.

- Name the instrument, then ask two things: does it measure the thing I am claiming, and is its reading current? A citation that still resolves is not a claim that is still current.
- Process claims get the same gate: "the migration ran", "the deploy succeeded", "the test passed" need the artifact (log line, exit code, row count, timestamp) or the check is run first.
- A document is "the spec" only after checking its provenance; a Claude-authored doc reviewed as spec is circular.
- "Is this deliberate?" is answered by the tests, not the comments: grep the test file, read the test NAMES, then the comments.
- A same-session repeat is auto-S3 with an RCA.

Diagnostic: the owner asks "did you actually read X?" or "show me where".

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/structural-claim-without-reading-code.md`
