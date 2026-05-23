# `~/.claude/rules/` — Behavioral rules

> Rules govern **what Claude MUST do**. They are mandates, not how-to docs.

## When to write here

- A process rule with measurable adherence (commit cadence, testing scale, shell safety)
- A hard guardrail with a known failure mode (never push main without approval)
- A correction graduated from `~/.claude/atone/events.jsonl` after recurrence

## When NOT to write here

- How a script or subsystem works → `~/.claude/features/`
- How an output should look / be formatted → `~/.claude/conventions/`
- A one-off preference for a project → that project's local `.claude/rules/`

## File shape

Each `*.md` carries YAML frontmatter (`brief`, `triggers:`, `related`, `tier`, `category`, `updated`, `stale_after_days`). Validate with `bash ~/.claude/scripts/validate-triggers.sh`.

Body structure (per `rules/comments.md` rubric): code-agnostic purpose → contract → caveats. Keep <8 lines per docstring; link out for depth.

## Promotion / demotion

Rules live or die by adherence. Tier-0 inline in CLAUDE.md, Tier-1 brief+pointer, Tier-2 pointer-only, Tier-3 LOOKUP.md-only. See `PLACEMENT.md` for the heuristic (80%-skip test, silent-failure bump).

## See also

- `PLACEMENT.md` — where new rules go
- `rules/corrections.md` — graduation path from atone to a rule
- `features/proposals.md` — backlog of rule candidates
