---
name: roster-budget
description: Measures the skill roster against its listing budget and names the skills whose descriptions are being dropped, ranked by what each long description costs. Use when a skill stops auto-triggering, the roster shows bare names, or before adding or lengthening a description.
allowed-tools: Read, Bash, Glob, Grep
user-invocable: true
argument-hint: "[--top N] [--json]"
---

## Brief

Claude Code keeps every skill's name in context but, when the listing exceeds its
budget (1% of the context window by default), drops the descriptions of the
least-invoked skills first. A skill with no description cannot be routed to. This
skill shows the budget, who is over it, who is being dropped, and which long
descriptions are spending the most, so the fix is a specific edit rather than a
guess.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` §8 (the description budget; or the project's
`.claude/skills/GUIDELINES.md` when one exists) and the `## roster-budget:` entries in
`~/.claude/skills/runtime-notes.md`.

## Usage

```
/roster-budget              table: skill · description chars · skill-log runs · status (kept / dropped / over cap)
/roster-budget --top 10     only the ten longest descriptions
/roster-budget --json       machine output for a hook or a doctor row
```

## Phase 1: measure

1. Total description characters across `~/.claude/skills/*/SKILL.md` and the enabled
   plugins' skills (read each SKILL.md frontmatter; one line each).
2. The budget: `skillListingBudgetFraction` from `~/.claude/settings.json` (default
   0.01) times the session model's context window in characters; say which model
   and window you assumed.
3. Invocation counts per skill from `~/.claude/skills/usage/events.jsonl` (skill-log);
   a skill with no events counts as zero.
4. Which skills are dropped: sort by invocation count ascending and accumulate
   description lengths from the most-invoked down until the budget is spent; the
   rest are the dropped set.

## Phase 2: report

One table, longest description first: skill, chars, runs, status (kept / dropped /
over the 300 cap). `--top N` keeps the N longest rows; `--json` emits the same rows
as a JSON array plus a `summary` object (total, budget, dropped count) and nothing
else. Then two lines: the total versus the budget, and the three edits that would
bring the most skills back (shorten X, Y, Z by N chars each), with the recomputed
dropped set if those edits were applied. Say what is estimated (the context window,
the plugin set) in one line at the end.

## Boundaries

Read-only. It measures and recommends; it never edits another skill's SKILL.md or
`settings.json`. The edits it proposes are for the owner or `/improve-skill`.

## Validation

Efficacy dimension: does the report name the skills that are actually missing from
the live roster. Check 1: compare the computed dropped set against the skill listing
in the current session's system prompt (the names shown without descriptions); every
name in one set and not the other is a miss to explain. This check only bites when
the live roster is over budget; on a large-context session both sets may be empty,
which proves nothing, so say so rather than calling it a pass. Check 2: recompute the
dropped set with the three suggested edits applied on paper (subtract the proposed
characters, re-run the Phase 1 step 4 accumulation) and confirm it shrinks; no file
is touched.

## Runtime notes and ledger

Prepend a `## roster-budget:` entry via `bash ~/.claude/skills/shared/prepend-runtime-note.sh roster-budget <entry.md>`
when a run taught something. Then
`bash ~/.claude/scripts/skill-log.sh record roster-budget --task "…" --outcome unknown --corrections 0 --note "dropped=<n> over-cap=<n>"`.
