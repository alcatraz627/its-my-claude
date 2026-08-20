---
name: build-change
description: Plans a non-UI change and produces an execution plan whose every clause has a command, a file:line, or a named artifact behind it. Classifies the change, states problems as falsifiable triples, inherits its approach by sweeping how this codebase already solves the shape, writes a parity ledger for behaviour that must survive, turns findings into directives that each carry a runnable check, then specifies a contract skeleton and the smallest slice that runs. Can and must output "no build" when nothing warrants work. Use before writing code for a backend change, a refactor, a data migration, a CLI, a script, or a pipeline that already exists. Not for a one-line fix, and not for pages, which are /build-ui.
allowed-tools: Read, Grep, Glob, Bash
argument-hint: "<the change, or the surface to change> [scope limit]"
user-invocable: true
---

## Brief

The non-UI half of the planning machinery. `/build-ui` already plans page work
to a standard where every clause is checkable, and almost none of that rigor is
actually about pixels. This skill is the same discipline in general vocabulary,
for the backend change, the refactor, the migration, and the CLI that previously
had nothing between a four-line sketch and writing the code.

It emits one plan and stops. It does not implement, and it does not commit.

## Step 0: Load shared guidelines and runtime context

Read `~/.claude/skills/GUIDELINES.md` and apply it for the run. Read
`~/.claude/skills/build-change/runtime-notes.md` if it exists.

Read the project's own conventions before planning against them. A repo's
`CLAUDE.md`, its `docs/` decisions, and any ADR outrank anything general here.

## Phase 1: Refuse conditions, decided before anything else

Run the census in this phase rather than deferring it, because this gate decides
whether there is work at all and a gate that consumes a measurement produced two
phases later is deciding on nothing.

At least one of these must fire, with evidence:

1. **Behaviour is wrong or absent.** A failing check, a reproduction, a missing
   capability someone needs. Record the command and its current output.
2. **A cost is being paid repeatedly.** Duplication with a count, a manual step
   run on a schedule, a measured slowness. Record the number.
3. **A constraint is violated.** The code contradicts a documented decision, a
   contract, a schema, or a rule the project states about itself.

If none fires, the plan says `no build` and stops. This is binding, not
advisory. A planning skill that can never recommend doing nothing will find a
reason for whatever it was pointed at.

## Phase 2: Classify the change

Pick exactly one. The class decides how much of the rest applies, and naming it
out loud is most of the planning decision.

| Class | What it is | What it most needs |
|---|---|---|
| **Behaviour** | changes what the system does for someone | parity ledger, reproduction first |
| **Structure** | same behaviour, different shape (refactor, extraction, rename) | parity ledger is the whole job |
| **Capability** | something the system could not do before | inheritance sweep, contract skeleton |
| **Migration** | moves data or state from one form to another | reversibility, a dry run on a sample |
| **Removal** | deletes a capability or a path | reader sweep, quarantine before delete |

When two seem to fit, the change is usually two changes. Say so and plan the
first.

## Phase 3: State the problems falsifiably

Every problem is a triple, or it does not go in the plan.

| Field | Content |
|---|---|
| **Observation** | a `file:line`, or a command with its current output. Never an adjective. Pair a line reference with a stable anchor such as a symbol name, because line numbers drift and a plan that outlives its references reads as wrong rather than stale. |
| **Cost** | what breaks, who it reaches, how often |
| **Check** | the command or artifact whose result flips when this is done |

Inadmissible: "the job runner is fragile."
Admissible: "`runner.py:88` retries on any exception, so a malformed payload
retries forever and the queue stalls. Check: a malformed row now lands in the
dead-letter table within one attempt."

Wishes go in a speculative appendix the plan explicitly does not authorize. That
appendix is what stops a fix becoming a rewrite. Keep observed anomalies that
have a plausible innocent explanation in a separate non-claims list marked watch
rather than chase, and never mix them into the problems.

## Phase 4: Inherit by measurement, not memory

Before designing anything, find how this codebase already solves this shape.
Grep the full tree rather than the directory where the answer ought to live,
because the original author placed it where the trigger fires, not where the
catalog belongs.

Emit an inheritance ledger, one row per decision, each carrying evidence:

| Decision | How this repo already does it | Evidence (file:line) | Adopting or deviating | Reason if deviating |
|---|---|---|---|---|

Rows worth forcing, when the change touches them: error handling and how errors
propagate, retry and backoff, logging, configuration reads, database access and
transactions, background work, input validation, and how tests for this area are
structured.

An empty sweep result is a finding, not permission to invent freely. It means
you are setting precedent, so say that out loud and let the owner see it as a
new-precedent row rather than as an ordinary choice.

## Phase 5: The parity ledger

This phase exists because the account's most frequent recent serious failure
(first in every recency window, fifth all-time) is a rebuild that quietly
replaced accumulated behaviour with no audit that anything survived. The
general form of that failure is not UI specific at all.

Do not take the ranking on trust, including from this file. Re-derive it:

```bash
bash ~/.claude/scripts/atone.sh search rebuild-replaced
```

List what must still be true after the change, one row each, and give every row
a check that would fail if it were lost:

