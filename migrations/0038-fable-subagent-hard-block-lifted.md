# 0038 — fable-as-sub-agent hard block lifted (sentinel-gated)

## Summary

`guard-model-tier.sh` job 2 no longer unconditionally blocks fable/mythos
sub-agent dispatches: the block steps aside while the human-owned sentinel
`~/.claude/.allow-fable-subagents` exists (created 2026-07-23, provenance
text inside the file). The expired promo branch (`.fable-subagent-promo`,
date-gated ≤ 2026-07-17) was removed in the same edit. Telemetry is
unchanged: every dispatch still lands in `~/.claude/logs/model-dispatch.jsonl`.

## Why

Owner instruction 2026-07-23 (versable-builder session catch-vb-3f): "Okay
let's lift the fable hard-block altogether" — first use: fable seats on the
CPRD functional-gap review. Sentinel-gated rather than deleted so the block's
machinery, message, and telemetry survive and re-arming needs no code change.

## Scope

One hook (`scripts/hooks/guard-model-tier.sh`) + docs that described the block.

## Label changes

None.

## Path moves

None. New file: `~/.claude/.allow-fable-subagents` (untracked machine state).

## Files affected

- `scripts/hooks/guard-model-tier.sh` — sentinel gate replaces promo branch
- `rules/model-tier-routing.md` — lanes table, ceiling, escape hatches, diagnostic
- `CLAUDE.md` — Tier-0 model-routing brief
- `features/model-tier-harness.md` — job-2 description

## Phases

Single-phase, landed 2026-07-23.

## Recovery

Re-arm: `trash ~/.claude/.allow-fable-subagents` (agents never touch it).
Full revert: restore the promo-era block from git history of this commit.

## Cross-references

- Mutation-tested at change time: sentinel present → fable dispatch allowed;
  sentinel absent → `decision:block`; warn path + telemetry unaffected.
- rules/model-tier-routing.md § sub-agent ceiling · features/model-tier-harness.md
