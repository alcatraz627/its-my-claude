---
name: validate
description: Routes a finished or nearly-finished change to the checks it actually needs, by first naming every validation question the change raises and then saying which instrument covers each one and which are being skipped and why. The failure this prevents is not picking the wrong checker, it is never asking the third question at all. Use when a change is about to be called done, when a review keeps missing what the user then catches on sight, or when you have fifteen audit skills and no idea which apply here. Not a checker itself: it classifies, enforces one precondition, and hands off.
allowed-tools: Read, Grep, Glob, Bash, Agent
argument-hint: "<what changed> [path or diff scope]"
user-invocable: true
---

## Brief

The front door to validation. The account holds more than a dozen checking
instruments and the selection has been made from memory every time, which means
the check nobody thought of is the one that never runs. This skill makes the
selection explicit and, more importantly, makes the omissions explicit.

It routes and it records. It does not run the checks itself, and it never
declares anything done.

## Step 0: Load shared guidelines

Read `~/.claude/skills/GUIDELINES.md` and apply it for the run. Read
`~/.claude/skills/validate/runtime-notes.md` if it exists.

## Phase 1: Name every question this change raises

Seven questions. Go through all seven, every time, out loud. Answering "not
applicable" is a valid outcome and is the point of the exercise; silently
skipping is the failure this skill exists to stop.

| # | Question | Instruments |
|---|---|---|
| Va | **Does it run?** | `/test`, the harness-bundled `run` skill, `/bloop` Phase 4, and `rules/exercise-based-verification.md` |
| Vb | **Is the code right?** | `/skeptical-review` while still in the session, `/adversarial-review` once it has been declared done |
| Vc | **Does it look right?** | `/ui-categorical-check` for bug classes, `/ui-gripe` for confusion, `/vis-compare` against a reference, `/ui-loop` (`see reshoot`) against a stored baseline, `/designer-reviewer` and `/web-design` for scored critique. `/visual-regression` is parked |
| Vd | **Is it safe, typed, consistent?** | the harness-bundled `security-review` skill; `npm audit` and `npm outdated` by hand (`/dep-audit` is parked). See the project-gating note below before reaching for the three Next.js audits |
| Ve | **Is the writing right?** | `scripts/style/prose-lint.py`, `/ste-writing`, `/cleanup-comments` |
| Vf | **Did what already worked survive?** | a parity ledger. See Phase 3 |
| Vg | **Is this what was asked?** | nothing automated. See Phase 4 |

Vf and Vg carry no convenient skill, which is exactly why they get their own
phases below rather than a table row. They are the account's two most recurring
serious failure classes, and a validation router that cannot ask them is not
worth having.

**Project-gating note.** `/type-audit`, `/route-audit` and `/invalidate-audit`
are written against Next.js App Router and one specific product, and all three
set `disable-model-invocation: true`, so they cannot auto-fire and must not be
offered outside a project whose shape matches. They are also PARKED (mig 0048,
`~/.claude/skills-parked/`): invoking any of them fails today regardless of
project shape. To use one, copy it into the project's `.claude/skills/` first,
then name it.

## Phase 2: Map the change type to its questions, then state the skips

This is the precondition, and it is the inverse of the usual failure. Write the
list of questions this change raises, including ones nobody asked for, then for
each one say which instrument covers it or why it is being skipped.

A starting map, to be adjusted rather than obeyed:

| Change type | Usually needs |
|---|---|
| UI surface | Va, Vb, Vc, Vf, and Ve for its copy |
| API or endpoint | Va, Vb, Vd, Vf |
| Refactor with no behaviour change | Vf first and hardest, then Va, Vb |
| Data migration | Va on a sample, Vd, Vf, and reversibility |
| Config, hook, or guard | Va, plus a mutation test, because a guard that has never fired is untested |
| Docs or prose | Ve, Vg |
| Dependency bump | Vd, Va |

A skipped check that is named is a decision. A skipped check that is never
mentioned is the defect. Write the skips down where the user can see them.

## Phase 3: Vf, did what already worked survive

If the change came from `/build-ui` or `/build-change`, a parity ledger already
exists. Run every row's check and report the results row by row. That ledger is
a contract, and an unrun check is an unmet one.

Whatever ledger exists, the callout store is part of Vf now: run
`bash ~/.claude/scripts/callouts/callouts.sh gate <surface>` for every surface the
change touched. Open call-outs are the owner's own parity rows, and an unmet one
outranks anything a generated ledger says.

If no ledger exists, build a small one now before any other check runs, from
what is actually there rather than from memory: the tests that currently pass,
the callers of anything the change touched, and any behaviour a `NOTE(by human)`
or `HACK` comment marks as deliberate. One row per behaviour that must still
hold, each with the check that would catch its loss.

**Run every row, whichever kind of ledger it is.** An inherited ledger and one
you just wrote are both contracts, and a row whose check has not been executed
is an unmet one. A ledger that merely exists is the negative-checker shape from
`rules/testing.md`: it detects bad-presence and never good-absence, so it is
vacuously satisfied by an empty or truncated list. Report the result per row,
including the rows that passed.

