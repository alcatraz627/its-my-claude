---
brief: "X stays / X unaffected / only threading needed" claims in plans, design docs, and reports must immediately become a verification task + a Standing-constraints checkpoint entry; mixed thread-vs-rebuild framing must be resolved with the user BEFORE implementation.
triggers:
  - topic:design-doc
  - topic:architecture-change
  - topic:refactor
  - skill:core-dump
  - skill:catchup
  - phrase:"only threading"
  - phrase:"unaffected"
  - phrase:"stays as is"
related: [rules/structural-claim-without-reading-code.md, features/context-retention.md, rules/testing.md]
tier: 1
category: rules
updated: 2026-09-18
stale_after_days: 180
---
# A "stays unchanged" claim is a constraint, not a sentence

When a plan, design doc or report written this session says something existing survives the change ("the UI stays, only threading", "endpoint X unaffected", "surfaces reused"), promote it in the same turn:

1. A Task-tool task: "verify <X> unaffected after implementation".
2. A Standing-constraints entry in the Resume Contract, **verbatim**, with the check that would catch its loss. A parity ledger's rows are SURFACES (this page, this table, this input), not behaviours.

Mixed framing ("thread the existing surfaces" here, "rebuilt" there) is resolved WITH THE OWNER into an explicit parity-or-rebuild statement before implementation; checkpoint compression otherwise resolves it toward momentum and drops the constraint.

Deleting a surface silently is its own rule: `rules/no-silent-ui-surface-deletion.md`.

Diagnostic: writing "X stays / unaffected / just threading" and X is in no task and no constraints entry.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/invariant-graduation.md`
