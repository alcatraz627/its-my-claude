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
updated: 2026-09-18
stale_after_days: 180
---
# No silent deletion of a UI surface

Before deleting, removing or replacing a component, page or route: did it appear in any prior owner-reviewed UI round? If yes, this turn needs a parity-ledger entry or the owner's explicit approval before the deletion. **Zero importers is not evidence**: an orphan this work stream created reads identically to one that was always dead; only the review history tells them apart. Build-time complement of `rules/invariant-graduation.md`.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/no-silent-ui-surface-deletion.md`