This phase is mandatory whenever the change touched something that already
worked. The recurring failure it addresses is a rebuild that replaced
accumulated behaviour while every gate verified only the new thing, so nothing
represented the old behaviour and nothing could fail on its absence.

## Phase 4: Vg, is this what was asked

Re-read the user's original request, verbatim, and compare it against what was
built. Compare against their words, not against the plan, because the plan is
already a paraphrase and a paraphrase is where the drift entered.

Three questions that catch most of it. Did a named example get implemented
literally when it stood for a class? Did an instruction get scoped down to the
nearest easy reading because the ask sounded urgent? Was something the user
deferred quietly resurrected because a later message brushed the same topic?

There is no instrument for this. It is a read and a comparison, and it takes a
minute.

## Phase 5: Vf and Vg go to a second seat, never to self-assessment

Vb hands the code to a separate reviewer. Vf and Vg are the two questions this
account fails most often, and they are the two where the agent that did the work
is the worst available judge, because both ask whether the work drifted from
something the author already believes it matches.

So dispatch one seat that did not do the work. Build the dispatch with
`bash ~/.claude/scripts/seat/seat.sh prompt --role second-seat --out <abs path> --subject <report>`
and verify the verdict landed with `seat.sh check --out <abs path>`. Give it the user's verbatim ask,
the change scope, and the parity ledger with its per-row results, and ask it to
answer two questions independently rather than to review your answers:

- Vf: which ledger rows does the evidence actually support, does any row's
  check pass for a reason other than the behaviour surviving, and what old
  behaviour appears in no row at all? An absent row cannot fail, so the seat
  names what the ledger never covered.
- Vg: comparing the user's words against what was built, what was asked for and
  is missing, and what is present that was never asked for?

Pin the seat to sonnet for an ordinary change and opus when the change is large
or hard to reverse, per `rules/model-tier-routing.md`. Tell it not to spawn
sub-agents and to stop when its answer is written. Its findings are reported as
they came back; the author does not get to overrule them silently, and a
disagreement is reported as a disagreement.

Self-assessment is never licensed by the size of the diff. A small diff shrinks
the context, not the author's bias, and Vf and Vg are bias questions. The only
exemption is the owner explicitly waiving the seat for this run: record it as
seat-waived=owner in the Phase 7 note (the write refuses a validate record that
carries neither a real seat nor that waiver) and say it in the report. An
unrecorded skip is the failure this phase exists to prevent.

## Phase 6: Hand off

Invoke the chosen instruments, one at a time, carrying the change scope and the
user's verbatim ask to each.

Then stop. This skill does not fix what the checks find, and it does not say
the change is done. It reports what ran, what each returned, and what was
skipped. The person who asked owns the verdict.

## Phase 7: Record the routing

```bash
bash ~/.claude/scripts/skill-log.sh record validate \
  --task "<what changed, trimmed to a line>" \
  --outcome unknown \
  --corrections 0 \
  --note "asked=<Va,Vb,...> ran=<n> skipped=<list with reasons> parity-rows=<n> rows-run=<n> second-seat=<seat model or name, or seat-waived=owner> found=<n>"
```

Watch the skipped list over time. If one question is skipped in most runs it is
either genuinely rare or quietly being avoided, and the two look identical until
someone counts.

## When NOT to use

- You already know which check to run. Run it. This removes a recall tax rather
  than adding a hop.
- Nothing has changed yet. Validation follows a change.
- A one-line edit whose only check is that it parses.

## Done-condition

- [ ] All seven questions considered out loud, including the not-applicable ones
- [ ] Every question either assigned an instrument or explicitly skipped with a
      reason the user can read
- [ ] Vf answered from a parity ledger, inherited or built during this run, with
      **every row's check executed** and its result reported, passes included
- [ ] Vg answered by comparing against the user's verbatim ask, not the plan
- [ ] Vf and Vg judged by a seat that did not do the work, or self-assessment
      declared in the report with the reason
- [ ] Results reported without a done verdict attached
- [ ] Run recorded via `skill-log.sh record validate`

## See also

- `/plan` is the sibling front door for planning, and routes on needs rather
  than on questions
- `/bloop` runs build and validation as one loop, and consults this skill in its
  validation phase rather than inventing an attack list. Loop bound, shared
  with `/bloop`: a change that fails validation re-enters the loop at most
  once, and a second failure returns to the owner, never to another automated
  pass
- A `/build-change` plan, when one exists, is pointed at by the project's
  `.claude/output/latest-change-plan.txt`; read the parity ledger from there
  rather than asking for it
- `/skeptical-review` and `/adversarial-review` are the two code-review
  instruments, split by whether the work has already been called done
- `rules/testing.md` for the scale-to-task ladder and the mutation-test rule
  that Phase 2 refers to for guards
