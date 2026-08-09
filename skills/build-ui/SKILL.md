---
name: build-ui
description: Plans a page-level UI build or renovation and produces an execution plan whose every clause has a command, a file:line, or a named artifact behind it. Classifies the work (surface conversion, trait sweep, or primitive promotion), picks the goal from the decision the user leaves with, derives environment context by measurement rather than memory, states problems as falsifiable triples, assigns a value-add profile that generates loading law, inherits layout by sweeping siblings, then specifies a structural skeleton and a living embryo. Can and must output "no build" when nothing warrants work. Use when asked to build, renovate, restyle, or bring a page up to the design language; when a page "feels dated" or "off"; or before writing UI code for a surface that already exists. Not for single-component fixes or one-line copy changes.
allowed-tools: Read, Grep, Glob, Bash
argument-hint: "<page or surface> [trait-only scope]"
user-invokable: true
---

## Brief

Plans a page-level UI build or renovation and emits ONE execution plan a
different engineer can run cold. Every clause carries a command, a `file:line`,
or a named artifact. The skill plans; it does not implement. That is enforced
by `allowed-tools` above, which withholds Write and Edit: the ruling gate in
Phase 11 is mechanical, not a promise.

## Step 0: Load shared guidelines and runtime context

Read `~/.claude/skills/GUIDELINES.md` and apply its rules for the whole run:
forbidden paths, retry logic, tool preferences, verbosity, timeouts, and
post-run insights. Also read `~/.claude/skills/build-ui/runtime-notes.md` for
past runs; continue without it if absent. This skill holds no file locks
because it writes only its own plan.

# build-ui

Plans a page-level UI build or renovation. The deliverable is an execution plan
document that a different engineer, or a different agent, can execute cold.

**The one rule everything else serves:** a plan clause is worth nothing that a
command cannot check. Every clause carries a command, a `file:line`, or a named
artifact. A clause carrying none of those is deleted, not softened.

That rule is not a preference. It comes from a measured failure. The commit held
up as the model page renovation in this account (`8cf51c9`, walmart-mvp) shipped
and left four lines of the old dialect at `Settings.tsx:108,111,140,272`, sitting
two lines from the new dialect at `:254,:286`. A conversion judged by eye
converts what the author looked at.

## When to use

- "Renovate / restyle / rebuild page X"
- "Bring X up to the design language"
- "X feels dated / cluttered / off"
- Before writing UI code for a surface that already exists

## When NOT to use

- A single component fix, or a copy change. Just do it.
- A greenfield page with no sibling and no canon. This skill is a **delta
  instrument**; with no comparison base it has nothing to measure against. Say so
  and fall back to `/frontend-design` or `/web-design`.
- Confusion forensics on a specific screenshot. That is `/ui-gripe`.
- Categorical bug classes before shipping. That is `/ui-categorical-check`.

## Placement of data

This skill is app-agnostic. Everything app-specific lives as **data in the target
repo**, never inline here:

| Data | Lives at | Volatility |
|---|---|---|
| Existence guidance | `<app>/.claude/ui/primer.md` | years |
| Hazard ledger | `<app>/.claude/ui/hazards.md` | append-only |
| State primer | regenerated per run, never stored | minutes |
| Design canon | wherever the repo keeps it | months |

If `<app>/.claude/ui/primer.md` does not exist, Phase 2 creates it from what you
measure and asks the owner to confirm the law section. Do not proceed on a
primer whose recorded SHA is not an ancestor of HEAD; regenerate instead. The
check, so it is a command and not a sentiment:

```bash
git -C <app> merge-base --is-ancestor <primer-sha> HEAD && echo current || echo regenerate
```

---

## Phase 0. Refuse conditions

Stop and say so, before anything else, if:

- The target has no sibling pages and no design canon. Wrong instrument.
- Another session holds the target's files. Plan only, and say so in the plan.
- The owner has not named a target surface. Ask which page.

## Phase 1. Classify the renovation

**Do this first. It decides the plan's whole shape.** These are directions of
travel, not sizes of job.

| Class | Shape | Done-condition |
|---|---|---|
| **Surface conversion** | vertical: one page, many traits | the page satisfies every row of its directive table |
| **Trait sweep** | horizontal: one trait, many pages | a named grep returns zero across the whole tree |
| **Primitive promotion** | design in the shared kit, release, consume, sweep consumers | the kit exports it, every consumer that should use it does, and none still hand-rolls it |

Three classes, two axes: conversion and sweep are the axes, promotion is the
kit-shaped case that runs along both.

