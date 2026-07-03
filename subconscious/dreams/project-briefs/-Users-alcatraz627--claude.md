<!-- i-dream project brief · 2026-07-02T23:55:36.379214+00:00 · 20 patterns / 10 insights -->
## What this project is about
The `~/.claude` meta-configuration repo — managing Claude's own rules, skills, hooks, WAL, and tooling. Work is long-running, multi-session, and heavily continuity-dependent.

## Things to do (or keep doing)
- **Run `/core-dump` at milestones**, not just session end; `/catchup` is the primary recovery path after compaction
- **Treat terse single-word messages** (`ahead`, `next`, `looks`, `done`) as autonomous-continue directives — increase execution depth, never expand scope
- **Write WAL entries as JSONL** (`scripts/wal/wal.sh`); markdown format is legacy-only
- **Checkpoint every ~15 actions** and before any risky operation; state here is especially ephemeral across compaction boundaries

## Things to avoid
- **Never commit or push without fresh per-operation approval** — this has triggered angry corrections 5+ times; prior session approvals do not carry forward to subsequent push actions
- **Don't thrash on fixes** — if the same block has been edited 3+ times, stop, re-read, form a hypothesis, then edit once
- **Don't infer or synthesize data values** not explicitly traceable to source; flag any gap rather than fill it
- **Don't over-generalize terse continuation as push approval** — `keep going` means continue editing/analysis, not perform shared-state mutations

## Open questions / known gaps
- Structural tension: the terse-continuation protocol grants broad execution autonomy that the agent repeatedly over-generalizes past the commit/push boundary; advisory rules alone have not fixed this in 18+ sessions — a mechanical pre-push hook is the only class of fix that will hold
