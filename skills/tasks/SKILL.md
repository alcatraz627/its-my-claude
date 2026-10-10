---
name: tasks
description: The owner's steering view of live goals. Bare /tasks composes the views that fit the ask (gates first, then convergence, drift as one loud line); /tasks now | path | left [goal] | doing | drift | shape "<one line>" call one. Facts come from the goal record via the views, never from memory. Use for the task list, what is left, what needs me, is this converging, what are you doing, or to reshape it in one line.
argument-hint: "[now | path | left [goal] | doing | drift | shape \"<one line>\"] [--all | --project X | --goal G] [--detail | --json]"
user-invocable: true
allowed-tools: Bash, Read
---

## What this is for

> /tasks exists so the owner can see, at any moment and from any directory,
> whether each live goal is converging on its stated outcome, what is gated on
> them, and what is drifting, and can reshape that picture in one line.
> (ruled 2026-09-23)

Convergence is measured against **acceptance**: the owner's own rows (visual,
functional, deployed, reviewed) on the goal. A goal whose rows are all done
and whose acceptance is unproven is "built, not accepted", never met. That one
requirement outranks format, grouping and tagging; every fix before this one
polished the paint and left the need untouched (`assets/reports/20260923-tasks-rebuild/`).

## The one record

A goal, keyed by its own id, at `~/.claude/goals/by-id/<goal_id>.json`: outcome,
acceptance rows, milestones (states), rows under milestones, projects and
sessions as attributes. `~/.claude/scripts/goals/gs` writes it; the views read
it. Sessions and projects are filters, never keys, so no view ever resolves a
store, pins one, or refuses. The agent's own Task-tool store
(`~/.claude/tasks/session-*`) stays agent-private working memory; `gs adopt`
is the only path from it to the owner's surface.

The store refuses: a goal with no acceptance row, a row with no milestone, a
gate with no do-line, a subject over 70 chars (cut at a word, tail to the
note), `met` while a row is open or an acceptance row is unproven.

## Run it

```bash
V=~/.claude/scripts/goals/views
python3 $V/path.py           # convergence: header, CLEAR NOW, one box per goal   (the default table)
python3 $V/now.py            # what waits on the owner, with the do-line for each
python3 $V/left.py [--goal G]  # one goal: acceptance rows with evidence, open rows, unread notes (consumed)
python3 $V/doing.py          # running, delegated, in review, with lane and session liveness
python3 $V/drift.py          # stale goals, aged gates, built-not-accepted, unfiled agent rows, rulings not read
```

Scope flags on every view: `--all` · `--project <path|name>` · `--goal <id|prefix|word>`
· `--detail` (height law off) · `--json`. Bare scope is this session's goal plus
live goals whose projects include the CWD repo. `~/.claude` is a repo like any
other (the gcc), never a window onto every goal; only `--all` shows everything
(owner, 2026-09-24: a gcc session showing a product session's goal is the old
wrong-queue defect in reverse).

## Bare `/tasks`: compose, do not recite

| Signal in the ask or the state | Show |
|---|---|
| any gate open | `now` first, always |
| goal · done · left · path · converging · "can I use it" | `path`; plus `left` when one goal is named |
| doing · what are you on · running | `doing` |
| `drift` non-empty | one loud line appended; the full view on "what's wrong" |
| mark done · fold X into Y · drop · group by · "give me a goal for all this" | `shape`: translate to `gs`, print the commands, apply, re-render |
| nothing live | "no live goal here" and the `gs new` line |

Put each rendered view in a code fence before any prose. Read the header
before showing it: is the scope the one the owner meant, are the goals ones you
recognise? A confident table about the wrong goals is the worst outcome here.

## `shape`: the owner's one-liners are writes

```bash
G=~/.claude/scripts/goals/gs
$G new "<outcome>" --accept "<kind>: <what the owner will check>" [--accept …] [--project a,b]   # arms it; prints the /goal line
$G milestone <g> "<a STATE, true or false after 'Right now,'>"
$G task <g> <mN> "<subject>" [--gate "USER: …" --do "…"] [--lane L --tier T --kind K --domain D] [--blocked-by 3,4]
$G start|review|defer|ready|close <g> <id> [--by "<instrument>"]   ·   $G delegate <g> <id> --to <seat>
$G gate|ungate <g> <id> …   ·   $G prove <g> <aN> --by "<instrument>"   ·   $G met <g> --by "<instrument>"
$G fold <g> <mN|#N> into <mN>   ·   $G drop <g> [<mN>|<id>] --why "…"   ·   $G park|revive <g>
$G note <g> [goal|mN|id] "<handoff>"   ·   $G notes <g>        # ephemeral: no state, consumed on first read
$G adopt <g> <mN> --session <sid8> [ids]   ·   $G import-callouts <g> [--surface s]   ·   $G link <g>
```