> **State which direction correct work moves the metric, and reject any metric
> where correct work and regression move it the same way.** A migration toward a
> new dialect makes hits of that dialect *rise*, so counting them flags good work
> as regression, and a check that fires on good work gets disabled. Verified
> case: a rising count read as drift until the consuming app's own stylesheet was
> found to carry the owner ruling that the new dialect was the target. The metric
> that survives is usually the mixed one: count the files speaking BOTH, and
> require it to only ever decrease.
>
> **Corollary, and it has cost real work: state checks as a rule plus an
> enumeration, never as a bare count.** A count is a proxy, and the cheapest way
> to satisfy a proxy is to damage what it counts. A pilot check demanded one
> token appear on exactly four elements; it appeared on seven, all of them
> correct, and meeting the number would have meant deleting real affordances.
> Write "every use of X is in set S, and here is the list", so a mismatch sends
> the reader to the list instead of to the delete key.

> **Count consumers through the app's indirection layer, not by the export
> name.** A well-behaved consumer routes kit exports through a single-source
> alias map, so a grep for the literal export reports its *best* consumers as
> absent. Verified case: a kit icon looked unconsumed until the trail ran through
> the app's icon map and into the component that renders it.
>
> The same audit is where a primitive with **zero** callers surfaces. A request
> for a primitive is not a caller. If nothing consumes it after the sweep, say so
> and either find the surface that wants it or drop it.

A single request often contains more than one. Split them into separate plans
rather than one blended plan, because their done-conditions are not compatible.

**Primitive promotion carries a hazard the other two do not.** The kit reaches a
consuming app by a copy ritual, so the source can be correct while the running
app is stale.

> **Its consumption gate must be a value computed by the running consumer, not
> the presence of the new source.** This is the strong form and it is expensive
> to learn the other way. In a real roll, three checks all passed and all were
> irrelevant: the file on disk was new, the version string in `package.json` was
> new, and the source the dev server served over HTTP for that path was new. The
> app still executed the old code, because replacing a directory by copy fires no
> watch event, so the bundler's in-memory module graph never invalidated.
> Clearing the dependency pre-bundle did not fix it either; only a server restart
> did. `getComputedStyle` reported the old value while every upstream artifact
> reported the new one.
>
> So the gate is: **read a computed value out of the running app and watch it
> change.** "The new source is present in the consumer" is not evidence.

State the class in line one of the document.

## Phase 2. Pick the goal, and decide if work is warranted

**State the goal as the decision the user leaves with**, not the data the page
shows. "Confirm who can act in this org, and change that", not "display
settings". Deriving from the decision is what stops you inheriting whatever the
current DOM happens to do.

Triangulate three sources; **disagreement is the finding**:

1. **Claimed**: nav label, route, spec, mock.
2. **Actual**: what it renders and mutates today. List every control.
3. **Consumed**: what the user does before and after, and how often.

Where claimed and actual disagree, name which wins and why. Inheriting the
current goal is legal but never silent. Write `goal: inherited, unchanged`.

**Then run the three work triggers.** At least one must fire:

1. **Dialect drift**, mechanical. A grep for superseded tokens or primitives
   returns hits. Record the count. **Run the census here, in this phase.** Do
   not wait for the Phase 3 state primer: this gate decides `no build`, and a
   gate that consumes a measurement produced one phase later is deciding on
   nothing. The primer reuses this census; it does not supply it.
2. **Affordance gap**. Something carries meaning or action without saying so.
3. **Mock or law divergence**. The surface contradicts the mock, or breaks the
   owner's UI law.

**If none fires, the plan says `no build` and stops.** This is binding, not
advisory. A builder skill that can never recommend doing nothing is a
rationalization engine.

Log the outcome so the rate can be audited; an instrument that always says no
is as useless as one that always says yes. One line per run, appended to
`<app>/.claude/ui/build-log.jsonl`:

```bash
printf '%s\n' "$(jq -nc --arg ts "$(date -u +%FT%TZ)" --arg s "<surface>" \
  --arg o "<build|no-build>" --arg t "<trigger that fired, or none>" \
  '{ts:$ts, surface:$s, outcome:$o, trigger:$t}')" \
  >> "<app>/.claude/ui/build-log.jsonl"
```

**Record the outcome per problem, not per run.** A brief usually carries
several problems and they rarely share a verdict. A pilot run found three of
seven already solved by a version that landed after the brief was written; a
single verdict could not say so, and re-solving them would have been the
literal-request failure. Give each problem its own `build` or `no-build`, and
say which already-shipped change closed the ones you are declining.

