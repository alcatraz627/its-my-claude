---
name: improve-skill
description: A skill misfires, feels stale, or needs checking before use. Audits it against house rules, run history, sibling skills and owner rulings, then applies approved fixes. Not for writing a new skill.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent
user-invocable: true
argument-hint: "[skill-name | a,b,c | all] [--eval] [--focus \"...\"]"
---

## Brief

`/improve-skill` is the meta-auditor: it reads what a skill says, what happened when
it ran, what its neighbours and the owner's rulings say about it, and what the house
requires, then closes the gaps with the owner's approval. Efficacy is judged per
skill, against the skill's own `## Validation` rubric, never a generic score, and
never on outcomes the skill graded itself. The history it trusts most is the repeated
residue in the run notes: the same defect written down three or more times. This skill
holds itself to the same rubric it applies.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` (§8 and the Authoring Conventions). Read this
skill's own history: its `## improve-skill:` entries in the global notes
(`rg -n "^## improve-skill" ~/.claude/skills/runtime-notes.md`, then the same pattern
over `~/.claude/skills/runtime-notes-archive*.md` if present) and
`~/.claude/skills/improve-skill/runtime-notes.md` if it exists.
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

One command per Bash call, no chaining or pipes; ask a tool for less output instead
(`rg -m 20`, `--limit 20`).

1. **The skill.** Read SKILL.md in full; list companion files (`*.sh`, `*.py`, `*.ts`,
   `references/`) and read the ones the workflow calls.
2. **Mechanical findings.** `python3 ~/.claude/scripts/skill-lint.py <path>`: field
   names, the caps (description 300, argument-hint 120, Brief 8 lines, emphasis), the
   `Task` tool name, CWD-relative skill writes, a missing `## Validation` rubric or
   skill-log step. Body length is never a finding.
3. **Run history.** Three sources, all read:
   - The skill's own notes: `~/.claude/skills/<name>/runtime-notes.md` when it exists
     (some skills keep their notes here and never write the global file; bloop has 50+
     entries there). Read it, do not search around it.
   - The global notes: `rg -n "^## <name>" ~/.claude/skills/runtime-notes.md`, then the
     same pattern over `~/.claude/skills/runtime-notes-archive*.md` (the live file
     rotates quarterly).
   - The ledger: `bash ~/.claude/scripts/skill-log.sh summary --skill <name>` and
     `bash ~/.claude/scripts/skill-log.sh list --skill <name> --limit 20`.

   **Mine repeated residue.** Write down each distinct defect an entry names (a
   validator that went idle until chased, a step skipped, a flag misread) with the
   entry date and line. A defect that appears in three or more separate entries is
   residue, not an anecdote; confirm the count with one `rg -c` on its key phrase over
   the notes file. Residue is a missing or wrong instruction until shown otherwise,
   and it outranks any lint finding in the proposed list.

   **Discount self-graded outcomes.** If the skill's own text tells the agent to record
   `--outcome accepted` (or any outcome) at its own finish, then those rows are the
   skill grading itself, and the owner never weighed in. Count them separately and say
   so in the analysis: "71 of 79 accepted rows are self-graded, so they say nothing
   about efficacy". Owner evidence is `revised`, `discarded`, nonzero `corrections`,
   a later note that records a rework, and the owner's own words in the notes.
   `unknown` is no evidence either way. With no owner evidence, the efficacy reading
   is "unmeasured", never "healthy".

   No history at all is itself a finding: check whether the skill has a step that
   writes it before concluding it never ran.
4. **Its rubric.** The skill's `## Validation` section: the efficacy dimension and its
   checks. If absent, draft one in Phase 2 from the skill's class (table below) and
   propose it.
5. **Its routing.** Description length and shape (verb + input + output + "Use when");
   whether the roster is dropping it (`rg -n "<name>" ~/.claude/skills/00-index.md`
   and, when `--eval`, the trigger eval in Phase 4).
