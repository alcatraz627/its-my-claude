---
brief: A blocked_on USER: prefix means the owner can act on it today. A prerequisite mislabelled USER: renders as an owner gate and gets read back as a real ask by the agent that wrote it. The check that needs no label: of the things about to go in front of the owner, which can they act on today? Anything waiting on other work is blocked-by that work.
triggers:
  - topic:owner-gate
  - topic:blocked_on
  - phrase:"needs you"
related:
  - rules/owner-decisions-go-through-a-wizard.md
  - skills/tasks/SKILL.md
tier: 1
category: rules
updated: 2026-09-18
stale_after_days: 180
---
# `USER:` means the owner can act on it today

Of the things about to go in front of the owner, which can they act on today? Anything waiting on other work is `blocked-by` that work, whoever eventually decides it. A prerequisite mislabelled `USER:` renders as an owner gate and gets read back as a real ask by the agent that wrote it.

- A UI is a medium, not an exemption. Count what the surface asks the owner to answer; more than one, and `rules/owner-decisions-go-through-a-wizard.md` governs it. **A decision SET is ONE decision page, never N rows** (owner, 2026-08-26).
- The pick was never the hard part. The owner's sentence is the ruling; options are shorthand that seed it. Size any decision surface for prose. A question arriving with the agent's confident pick attached is usually one to default and record, not ask.
- A gate set before the owner's latest ruling is re-derived, never repainted (`rules/stale-belief-as-current-state.md`).

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/owner-gate-means-actionable-today.md`