The trigger also sizes the job. Trigger 1 alone is a sweep. Triggers 2 or 3 mean
a conversion.

**Check the authority actually covers this page.** If the plan will cite a mock
or spec, confirm the target is in it. A binding mock that does not contain your
page means sibling precedent is the primary inheritance source, not a fallback.
This has bitten a real run: the pilot page was absent from a six-screen mock.

## Phase 3. Environment context, split by rot rate

One document with two rot rates is stale by definition. Produce three things.

**Existence guidance.** Slow law, hand-written, about one page. What the app is,
who uses it, the shell contract, the token source, the component library, and the
owner's UI law. Lives in the repo; the plan **cites it and never copies it**,
because a copy is a fork that rots invisibly.

**Model plan.** The sweeps in this phase and Phase 6 are mechanical grep work,
so route them and say so (`rules/model-tier-routing.md`). Four lines in the
plan:

```
census + sibling sweep → sonnet · low  · read-only, no nesting
outward reference      → sonnet · medium
judgment and synthesis → main agent (never delegated)
validation seat        → sonnet · medium · no nesting (opus if the surface is contested)
```

**Colour verified on the shipped value.** Any colour specified in a wide space
(OKLCH, LCH, P3) is checked AFTER conversion to what the browser will serve.
Clipping to sRGB moves hue, not only chroma: on the pilot it rotated two label
hues under their separation rule while the specification said they complied.

**State primer.** Regenerated at plan time from fixed commands, never stored, so
it cannot rot. Kit version and export list; a legacy-token census; the
sibling-wrapper survey; the page's own imports. Stamp it with the commit SHA.

> **Anti-rot rule.** Any primer line not regenerable by a command and not
> resolvable as a `file:line` is **deleted, not repaired**.

**Hazard ledger.** Append-only, in the repo, written by whoever got bitten. Facts
no amount of code-reading recovers. The canonical entry from this account: custom
spacing keys in `index.css` shadowed Tailwind v4's container scale, so
`max-w-md` compiled to `max-width:16px` and prose collapsed to one word per line.
A builder who reads every component still walks into that. Regenerated primers
cannot hold such facts and hand-written primers rot around them, so hazards get
their own lane.

## Phase 4. State the problems falsifiably

Every problem is a triple, or it does not go in the plan.

| Field | Content |
|---|---|
| **Observation** | a `file:line`, or a command with its current output. Never an adjective. Pair a line ref with a stable anchor (a symbol, a quoted comment) when the file is under active edit, because line numbers drift and a plan that outlives its line refs reads as wrong rather than stale. |
| **Cost** | what the user cannot do, and who they are |
| **Check** | the command or named artifact whose result flips on completion |

Inadmissible: "Settings feels dated."
Admissible: "`Settings.tsx:108,111,140,272` use retired tokens, so error text
renders a different red than every sibling page. Check: `rg 'ink-|2xs|signal-'
pages/Settings.tsx` returns nothing."

Wishes go to a **speculative appendix** that the plan explicitly does not
authorize. That appendix is what stops a renovation becoming a redesign.

Keep a separate **non-claims** section for observed anomalies with a stated
alternative explanation and a "watch, do not chase" instruction. Never mix those
into the problem list.

## Phase 5. Classify the segment, and let it generate loading law

**Role, two axes.** *Traffic*: destination, waypoint, utility. *Cadence*: daily,
occasional, once. The pair has consequences the plan cites. Utility x occasional
means legibility cold beats density, which licenses a narrow column; a daily
destination holding a table does not.

**Role picks the width. The builder does not.**

> Measure the target app's own conventions before applying any canon. Transferring
> a sibling app's ladder without measuring has produced a wrong finding in a real
> run.

**Value-add profile.** Four primitives: `standalone`, `composite`, `information
display`, `control surface`. Write combinations as an **ordered pair, primary
first**. The primary decides layout; the secondary decides affordance density.
An unordered list of adjectives lets a builder pick whichever one justifies what
they already wanted. A profile with no dominant means the segment should be split
in two.

**The profile generates loading law**, which is the point of assigning it:

- **Control-surface weight** means affordances are present and honest even when
  inert. That is `disabled-real`, never a bone.
- **Information-display weight** means genuinely unknown values may bone. That is
  `honest bone`.

The four readiness classes, in preference order:

| Class | Meaning |
|---|---|
| `static` | knowable at build time. Render it as itself. |
| `ready-to-show` | derivable from data already on the client |
| `disabled-real` | the real element rendered inert. Beats a bone: layout, affordance and label are all real. |
| `honest bone` | genuinely unknown. **The only place a skeleton placeholder belongs.** |

