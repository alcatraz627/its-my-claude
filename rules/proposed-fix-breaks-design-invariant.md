---
brief: Treat a design doc's goals/constraints section as a checklist, not background — before writing "mode A trades X for Y" framing, verify no consumer-rendered field diverges against a stated constraint
triggers:
  - topic:design-doc
  - topic:design-invariant
  - phrase:"lean vs enriched"
  - phrase:"trades freshness"
  - phrase:"fast vs correct"
related:
  - rules/structural-claim-without-reading-code.md
  - rules/grep-scope-before-claiming-absence.md
tier: 1
category: rules
updated: 2026-05-20
stale_after_days: 90
---

# A proposed fix must not break a stated design invariant

When proposing a design where two modes return the same fields differently (lean vs enriched, cached vs live, fast vs correct), **treat the goals/constraints section as a checklist** — re-ground the proposal against it before committing to any "mode A trades X for Y" framing.

Graduated from atone slug `proposed-fix-breaks-design-invariant` (S3, 2× recurrence, 2026-05-15).

## The incident

A jobs-list design doc proposed that *enriched* mode "skip the run join, derive total/processed from tasks live" while *lean* reads a stale `processed_count`. Framed in chat as "Lean trades freshness for cost; enriched is always-correct." This contradicted **constraint #4 in the same doc** (lean and enriched must not flip the displayed state for the same job) — different total/processed values would have produced different state classifications.

The constraint was in the doc's own goals section, written by the same agent, and never re-checked against the proposal. When the user pushed back, the agent dismissed atone as "framing tightening" — but the **design proposal was the mistake**, even though the bad code never shipped (the implementation later used a run-join in both modes).

## The rule

Before writing any "mode A vs mode B" comparison in a design doc:

1. Does the divergence affect any field the consumer **renders state from**?
2. If yes — is the divergence explicitly approved by a user-stated constraint?
3. If no explicit approval AND values diverge → **STOP**. Either align the modes on those fields, or surface the conflict to the user before committing to the framing.

## What this rule does NOT mean

- Modes legitimately differ on *additive* fields (extra aggregates, extra joins for detail). The rule fires only on fields that drive **state/classification** the consumer renders.
- Performance-vs-cost framing is fine when no rendered-state field diverges.

## Don't dismiss the atone on "caught in implementation" grounds

The proposal IS the mistake even if the code didn't ship. A design doc that contradicts its own constraints section will mislead the next reader. Catching it at implementation time is luck, not process.

## Diagnostic signal

You're about to write "mode A is fresher/faster/cheaper; mode B is more correct" — and you have not checked whether the consumer renders state from a field that differs between them.

## Related

- `rules/structural-claim-without-reading-code.md` — sibling "proposed without checking the named source of truth"
- Atone event + RCA: `bash ~/.claude/scripts/atone.sh search proposed-fix-breaks-design-invariant`