- "Dropzone is done, mark it so" → `close` with the instrument, or `met` when
  the goal is; if acceptance is unproven say so and ask which row proves it.
- "Fold the one-off UI fixes into the general UI sweep" → `fold mN into mN`.
- "Give me a goal for all this" → draft the outcome and the acceptance rows
  from what the owner said they will check, draft milestones as states, then
  `new` + `milestone` + `task`, and print the `/goal` line. Every clause one the
  agent can finish alone (`rules/goal-statement-on-starting-work.md`).
- "Finish the tail of #3 before anything else" is a **note on #3**, never row #4
  (owner ruling D1, 2026-09-23: a handoff must not become a second nagging task).
- Say the commands you ran in one line; never re-type the facts from memory.

## Acceptance is where "done" lives

`gs new` requires at least one acceptance row. `gs import-callouts` turns the
owner's `/callouts` review findings into acceptance rows on the goal (visual →
visual, technical and behavior → functional, literary → other); a retired
callout with a pass recheck arrives proven. `gs prove` names the instrument.
`left` shows every row with its evidence state before it shows any task.

## The shape: cards (ruled 2026-09-24, two decision pages)

**A frame per goal**, the goal holding an owner gate first, no separate band.
Inside, in this order:

1. `to finish: N rows, M milestones, K acceptance rows · first stop: <who> at #id`
2. Each milestone wears an emoji (`gs milestone … --emoji`, else derived from its name); the "next" one rides the to-finish line, and a stage strip appears when a goal has three or
   more milestones with open rows.
3. The open rows, split **burst** (the agent takes these without stopping),
   **stop** (someone else is needed), **after** (behind a stop). Colour appears
   only on stops: 🏓 you, 🐱 a seat, 🤝 a peer, 🧷 **closure pain**. Every other
   row is one ASCII glyph (▶ running, ○ ready, ~ after a task, 🗑️ deferred). A
   holder column appears only when a goal has more than one holder; a goal with
   six or more open rows draws them as a ledger table. A row gets a second
   `↳` line when it stops for someone or when it would clip.
4. The acceptance checklist, ◻ unproven, ✓ proven with what proved it.
5. Unread handoff notes, as a count.

**Closure pain** is the owner's word for the known finalization hassle between
rows done and goal met: a deploy, a migration, a review round, a smoke check.
`gs closure <g> <id> "<why>"` marks it; the card shows it as a 🧷 stop; the
agent makes space for it and never skips it. The owner's purpose for the
screen, verbatim: "gauge what all the agent can do in an uninterrupted burst
and when an owner gate or an explicit other-agent input OR making space for
some known finalization hassle-dealing to ensure goal is met instead of tasks
are checked, is needed".

Width free, **height within 44 lines**; a card that cannot show every row
names the count inside the frame. `--quiet` is the 09-23 flat style,
`--boxed` the 09-05 rail-and-ball shape (rulings in `skills/tasks/REDESIGN.md`).

## Hooks around this

`scripts/hooks/task-table-inject.sh` renders `path` on the observed phrasings
and hands it to the agent to show verbatim; after twelve quiet turns it nudges
with `now`. `scripts/hooks/hand-rendered-tasks-stop.sh` warns when a turn
hand-renders a task table without calling a view or `gs`. Mute the injector:
`touch ~/.claude/.no-task-table-inject`.

## What is not here

- The kanban board is independent, optional and **frozen** (D2, 2026-09-23):
  nothing writes to it unasked. `/kanban` reads it.
- Decisions the owner must make go through `/decision-wizard`; a gate here
  only says one is owed and how to clear it.
- The old renderer (`scripts/task-table/`) is no longer called by any surface.
  Its session stores remain readable input for `gs adopt`.

## Validation

The efficacy question is unchanged: did the render answer, or did the owner
re-ask. `logs/tasks-render-reactions.jsonl` records the owner's next prompt
after each injected render; `scripts/measure/reaction-join.py` reports the flag
rate. Suites: `scripts/goals/tests/gs.test.sh`, `views.test.sh`,
`drift-doing.test.sh`, each with a mutation control. Green before any change
to `goalstore.py`, `gs`, `render.py` or a view.
