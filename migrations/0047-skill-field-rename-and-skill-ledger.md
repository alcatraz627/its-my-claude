# 0047: `user-invocable` spelling, skill-lint gate, skills stream joins the ledger family

**Date:** 2026-08-19
**Type:** rename (a frontmatter field other files reference) + new hook + ledger registration
**Sessions:** valid-docx-7a

## What changed

1. **Field rename.** Every `user-invokable:` in `skills/*/SKILL.md` (84 files incl.
   `create-report/table`), `skills/GUIDELINES.md`, `skills/README.md`,
   `features/codex-adapter.md` and `scripts/skills-index.sh` is now
   `user-invocable:`, the spelling Claude Code reads (docs frontmatter reference,
   confirmed 2026-08-19). The old spelling was a silent no-op; every instance was
   `true`, the default, so nothing changed at runtime. A project-local skill written
   by the old `/create-skill` template still carries the old spelling; the new
   `scripts/skill-lint.py` flags it as `misspelled-field`.
2. **Skill lint + hook.** `scripts/skill-lint.py` (field list, description cap 300,
   argument-hint cap 120, Brief cap 8 lines, `Task` tool name, CWD-relative skill
   writes, missing `## Validation` rubric, missing skill-log step, emphasis count;
   body length is never judged). `scripts/hooks/skill-lint-nudge.sh` runs it on every
   PostToolUse Edit|Write|MultiEdit of a `*/skills/*/SKILL.md`, warn tier, and
   regenerates `skills/00-index.md` for gcc skills. Registered in `settings.json`.
   Mute: `touch ~/.claude/.no-skill-lint-gate`. Tests: `scripts/hooks/skill-lint-nudge.test.sh`.
3. **Ledger family.** `skills/usage/events.jsonl` (written by `scripts/skill-log.sh`)
   is registered in `scripts/ledger/ledger.sh` `_streams` as domain `skills`
   (classifier `skill/outcome`, summary `task`). `skill-log.sh` and
   `scripts/persona-log.sh` now append through `ledger-common.sh`
   (`ledger_ts`, `ledger_append`); id shapes (`skl-`, `puse-`) and event shapes are
   unchanged. The lock path moved from `<events>.lock` (dir) to `<events>.lock.d`
   (ledger-common's); no migration of data.
4. `settings.json`: `skillListingBudgetFraction: 0.02` (the roster was dropping 24
   skill descriptions at the 1% default).

## Why

Owner rulings D2a, D4a, D5a, D6a on the meta-skills plan
(`assets/reports/20260819-meta-skills-validate/PLAN.md` §Rulings).

## Readers to update if you find one

`rg -n "user-invokable" ~/.claude --glob '!projects/**' --glob '!file-history/**'`
should return only archives and logs. Any hit in a live file is a stale reader.
