# 0048: skills-parked/ as a new top level, the callout ledger, and the coverage instruments

**Date:** 2026-08-20
**Type:** structural (new top-level dirs, 11 skills moved out of the roster)
**Sessions:** valid-docx-7a

## What changed

1. **`~/.claude/skills-parked/`** (new top level): 11 skills moved out of
   `skills/` per the owner's 2026-08-20 rulings — apple, type-audit, route-audit,
   invalidate-audit, sync-api-types, add-mcp, clean-html, scaffold, dep-audit,
   daily-todo, forgotten-todos. Kept, not loaded: no roster cost, no auto-trigger.
   `README.md` + generated `INDEX.md` (tldr/tags/activation) + `tags.tsv` +
   `friction.jsonl` (the twice-counter). Surface: `scripts/parked/parked.sh`
   (index / list / match / copy / friction). SessionStart nudge:
   `scripts/hooks/parked-skills-nudge.sh` (registered; runs the owner's two-way
   check in non-gcc projects; mute `.no-parked-nudge`).
2. **Callout ledger**: `scripts/callouts/callouts.sh` writes
   `<project>/.claude/callouts.jsonl` (gcc: `~/.claude/callouts.jsonl`) — owner
   review findings as re-runnable rows; `gate <surface>` blocks done-claims with
   unmet rows; only `retire --by owner` closes a row. Skill `/callouts`;
   /validate Vf and the ui-gripe / ui-categorical-check feeders reference it.
3. **Prototypes** (`metadata.maturity: prototype`): `/intake`, `/probe`, plus
   `/callouts` above.
4. **`scripts/seat/seat.sh`** + `roles/` (intent-review, second-seat,
   claim-tracing): the standard fresh-context reviewer prompt builder + verdict
   check; /validate and /create-skill now dispatch through it.
5. **GUIDELINES §Output**: the 🏁 done box gains a mandatory
   `covered … skipped …` row (activation self-report, owner ruling 2026-08-20).

## Why

Owner rulings on the coverage map (`assets/reports/20260820-skills-eval/`):
review-loop persistence is their #1 pain; activation beats building; parked
skills stay reachable through awareness plus a proactive twice-trigger.

## Readers to update if you find one

A reference to `skills/<name>/` for any of the 11 moved names now points at
`skills-parked/<name>/`. `skills/00-index.md` regenerates clean; the one
load-bearing reader found (core-dump's See Also) was updated in this change.
