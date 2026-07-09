---
migration: 0027
title: Rules payload restructure — 3 merges + 5 sentinel-paths demotions
session: audit-gcc-7c@2026-07-09
status: complete
date: 2026-07-09
---

# Migration 0027 — Rules payload restructure (merges + autoload demotions)

## Why

The 2026-07-09 CLAUDE.md payload audit (`assets/reports/20260709-config-audits/claude-md.md`)
measured the always-on context cost at ~42.9k tokens, 83% of it from `rules/*.md`
autoload (34 files with no `paths:` block load in full every session). User approved
the audit's demotion + merge proposal, with one mitigation for the known
chicken-and-egg risk of on-demand rules (user had previously explored and rejected
on-demand loading because bare slugs give the agent an "I didn't know what it meant"
excuse): every demoted rule's `brief:` was rewritten to carry the directive itself,
so the always-on `00-index.md` line is actionable without opening the file. A
2-week follow-up check is scheduled to confirm no detrimental effect.

## What changes

| From | To | Why |
|---|---|---|
| `rules/cron-calendar-companion.md` | merged into `rules/scheduling-discipline.md` § "Every cron gets a companion calendar event"; file retired | Same topic, always co-triggered; saves frontmatter + restated contract |
| `rules/performative-self-criticism.md`, `rules/prescribed-flattery-as-fix-for-pushback.md`, `rules/pushback-honesty.md` | merged into new `rules/pushback-and-self-criticism.md` (stays always-on) | Three faces of one disagreement doctrine, each cross-referencing the others |
| `rules/subagent-model-ceiling.md` | folded into `rules/model-tier-routing.md` § "The sub-agent ceiling"; file retired | Routing rule was written to supersede it and restated its core claim |
| 5 rules always-on | sentinel `paths:` demotion (index-disclosed): `sub-agent-outputs`, `proposed-fix-breaks-design-invariant`, `cache-externally-mutated-state`, `skill-spec-update-not-honored-by-running-session`, `scheduling-discipline` (merged) | 80%-skip cases with bounded, recoverable failure modes; sub-agent-outputs additionally has a mechanical PreToolUse guard hook |

Cross-references updated: `LOOKUP.md`, `NAMESPACE.md` (§ std::claude::schedule),
`conventions/preference-graduation.md`, `scripts/schedule/INSTRUCTIONS.md`,
`scripts/schedule/schedule.sh` (live copy only; .bak snapshots untouched),
`scripts/hooks/guard-model-tier.sh`, `rules/audience-aware-writing.md`,
`rules/right-sized-code.md`, `skills/ui-gripe/SKILL.md`,
`memory/global/feedback_subagent_model_never_fable.md`, and the auto-memory
`feedback_cron-calendar-companion.md`. `rules/00-index.md` regenerated (34 rules).

## What does NOT change

- **Atone/affirm slugs** (`prescribed-flattery-as-fix-for-pushback`,
  `performative-self-criticism`, etc.) — event history keys are permanent; the merged
  file names them so greps still connect.
- **`trusted-linter-reminder.md` and `ambiguous-file-action-halt.md`** stay always-on
  (silent-failure / irreversible-overwrite class) — explicitly excluded from demotion.
- **`helper-return-type-assumption.md`** stays always-on (re-confirmed the 2026-07-05
  rejection: no clean glob captures "code that chains a method on a helper return").
- Migration docs and `.bak` files referencing retired filenames — point-in-time
  records, intentionally untouched.
- CLAUDE.md itself — 193 lines, structure unchanged (the audit found it correctly
  tiered; the budget lever was `rules/`).

## Verification

- [x] `bash scripts/rules-index.sh` — regenerated, 34 rules, retired files absent,
      merged/demoted rows correct (`scoped` for the 5, `always` for the merged doctrine)
- [x] `bash scripts/validate-triggers.sh` — 0 errors (26 pre-existing cross-file topic warnings)
- [x] `bash -n scripts/schedule/schedule.sh scripts/hooks/guard-model-tier.sh` + `schedule.sh --help` runs
- [x] Payload re-measured: always-on `rules/` 106,561 chars (~26.6k tok) + CLAUDE.md
      28,582 chars (~7.1k tok) = ~33.8k tokens, down from ~42.9k (−21%)
- [x] `rg` for retired filenames across live surfaces returns only historical records
      (migrations, .bak, transcripts/archives)
- [ ] 2-week efficacy check (gcc-schedule one-shot `rules-demotion-check`, ~2026-07-23):
      any atone events whose pattern a demoted rule would have prevented? Any missed
      calendar companions / unpersisted sub-agent outputs / stale-cache slips?

## Rollback

```bash
cd ~/.claude
git checkout HEAD -- rules/ LOOKUP.md NAMESPACE.md conventions/preference-graduation.md \
  scripts/schedule/INSTRUCTIONS.md scripts/schedule/schedule.sh scripts/hooks/guard-model-tier.sh \
  skills/ui-gripe/SKILL.md memory/global/feedback_subagent_model_never_fable.md
# The merged doctrine file is UNTRACKED — git checkout won't remove it, and leaving
# it would duplicate the restored triad in the index (4 pushback-family rules):
trash rules/pushback-and-self-criticism.md
bash scripts/rules-index.sh
```

(Or selectively: restore a retired file from git and delete a demoted rule's `paths:`
block, then re-run `rules-index.sh`.) Rollback triggers: the 2-week check finds a
recurrence pattern attributable to a demoted rule not being in context, or the user
reports the index-line briefs are not carrying enough directive to act on.

## Notes / followups

- Filed alongside: proposal to build a companion hook for `trusted-linter-reminder`
  (detect the harness's "modified by linter" reminder → inject the rule pointer),
  after which that rule too can demote.
- Optional future: split `shell.md`'s rg/fd/yq cheatsheet to a Tier-2 features doc
  (~800-1,000 more tokens); deliberately not done in this pass.