Every placeholder in the plan carries its class, and a bone carries a written
justification for why the value is genuinely unknown.

## Phase 6. Inherit by measurement, not memory

Sweep the siblings and the shell before drafting. Emit an **inheritance ledger**,
one row per decision, each with a majority count and a citation:

| Decision | Inherited value | Evidence | Adopted / deviated | Reason if deviated |
|---|---|---|---|---|

Mandatory rows: page wrapper, width, first child, section or card container,
heading scale, form row, row rhythm, empty state, loading state, toast.

Three defects, all blocking:

- An uncited layout claim.
- A deviation without a stated reason.
- A value authored where the sweep returned a result.

**A value may be authored only where the sweep returned empty**, and every
authored value is listed as a **new precedent** needing owner sign-off. Design
languages accumulate synonyms otherwise: one real canon in this account carries
five names for a single idiom, with a standing instruction to reuse rather than
invent a sixth.

## Phase 7. Write the ideated UI semantic description

It is the **contract between the goal and the skeleton**. The implementing
engineer reads it first; the owner reads it as the sign-off surface.

Form: a numbered element list. Each entry has exactly four fields.

| Field | Content |
|---|---|
| **Role** | the Phase 5 primitive |
| **Content source** | a data field name, or verbatim mock copy |
| **Component** | the kit component, or the literal word `raw` |
| **State behavior** | boot, loading, loaded, empty-or-error |

Two bans keep it in its lane:

- **No props, classNames, or JSX.** That is pseudo-code and belongs in the
  skeleton or the embryo.
- **Every noun is a data field name or verbatim copy.** "Clean and modern" has
  neither, so it is deleted.

Two tests:

- Any entry a reviewer cannot mark satisfied or violated by looking at the
  running page is cut.
- **Adequacy:** two implementers working from it independently produce the same
  DOM order and the same behavior in all four states.

## Phase 8. Turn traits into directives

A trait becomes a directive when it has **named classes, a rule, and a check**.
A row with an empty check column is not a directive. It is advice, and builders
skip advice.

Give directives **stable IDs** (`D-COLOR-03`) and map every region to the IDs it
must satisfy, so the build is auditable line by line rather than vibe-checked.

The nine trait families, their classes of use, and worked rules live in
[`references/directives.md`](references/directives.md). Load it in this phase.

> **Promotion rule.** A directive that must hold on **every** page does not
> belong in a per-page plan at all. Promote it into the repo's permanent gate
> catalog. The procedure, since "promote it" is not a check: append the class
> to `<catalog>/patterns.md` in that file's own shape (name · what it looks
> like · why assertions miss it · the mechanical check), where `<catalog>` is
> the directory `/ui-categorical-check` Phase 1 resolves for this project. The
> per-page plan then cites the class id instead of restating the rule.

> **Directives outlive the plan only if they become a script.** On approval,
> the page-specific directive checks are written to
> `<app>/.claude/ui/checks/<slug>.sh`, exiting non-zero on any violation, and
> committed with the change. A plan document binds nobody: on the pilot surface
> a shipped colour contract was violated within hours by a new element whose
> author reasoned correctly from the law the plan had just replaced, and no
> mechanism noticed. The script is what turns a directive into something a
> future change can fail.

## Phase 9. Specify the skeleton

**Open this section with this exact disambiguation line, every time:**

> *Structural skeleton, meaning the region cast. Not a loading skeleton; loading
> placeholders are specified per region as readiness classes.*

Ambiguous vocabulary is the most reliable way a written instruction rots, and a
mandated sentence is the cheapest available fix.

**Skeleton is breadth without depth.** The page's whole structure rendered with
real copy and real kit components, **zero data and zero handlers**. It compiles
and it renders.

It renders rather than staying abstract because the artifact then doubles as the
boot frame, which is how real codebases already build it: an app boots its real
shell with placeholders confined to data slots, under comments like "boot and
loaded chrome cannot drift".

> **A runnable skeleton makes the static-first check cheap and visual. It does
> not replace it.** Static-first is slow law from Phase 3, and it needs its own
> pass: *is this element's content known at build time? If yes, render it as
> itself.* Two real cases prove a runnable skeleton alone does not enforce it. An
> Error management banner was missing from the boot tree on a page that already
> rendered. A home-page skeleton mirrored the whole page but omitted a static
> button that the loaded page showed. Both pages were runnable. Both shipped the
> bug.

