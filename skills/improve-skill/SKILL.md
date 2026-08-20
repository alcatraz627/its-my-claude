---
name: improve-skill
description: Audits skills against the house rules and their run history (runtime notes incl. archives, skill-log outcomes, their own Validation rubric), applies approved fixes, and reports efficacy per the skill's rubric, not a score. Use when a skill misfires, feels stale, or before relying on one.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent
user-invocable: true
argument-hint: "[skill-name | a,b,c | all] [--eval] [--focus \"...\"]"
---

## Brief

`/improve-skill` is the meta-auditor: it reads what a skill says, what happened when
it ran, and what the house requires, then closes the gaps with the owner's approval.
Efficacy is judged the way the owner ruled on 2026-08-19: per skill, against the
skill's own `## Validation` rubric (context retention for a checkpoint skill, prose
and structure for a writing skill, useful ratio for a review skill), never a generic
score. Measuring something that does not matter to the output is worse than not
measuring. This skill holds itself to the same rubric it applies.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` (§8 and the Authoring Conventions). Read the
`## improve-skill:` entries: `rg -n "^## improve-skill" ~/.claude/skills/runtime-notes*.md`.
The consumption rules this skill applies live in
`~/.claude/assets/reports/20260618-persona-dogfood/claude-consumption-spec.md`; they
were written against Opus 4.6/4.8 and have held on later models, so read them as
house rules and say so if one stops holding.

## Usage

```
/improve-skill <name>             one skill
/improve-skill a,b,c              several, in sequence
/improve-skill all                every ~/.claude/skills/*/SKILL.md (in a project: its .claude/skills too)
/improve-skill <name> --eval      also run the skill's Validation checks and a trigger eval (costs tokens; say so first)
/improve-skill <name> --focus "…" one concern to weight first ("it never reads the notes", "the description")
```

Resolve each target to an absolute path (`~/.claude/skills/<name>/SKILL.md`, or the
project's `.claude/skills/<name>/SKILL.md` when in a project); a missing one prints
`✗ <name> not found` and is skipped.

## Phase 1: gather, per skill

1. **The skill.** Read SKILL.md in full; list companion files (`*.sh`, `*.py`, `*.ts`,
   `references/`) and read the ones the workflow calls.
2. **Mechanical findings.** `python3 ~/.claude/scripts/skill-lint.py <path>`: field
   names, the caps (description 300, argument-hint 120, Brief 8 lines, emphasis), the
   `Task` tool name, CWD-relative skill writes, a missing `## Validation` rubric or
   skill-log step. Body length is never a finding.
3. **Run history.** `rg -n "^## <name>" ~/.claude/skills/runtime-notes*.md` (the
   archives hold most of it; the live file rotates quarterly), then
   `bash ~/.claude/scripts/skill-log.sh summary --skill <name>` and
   `bash ~/.claude/scripts/ledger/ledger.sh list --src skills --limit 20 | rg <name>`.
   No history is itself a finding: check whether the skill has a step that writes it
   before concluding it never ran.
4. **Its rubric.** The skill's `## Validation` section: the efficacy dimension and its
   checks. If absent, draft one in Phase 2 from the skill's class (table below) and
   propose it.
5. **Its routing.** Description length and shape (verb + input + output + "Use when");
   whether the roster is dropping it (`rg -n "<name>" ~/.claude/skills/00-index.md`
   and, when `--eval`, the trigger eval in Phase 4).

## Phase 2: analyse, nothing written yet

Two lenses, recorded as pass / partial / fail with one line each:

**House rules (Claude-consumption).** Emphasis reserved for two or three load-bearing
gates; procedure over flavour; canonical examples and heuristics over exhaustive
enumeration; for review skills, coverage-first reporting (rank, never drop);
`rg` not `grep` in runtime steps; no gum/TTY output under `context: fork`; cross-links
to the subsystems the skill's domain leans on (build and fix skills to
`/skeptical-review` and exercise-based verification; review skills to `/magi` and
`/arch-qa`; doc skills to `conventions/doc-writing.md`; research skills to
`/deep-research`).

**Structure (GUIDELINES).** Brief after frontmatter; Step 0 reading GUIDELINES and
its runtime notes; gather → plan → do → check phases in whatever order the work
needs; `## Validation` rubric; runtime-note and skill-log steps; absolute paths.

**Run history, classified.** Each runtime-note insight and each skill-log residue is
one of: already handled · missing instruction · wrong instruction · informational.
Repeated `corrections > 0` or `outcome: revised` on the same phase is a wrong or
missing instruction until shown otherwise.

**The rubric, judged.** Does the `## Validation` dimension match what this skill is
for, and can an agent run its checks with the skill's own tools? The classes:

