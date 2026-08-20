---
name: intake
description: Models a request before work starts, restating it as goal, scope ceiling, register, and what the wording exemplifies versus specifies, with one line back when readings diverge. Use before non-trivial work, when a request names one instance of a possible class, or when the last answer missed.
allowed-tools: Read, Grep, Glob, Bash
user-invocable: true
argument-hint: "[the request, or nothing to take the last owner message]"
metadata:
  maturity: prototype
---

## Brief

The account's largest mistake cluster is acting on the words instead of the goal
(literal-request-over-intent, 17x; dense-briefing, 11x). This skill is the pause
that prevents it: four questions answered in a fixed order before the first tool
call of real work. It generalizes the intent seat that /create-skill runs on drafts
to any request. It is a checklist, not a conversation; most runs end in six lines
and no question to the owner.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` and the `## intake:` entries in
`~/.claude/skills/runtime-notes.md`. The seven literal-request shapes live in
`~/.claude/rules/literal-request-over-intent.md`; scan the tells, not the essays.

## The four questions, in order

1. **Goal.** One sentence: what changes in the world when this is done, in the
   owner's terms, not the artifact's. If the request is a complaint, the goal is a
   diagnosis and fix, never a menu of options.
2. **Sample or spec.** For each named string, instance, or example: does it stand
   for a class? Name the class you will serve. The escape hatch is theirs, not
   yours: "exactly this" or a repeat after pushback makes the literal binding.
3. **Scope ceiling.** What the request does NOT authorize: adjacent improvements,
   infra, rebuilds of things that work. One line. The ceiling holds even when the
   goal reading is wide.
4. **Register.** What shape the answer should take: a one-line answer, a table, a
   built thing, a document. A two-line question gets a two-line answer; a briefing
   is a choice the owner makes, not a default. Check the ask for tokens a stranger
   could not resolve and gloss them.

Then, exactly one of:

- **Readings converge**: state the four answers in at most six lines and start.
- **Readings diverge materially** (different work products, not different
  phrasings): one line naming both readings and the one you will take unless
  redirected. Keep working on everything the divergence does not touch.

## When a seat is worth it

For a large or hard-to-reverse piece of work, dispatch one fresh seat (sonnet, low,
read-only, no sub-agents, writes its verdict to a file before returning) with the
owner's verbatim words and your four answers, asking only: which answer misreads
the words? Use `bash ~/.claude/scripts/seat/seat.sh prompt --role intent-review ...`
to build the dispatch. Most runs do not need it.

## Boundaries

Never widen scope because the goal reading is generous. Never ask the owner a
question the transcript already answers. Never run this on trivial requests; a
rename does not need an intake.

## Validation

Efficacy dimension: the literal-request and dense-briefing recurrence bends.
Checks: (1) atone recurrence of `literal-request-over-intent` and
`dense-briefing-instead-of-a-direct-answer` in months with regular /intake use vs
months before (`bash ~/.claude/scripts/atone.sh search <slug>`); (2) sampled runs
show the six-line form, not an essay; (3) divergence lines that the owner answers
with "the other reading" count as catches, and there are some, because a prototype
that never catches anything is decoration.

Maturity bar: the `maturity: prototype` flag flips to stable when check (3) shows
at least one real catch across five or more recorded runs. Not before, and never
by a maturation pass alone; the flag is a claim about evidence, not effort.

## Runtime notes and ledger

Prepend a `## intake:` entry via
`bash ~/.claude/skills/shared/prepend-runtime-note.sh intake <entry.md>` when a run
taught something. Then
`bash ~/.claude/scripts/skill-log.sh record intake --task "<gist>" --outcome unknown --corrections 0 --note "divergence=<none|caught|missed> lines=<n>"`.
