---
name: preference-graduation
description: Harvests recurring preference and vocabulary signals from the post-insight streams (atone, affirm, i-dream, runtime-notes, checkpoints), dedupes them against existing GLOSSARY and memory, and routes each fresh signal to its durable home (a glossary term, a global memory, or a rule) after per-signal confirmation.
argument-hint: "[--days N]"
user-invokable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

## Brief

Mines how-the-user-works signals out of the streams where they accrete implicitly (atone corrections, affirm good-calls, i-dream insights, runtime-notes, core-dump checkpoints) and promotes the real ones into the durable homes where future agents will actually load them. It is the preference-side sibling of `atone -> rules` and `proposals -> canon`: same promotion shape, different payload. The payload here is the user's working vocabulary and standing preferences, not a bug pattern.

This skill is the runnable form of the "manual pass" in `conventions/preference-graduation.md`, which stays the source of truth for the routing and the write-bar. It surfaces candidates with the existing `scripts/preference-harvest.sh`, then drives a human-confirmed routing of each fresh signal to its home.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md`. Apply all rules (forbidden paths, retry logic,
tool preferences, verbosity, timeouts, post-run insights, and the file lock protocol)
for the entire duration of this skill run before proceeding.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock hygiene: run `bash ~/.claude/skills/shared/lock-file.sh cleanup` once at skill start.
> Acquire a lock via `lock-file.sh acquire` before every Edit/Write and release it
> immediately after. Never write to `MEMORY.md`, GLOSSARY.md, a memory file, or a rule
> without holding its lock.

Then read the routing contract and where things go:
`~/.claude/conventions/preference-graduation.md` (source streams, routing table, write-bar),
`~/.claude/GLOSSARY.md` (term homes), `~/.claude/PLACEMENT.md` (where a graduated rule goes).

## Usage

```
/preference-graduation            harvest the last 30 days and triage
/preference-graduation --days 60  widen the look-back window
```

| Argument   | Type         | Meaning                                                       |
| ---------- | ------------ | ------------------------------------------------------------- |
| `--days N` | optional int | Look-back window passed through to the harvester (default 30) |

## Phase 1: Harvest candidates

Surface candidate signals; do not judge them yet. Run the existing harvester rather
than re-implementing the scan:

```bash
bash ~/.claude/scripts/preference-harvest.sh --days "${DAYS:-30}"
```

It prints the path of a dated candidate file under `~/.claude/topics/`. Read that file.
It scans atone corrections, affirm good-calls, recent i-dream insights, and recent
project runtime-notes for "how I work" language, and it explicitly flags already-baked
terms (efficacy, one-shotting, the work-routing triad) that will recur. If it reports
no candidates, say so and stop; an honest empty pass is a valid outcome.

## Phase 2: Dedupe against what is already durable

For each candidate, check whether it is already captured. Grep the existing homes before
proposing anything new (grep the full set, not one file):

```bash
rg -n -i "<keywords of the signal>" ~/.claude/GLOSSARY.md ~/.claude/memory/global
```

Drop candidates that already have a home. If a candidate refines an existing entry,
plan to update that entry rather than add a second one.

## Phase 3: Classify and route each fresh signal

Route by the table in `conventions/preference-graduation.md`:

| Signal kind                                      | Durable home                                          |
| ------------------------------------------------ | ----------------------------------------------------- |
| A word or shorthand the user adopts              | `GLOSSARY.md` (User Shorthand / Concepts)             |
| A standing preference ("I prefer X over Y")      | `memory/global/feedback_*.md` (+ `MEMORY.md` index)   |
| A who-the-user-is fact                           | `memory/global/user_*.md`                             |
| A how-Claude-MUST-work mandate, repeat-confirmed | `rules/*.md` (+ a CLAUDE.md brief per PLACEMENT.md)   |
| A project-scoped preference                      | that project's `.claude/` memory or rules, not global |

A promotion all the way to a `rules/*.md` mandate is the strongest claim and needs the
highest bar (see Phase 4). Most signals land in a memory or a glossary term.

## Phase 4: Confirm against the write-bar

Graduate a signal only when it is recurring or user-confirmed, the same bar as atone.
A single offhand remark goes in a memory at most; promotion to a rule requires repeat
occurrence or an explicit "bake this in". Over-baking pollutes the always-loaded budget
(see PLACEMENT.md): every promoted rule competes for the model's instruction-following
capacity, and a `rules/*.md` file is auto-loaded every session.

Present the routed candidates as one list with your recommended home and tier per item,
and get a per-signal yes/no. Do not batch-approve. Offer your own read on which signals
are real versus noise.

## Phase 5: Write, index, and cross-link

For each approved signal, holding the file lock:

1. Write or update the durable file (a `feedback_*` / `user_*` memory, a GLOSSARY row, or
   a rule sub-file with full frontmatter per PLACEMENT.md).
2. Update the index: add or update the `MEMORY.md` pointer line for a new memory, or the
   GLOSSARY table row for a new term.
3. If a rule was added, add its CLAUDE.md brief per PLACEMENT.md, and check the sub-200
   line ceiling first (`wc -l ~/.claude/CLAUDE.md`).
4. Cross-link related entries with `[[name]]` / `related:` on both ends.

## Phase 6: Verify

1. If a `rules/*.md` sub-file was added, run `bash ~/.claude/scripts/validate-triggers.sh`
   and read the pass/fail line.
2. Confirm each new `MEMORY.md` pointer resolves to a real file.
3. Render-check every written file (frontmatter closes, headings intact).
4. Print the GUIDELINES completion block, then the post-run insight entry.

## Notes

- **Relationship to the harvester.** `preference-harvest.sh` only surfaces candidates and
  never writes to GLOSSARY / memory / rules. This skill is the judgment layer that
  routes and writes. The harvester also runs on a schedule and drops a candidate file for
  later review; this skill can consume that file instead of re-running the scan.
- **Relationship to `/tag`.** `/tag` is the manual, point-at-one-thing path for filing a
  single item now. This skill is the batch pass over the streams. They share the same
  destination homes and the same PLACEMENT discipline.
- **Do not over-bake.** The default outcome for a weak signal is a memory, or nothing.
  Rules are for repeat-confirmed mandates only.
- Never commit or push. Graduation is a working-tree change; the user commits.
