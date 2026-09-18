---
brief: Never delete, remove, or replace a component, page, or route silently: if the surface appeared in any owner-reviewed round, this turn needs a parity-ledger entry or the owner's approval first. Zero importers is not evidence; the review history is.
triggers:
  - topic:ui
  - topic:delete
  - topic:refactor
  - phrase:"remove the old"
  - phrase:"clean up"
related:
  - rules/invariant-graduation.md
  - rules/ui-visual-verification.md
tier: 1
category: rules
updated: 2026-09-01
stale_after_days: 180
---

# No silent deletion of a UI surface

Everything above activates when someone *writes* a claim. The damage happens
later, during implementation, where a component gets deleted and no claim was
ever written to trigger the check. So the gate binds to the deletion itself.

Before deleting, removing, or replacing a component, page, or route:

1. Did this surface appear in any prior owner-reviewed UI round?
2. If yes, you need a parity ledger entry or explicit owner approval **in this
   turn**, before the deletion.

**Zero importers is not evidence.** The owner can have reviewed and approved a
surface that no code calls, and an orphan this same work stream created reads
identically to an orphan that was always dead. The import graph cannot tell you
which one you are looking at; only the review history can.

This is the build-time complement to the claim-level check above. The rule is
currently 7× S3 with four events in a single week, annotated in the session
briefing as a standing blind spot, which is why it now has two activation points
instead of one.

A halt under this rule needs a genuinely missing thing — information no derivation supplies, or authority not yet granted. Holding both, the rule does not apply: act (`never-halt-on-authority-you-hold.md`).