| Must still hold | Why it matters | Check that would catch its loss |
|---|---|---|

Populate it from what exists rather than what you remember: the current tests,
the callers of anything you are touching, the documented contract, and any
behaviour a comment marks as deliberate. A `NOTE(by human)` or `HACK` comment is
a tested decision and belongs in this ledger rather than in the diff.

For a Structure-class change this ledger is the entire deliverable, because
"same behaviour, different shape" is a claim that only a parity check can make
true.

## Phase 6: Turn findings into directives that carry checks

Each directive gets an ID, an imperative statement, and a check. A directive
without a runnable check is a wish with better grammar.

| ID | Directive | Check |
|---|---|---|
| D1 | ... | command, or named artifact, whose result flips |

Directives that came from the parity ledger are marked as such, so a later
reader can tell what the change adds from what it must not break.

## Phase 7: Specify the skeleton and the first running slice

The skeleton is the contract: the function or endpoint signatures, the data
shapes, the module boundaries, and what calls what. Write it as the interface a
reviewer could argue with before any implementation exists.

The first running slice is the smallest end-to-end path that actually executes
and can be observed. Name it explicitly, because a plan whose first verifiable
moment is at the end has no early failure signal. Say what command runs it and
what output proves it worked.

Right-size both to the change. Climb the ladder from reusing what is here, to
the standard library, to a dependency, and stop at the first rung that holds.
Do not introduce a helper for a caller that does not exist yet.

## Phase 8: Emit the plan, then stop for the ruling

**Write the plan to a file before returning it.** The parity ledger is the part
worth surviving, and a ledger that lives only in a context window is gone at the
next `/clear` or compaction, which is exactly when `/validate` comes looking for
it. The time segment is load-bearing: two runs on one day must not overwrite each
other.

```bash
OUT="<project>/.claude/output/$(date +%Y%m%d-%H%M)-<slug>-change"
mkdir -p "$OUT"        # plan.md, with the parity ledger as its own section
printf '%s\n' "$OUT/plan.md" > "<project>/.claude/output/latest-change-plan.txt"
```

The pointer file is the discovery contract: a consumer reads
`.claude/output/latest-change-plan.txt` instead of guessing dated paths, which
is what made earlier plans unfindable.

Fall back to `~/.claude/assets/reports/<YYYYMMDD>-<HHMM>-<slug>-change/` when the
project has no output directory. Never write a relative `.claude/...` path while
the working directory is `~/.claude`, because it resolves to `~/.claude/.claude/`
where nothing reads it.

The plan carries, in order: the class and the refuse-condition evidence, the
parity ledger, the directives, the skeleton, the first running slice, then
sequencing and anything the change must not touch. Optional sections go after,
and only when they carry weight.

Then stop. This skill does not implement. Hand the plan to `/bloop` for a built
and validated change, or to the owner when the plan itself needs a ruling.

State the model plan when the work will fan out, per
`~/.claude/rules/model-tier-routing.md`.

## Phase 9: Record the run

```bash
bash ~/.claude/scripts/skill-log.sh record build-change \
  --task "<the change, trimmed to a line>" \
  --outcome unknown \
  --corrections 0 \
  --note "class=<behaviour|structure|capability|migration|removal> no-build=<yes|no> parity-rows=<n> directives=<n>"
```

The count worth watching is `no-build=yes`. A planner that has never once said
there was nothing to do is not gating, and the refuse conditions in Phase 1 are
decoration.

## When NOT to use

- A one-line fix, a typo, a rename with no readers outside its file. Just do it.
- A page or any user interface. That is `/build-ui`, which is this same shape
  specialised for surfaces.
- A question about how the system works today, with no change intended. That is
  `/arch-qa`.
- A choice between approaches you already understand. That is `/magi`.
- Work blocked on a judgment only the owner can make. That is `/gated-plan`.

## Done-condition

- [ ] A refuse condition fired with evidence, or the plan says `no build`
- [ ] Exactly one class named
- [ ] Every problem is a triple with an observation, a cost, and a check
- [ ] The inheritance sweep ran across the full tree, and its ledger cites
      file:line per row or declares the slot empty
- [ ] A parity ledger exists, and every row has a check that would fail if that
      behaviour were lost
- [ ] Every directive carries a runnable check
- [ ] The first running slice is named, with the command that exercises it
- [ ] The plan written to a date-and-time stamped output path, so the parity
      ledger survives a `/clear` or a compaction
- [ ] The plan stops before implementation
- [ ] Run recorded via `skill-log.sh record build-change`

Anything less is a draft, not a plan.

## See also

- `/build-ui` is this same machinery specialised for pages, and carries the
  UI-specific parts this skill deliberately omits: segment loading law, the
  skeleton and embryo vocabulary for surfaces, and the design-token census
- `/bloop` takes a plan and drives it through build, review, and validation
- `/gated-plan` when the work cannot proceed until the owner rules
- `/deep-research` when the plan depends on evidence from outside this machine
- `rules/right-sized-code.md` for the ladder Phase 7 refers to, and
  `rules/invariant-graduation.md` for why the parity ledger is a phase rather
  than a paragraph