6. **Its neighbours and rulings** (feeds the contradiction lens in Phase 2):
   - Skills that route to it or that it routes to:
     `rg -n -w "<name>" ~/.claude/skills --glob SKILL.md`, plus every `/other-skill`
     named inside the target's own SKILL.md. Read the lines around each mention.
   - Owner rulings that bear on it: scan `~/.claude/rules/00-index.md`, read the
     rules the skill's domain touches, and read `~/.claude/style/sweep/*/rulings.md`
     for the newest sweeps plus any whose text matches the skill's name or domain
     (`rg -l -i "<name>|<domain word>" ~/.claude/style/sweep --glob rulings.md`).
   - References it makes: every path (`~/.claude/...`, `scripts/...`), skill name
     (`/x`, `x:y`) and script it names.

## Phase 2: analyse, nothing written yet

Four lenses, recorded as pass / partial / fail with one line each:

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

**Contradictions.** Each is a finding with both sides quoted and a file:line for each.
- *Siblings.* For every skill that names the target, or that the target names: do the
  two agree on who owns the step, in what order, and who asks the owner? A loop is a
  contradiction (A defers to B, B defers back to A). A claim about a neighbour ("X no
  longer calls Y") needs a read of X before it passes.
- *Rulings.* Does any instruction break a rule in `~/.claude/rules/` or a ruling in a
  sweep's `rulings.md`? Typical breaks: a command chained with `&&`, `;` or a pipe; a
  decision set asked one prompt at a time; arming a goal in the agent's name; a dump
  or publish nobody asked for; a retired ban or memory still cited as live. A ruling
  newer than the skill's last edit wins.
- *Dead references.* Every path must exist (`test -e` or Read), every `/skill` name
  must have `~/.claude/skills/<name>/SKILL.md`, every script must run `--help`. Skill
  names written `router:<x>` are dead unless this session's skill list shows them:
  the Skill tool has failed on them in recorded runs.

**Run history, classified.** Each runtime-note insight and each owner-evidence
skill-log residue is one of: already handled · missing instruction · wrong
instruction · informational. Repeated residue (Phase 1.3) and repeated `corrections > 0`
or `outcome: revised` on the same phase are a wrong or missing instruction until shown
otherwise.

**The rubric, judged.** Does the `## Validation` dimension match what this skill is
for, and can an agent run its checks with the skill's own tools? The classes:

| skill class | efficacy dimension | the kind of check |
|---|---|---|
| retention (core-dump, catchup, workspace) | context and attention survive `/clear` | what a resumed agent gets wrong without the artifact vs with it |
| writing (word-doc, deck, pr-description, write-docs) | prose and structure of the output | the output's lint gate, the reader's first read, rework asked for |
| review and debugging (skeptical-review, ui-gripe, dep-audit) | useful-to-noise ratio of findings | findings acted on / findings reported, over the last N runs |
| routing (pick-skill, plan, validate, ui) | the right instrument chosen | routed-to skill's outcome, and the trigger eval |
| generation (create-skill, scaffold, readme) | output accepted without rework | skill-log `outcome` and `corrections` on first use |
| driving (bloop, deadline, a queue runner) | the work finishes without the owner chasing it | owner nudges in the run notes, residue repeated across runs, gate failures that reached the owner |
| measurement (roster-budget, session-stats) | the number is right and interpretable | a known case recomputed by hand |

Then print the analysis block for the skill:

```
── <name> ────────────────────────────────────────────
  lint            <n errors, n warnings | clean>
  description     <ok | too long (n) | does not route: why>
  structure       <gaps, or none>
  house rules     <defects, or none>
  contradictions  <n siblings, n rulings, n dead refs, or none>
  run history     <n notes (own file + global), n skill-log runs (n self-graded); n repeated residue, n missing, n wrong, n handled>
  rubric          <present and fit | present but <what is wrong> | missing; proposed: <dimension>>
  proposed
    1. <title>  <one-line why>
    2. …
──────────────────────────────────────────────────────
```

Print one block per skill, then ask the owner once for the whole run.

**Ask once, not once per skill.** Every proposed change across every audited skill
goes on ONE decision page through `/decision-wizard` (Path B): a card per proposed
change, grouped by skill, options apply or skip, one drafted `rec` each (apply, for
the ones you hold a confident pick for; say which in the page intro). `--focus` items
lead the list. For `all`, that is one page for the run, never ninety prompts. A run
with three or fewer simple proposals may use the inline numbered menu in `/decision-wizard`
Path A instead; a terse continuation means apply all.

## Phase 3: apply

For each approved change: `Edit` for a section, `Write` only for a structural
rewrite. Companion code changes only when a runtime note names the bug and the fix
is unambiguous; anything needing design judgement is listed for the owner instead.
When the description changes, keep it under 300 characters. When a `## Validation`
rubric is added, write it against the skill's class and its own tools, as a rubric
(what to check, how, what a pass is), never worked examples.

Then, per skill, each as its own Bash call:

```bash
python3 ~/.claude/scripts/skill-lint.py <path>        # no errors left; warnings named in the summary
npx prettier --write <path>                            # if available
bash ~/.claude/scripts/skills-index.sh                 # gcc skills (the write hook also does this)
```

## Phase 4: efficacy, per the skill's rubric

Default (no `--eval`): read, do not run. Report each rubric check with the evidence
already on disk (owner-graded skill-log outcomes and corrections, runtime notes, the
lint), as `pass / fail / unrunnable without --eval / unmeasured`, one line each, with
the interpretation in plain words. Self-graded rows are named and excluded. No number
is produced; a count of passes would be the score the owner retired.

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
2. Record one run line. The outcome is the owner's verdict on this run's proposals,
   read from their answer on the decision page or menu: every proposal applied as
   drafted is `accepted`, any flipped or partly applied is `revised`, everything
   skipped is `discarded`. Use `unknown` only when no answer came back (a run the
   owner never saw). Never grade the run yourself.
   `bash ~/.claude/scripts/skill-log.sh record improve-skill --task "<names>" --outcome <accepted|revised|discarded|unknown> --corrections <n flips> --note "changes=<n> rubric=<added|fit|fixed> eval=<none|ran: …> flips=<which proposals the owner flipped>"`.
3. Runtime note per GUIDELINES §7 when the run taught something (a rubric that did
   not fit, a run-history pattern).
4. Final summary, one block per skill: files changed, the efficacy lines from Phase
   4, anything left for the owner (a companion-code fix needing judgement, an
   unrunnable check).

## Validation

Efficacy dimension: the audited skill gets better at what it is for, and the owner
keeps the changes. Checks: (1) owner-graded evidence for the audited skill (`revised`,
`discarded`, `corrections`, rework notes) over its next three runs, compared with the
three before; self-graded `accepted` rows do not count, and with no owner evidence the
reading is "unmeasured"; (2) the audited skill's `## Validation` checks are runnable
with its own tools (a seat that did not write them can run one); (3) this skill's own
runs in skill-log carry the owner's verdict from Phase 5, so the ratio of `accepted`
to `revised` is readable, and each `revised` run's `flips=` note says what the owner
disagreed with; (4) a run that proposed a repeated-residue fix names the entries it
came from, so the owner can check the count.

## Runtime notes and ledger

Prepend a `## improve-skill:` entry with
`bash ~/.claude/skills/shared/prepend-runtime-note.sh improve-skill <entry.md>` when
a run taught something. The `skill-log.sh record improve-skill` line in Phase 5 is
mandatory.

## See also

- `~/.claude/assets/reports/20260618-persona-dogfood/claude-consumption-spec.md`, the house rules Phase 2 applies, and `subsystem-inventory.md` beside it for the cross-link map
- `/create-skill` writes skills in the shape this skill audits; `/create-agent` the agent variant
- `/decision-wizard`, where every owner decision of a run goes on one page
- `~/.claude/scripts/skill-lint.py`, `skill-trigger-eval.py`, `skill-log.sh`
- `rules/skill-spec-update-not-honored-by-running-session.md`: a mandate added to a SKILL.md binds only future sessions; add a data-path gate when it must bind now
