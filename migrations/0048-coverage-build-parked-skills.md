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

## Amendment 2026-08-20 — skills-parked/ is tracked

This migration created a new top level and did not say whether git should track
it. `.gitignore` runs an allowlist (`/*`, then un-ignore the config/code layer),
so silence meant ignored, and git could see the source of the move but not its
destination. The next `git add -A` would therefore have recorded the move as 428
bare deletions: the skills stay on this disk and leave the repo and every clone.

The bi-weekly repo-sync caught it before pushing, held the deletions back, and
put it to the owner, who ruled **track it** — consistent with "Kept, not loaded"
above, which is about roster cost rather than about what the repo keeps.
`!/skills-parked/` is now in `.gitignore` (431 files, 5.4M).

Two things worth carrying forward:

- A new top-level dir under an allowlist is invisible by default. Creating one
  is a tracking decision even when it doesn't feel like one, so state the answer
  in the migration that creates it.
- `COMMIT.md` step 1 scans with `rg` from the repo root, and `rg` honours
  `.gitignore`. A previously-ignored dir that becomes tracked is therefore
  brand-new bytes the standard scan never read. Scan such a dir explicitly with
  `--no-ignore` before the commit that starts tracking it. Done here: 431 files
  read, clean.