| skill class | efficacy dimension | the kind of check |
|---|---|---|
| retention (core-dump, catchup, workspace) | context and attention survive `/clear` | what a resumed agent gets wrong without the artifact vs with it |
| writing (word-doc, deck, pr-description, write-docs) | prose and structure of the output | the output's lint gate, the reader's first read, rework asked for |
| review and debugging (skeptical-review, ui-gripe, dep-audit) | useful-to-noise ratio of findings | findings acted on / findings reported, over the last N runs |
| routing (pick-skill, plan, validate, ui) | the right instrument chosen | routed-to skill's outcome, and the trigger eval |
| generation (create-skill, scaffold, readme) | output accepted without rework | skill-log `outcome` and `corrections` on first use |
| measurement (roster-budget, session-stats) | the number is right and interpretable | a known case recomputed by hand |

Then print the analysis block for the skill:

```
── <name> ────────────────────────────────────────────
  lint         <n errors, n warnings | clean>
  description  <ok | too long (n) | does not route: why>
  structure    <gaps, or none>
  house rules  <defects, or none>
  run history  <n notes, n skill-log runs; n missing, n wrong, n handled>
  rubric       <present and fit | present but <what is wrong> | missing; proposed: <dimension>>
  proposed
    1. <title>  <one-line why>
    2. …
──────────────────────────────────────────────────────
```

Then one plain question, numbered, in the conversation (never a dialog tool; the
owner's fullscreen TUI cannot show one): `1 apply all · 2 apply some (say which) ·
3 skip this skill`. A terse continuation means 1. Add `--focus` items first in the
list when given.

## Phase 3: apply

For each approved change: `Edit` for a section, `Write` only for a structural
rewrite. Companion code changes only when a runtime note names the bug and the fix
is unambiguous; anything needing design judgement is listed for the owner instead.
When the description changes, keep it under 300 characters. When a `## Validation`
rubric is added, write it against the skill's class and its own tools, as a rubric
(what to check, how, what a pass is), never worked examples.

Then, per skill:

```bash
python3 ~/.claude/scripts/skill-lint.py <path>        # no errors left; warnings named in the summary
npx prettier --write <path>                            # if available
bash ~/.claude/scripts/skills-index.sh                 # gcc skills (the write hook also does this)
```

## Phase 4: efficacy, per the skill's rubric

Default (no `--eval`): read, do not run. Report each rubric check with the evidence
already on disk (skill-log outcomes and corrections, runtime notes, the lint), as
`pass / fail / unrunnable without --eval`, one line each, with the interpretation in
plain words. No number is produced; a count of passes would be the score the owner
retired.

With `--eval` (say the token cost first; one `claude -p` run per query):

1. Run the rubric checks that can be run now (the skill's own gate on a fixture, a
   recompute of a known case, a read of the last N outputs).
2. Trigger eval for routing: write six to ten queries (half should trigger, half
   should not) to a file and run
   `python3 ~/.claude/scripts/skill-trigger-eval.py <name> --queries <file> --model sonnet`.
   Misses name what the description must say or stop saying.
3. For output-quality rubrics where it matters (a writing or generation skill the
   owner relies on), a with/without comparison: the same prompt once with the skill
   invoked and once without, the two outputs read side by side against the rubric by
   a fresh seat (sonnet, read-only, findings written to disk). This is the useful
   half of the retired plugin's loop; it is a procedure, not a script, and it is
   opt-in because it costs two full runs.

A check that the rubric names but nothing can run is reported as unrunnable and
becomes a proposed rubric fix, not a pass.

## Phase 5: verify, record, report

1. Read each edited SKILL.md back: the change landed, the lint is clean, the
   description is under the cap.
2. `bash ~/.claude/scripts/skill-log.sh record improve-skill --task "<names>" --outcome unknown --corrections 0 --note "changes=<n> rubric=<added|fit|fixed> eval=<none|ran: …>"`.
3. Runtime note per GUIDELINES §7 when the run taught something (a rubric that did
   not fit, a run-history pattern).
4. Final summary, one block per skill: files changed, the efficacy lines from Phase
   4, anything left for the owner (a companion-code fix needing judgement, an
   unrunnable check).

## Validation

Efficacy dimension: the audited skill gets better at what it is for, and the owner
keeps the changes. Checks: (1) skill-log `outcome` and `corrections` for the audited
skill over its next three runs, compared with the three before; (2) the audited
skill's `## Validation` checks are runnable with its own tools (a seat that did not
write them can run one); (3) this skill's own runs land in skill-log with
`outcome: accepted` more often than `revised`.

## Runtime notes and ledger

Prepend a `## improve-skill:` entry with
`bash ~/.claude/skills/shared/prepend-runtime-note.sh improve-skill <entry.md>` when
a run taught something. The `skill-log.sh record improve-skill` line in Phase 5 is
mandatory.

## See also

- `~/.claude/assets/reports/20260618-persona-dogfood/claude-consumption-spec.md`, the house rules Phase 2 applies, and `subsystem-inventory.md` beside it for the cross-link map
- `/create-skill` writes skills in the shape this skill audits; `/create-agent` the agent variant
- `~/.claude/scripts/skill-lint.py`, `skill-trigger-eval.py`, `skill-log.sh`, `ledger/ledger.sh`
- `rules/skill-spec-update-not-honored-by-running-session.md`: a mandate added to a SKILL.md binds only future sessions; add a data-path gate when it must bind now