Contents: every region, its nesting, its order, its layout law from Phase 5, its
sizing, its overflow behavior, and its readiness class per region.

**Failure mode: a missing or misordered region.** The real instance in this
account: an entire static banner absent from the boot tree because the loading
branch rendered only a table skeleton, so the banner popped in on load.

## Phase 10. Specify the embryo

**Embryo is depth without breadth.** Exactly one region taken fully alive: real
data, real handlers, every state class, every Phase 8 directive applied, mock
copy verbatim.

**Choose the region that exercises the most state classes**, not the simplest
one, because the rest of the page grows from it by repetition. In the pilot run
the embryo was the members section rather than the connection section, because it
alone exercised loading, error, permission gating, mutation, and destructive
confirm. Once the owner signs off on the embryo, every other region is
repetition, not design.

Two failure modes, both cheap to detect:

- **Vitality:** a region that looks right and is dead. No toast, a generic
  loader, a fade where a real placeholder belongs.
- **Structural falsification:** an embryo that needs a **new structural kind** to
  become the full page. That is a failed embryo, and it is the cheapest available
  signal that the skeleton was wrong.

**Build order: skeleton, then embryo inside it, then replicate.** Skeleton and
embryo are the surface-conversion slices. Trait tables are swept separately with
grep done-conditions.

## Phase 11. Emit the plan, then stop for the ruling

Write to `<app>/.claude/output/<YYYYMMDD>-<HHMM>-<slug>-renovation/PLAN.md`.
The time segment is not decoration: two plans for one slug on one day collide
without it, and the second silently overwrites the first.

**Required sections, in this order, none renamed or dropped:**

1. **Directives** (Phase 8 tables, with IDs and checks)
2. **Skeleton** (Phase 9, opening with the mandated disambiguation line)
3. **Embryo** (Phase 10)
4. **Other instructions** (sequencing, gates, coordination, what not to touch)

**Optional sections**, included only when they carry weight:

- Helpful mental models
- Justifications or retros
- Edge cases and problems
- Tech debt

Then **stop and present to the owner.** No implementation code before the ruling.
Batch every judgment the plan needs into one surface; `/decision-wizard` handles
more than about three.

**The hand-off block, written into "Other instructions" before you stop.** The
plan names its own executor and the terms, or the loop ends at the ruling:

- **Executor:** on approval, run the build through `/bloop`, seeding the
  Phase 4 validator's attack list from this plan's directive checks verbatim.
  Every D-* row is a named claim to attack.
- **Post-build gate:** `/ui-categorical-check` runs on the built surface, over
  the FULL catalog rather than the classes this plan happens to name. On the
  pilot, every serious finding came from a class the plan did not name; the
  author's own checks confirmed the author's own design.
- **Evidence:** the validation report's path lands in this plan's dispositions
  table. A plan whose dispositions carry no report path is not done.
- **Commit scope:** name the files this change owns, and commit them with a
  scoped `git add`. Never `git add -A` in a repo other sessions are editing.
  On the pilot another session's blanket add swept an entire colour conversion
  into a commit whose message never mentioned it, so the history records work
  that appears never to have happened.
- **Surface claim:** say who holds these files. If another session is editing
  them, the plan says so and the build uses targeted edits only.

## Done-condition for this skill

`build-ui` has finished when:

- [ ] The plan states its renovation class in line one
- [ ] The goal is a decision, and its three sources are triangulated
- [ ] A work trigger fired, or the plan says `no build` and stops
- [ ] Every problem record carries a check
- [ ] The inheritance ledger has no uncited row and no unreasoned deviation
- [ ] The directive table has no empty check cell
- [ ] Every placeholder carries a readiness class; every bone carries a
      justification
- [ ] The skeleton section opens with the disambiguation line
- [ ] The embryo names why its region exercises the most state classes
- [ ] A fresh reader who has never seen the app can name the goal, the regions,
      and the first thing to build
- [ ] The hand-off block names the executor, the post-build gate, the evidence
      path, the commit scope, and who holds the files

Anything less is a draft, not a plan.

## Provenance

Framework settled by a five-seat opus MAGI panel, 2026-08-08. Archive, including
the five proposals, the vote matrix, and the reasoning behind the minority ruling
on skeleton:
`~/.claude/assets/magi/20260808-0203-build-ui-skill-framework/`

## See also

- `/ui-categorical-check`: the permanent gate catalog that directives get promoted into
- `/ui-gripe`: confusion forensics on one screenshot
- `/skeptical-review`: grounded review after the build
- `/decision-wizard`: batching the owner's ruling
