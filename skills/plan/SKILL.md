---
name: plan
description: Routes a planning request to the instrument that fits it, by naming which of six needs the request actually has, and refuses to plan a change to something that already exists until current behaviour is written down. Planning requests usually carry two or three needs at once, and naming them is most of the routing decision. Use when a plan is wanted and the right instrument is not obvious: "how should we approach X", "what's the plan for Y", "where do I even start", "should we do A or B". Not a planner itself: it classifies, enforces one precondition, and hands off.
allowed-tools: Read, Grep, Glob, Bash
argument-hint: "<what you want planned, in your own words> [target]"
user-invokable: true
---

## Brief

The front door to planning. The account holds instruments for orienting,
deciding, researching, specifying, sequencing and gating, and the cost of using
any of them has been remembering which name to type. This skill reads a request,
names the needs behind it, and invokes the one or two instruments that serve
them.

It routes and it records. It produces no plan of its own.

## Step 0: Load shared guidelines

Read `~/.claude/skills/GUIDELINES.md` and apply it for the run. Read
`~/.claude/skills/plan/runtime-notes.md` if it exists.

## Phase 1: Name the needs

Six needs. A request usually has two or three, and they are served in order, so
name them all and say which comes first.

| # | Need | The question it answers | Instruments |
|---|---|---|---|
| Pa | **Orient** | what is this system and how does it work today | `/arch-qa` traces code paths, `/project-index` maps structure, `/past-sessions` recovers prior context, the `feature-dev:code-explorer` agent |
| Pb | **Choose** | which approach, and why not the others | `/magi` for multi-voter deliberation, `/decision-wizard` to batch the human's judgments into one pass |
| Pc | **Learn** | what is true outside this repo | `/deep-research` for a verified cited report, `/cogitate` for a durable topic note |
| Pd | **Specify** | turn intent into a plan whose clauses can be checked | `/build-ui` for pages, `/build-change` for everything else |
| Pe | **Sequence** | what order, tracked where | the Task tool, which is the live status surface, plus `personas/task-goal-planner.md` and `/bloop` Phase 1 |
| Pf | **Gate** | what must the owner rule on before this proceeds | `/gated-plan`, and `/decision-wizard` when the rulings are numerous |

Orient almost always comes first when the target already exists, and skipping it
is how a plan ends up describing a system that is not there.

## Phase 2: Apply the two modifiers

These cut across all six needs and change the instrument rather than the need.

**Scale.** A question whose answer requires reading a corpus rather than a file
routes to `/pyramid-sweep`, which mines broadly with cheap passes and spends
judgment only on survivors. A single pass over a large corpus either truncates
or costs a fortune.

**Constraint.** Work against a real deadline routes through `/deadline`, which
spends the user's return visits as the scarce resource. Work blocked on an owner
judgment routes through `/gated-plan`, which batches the open questions into one
decision-grade bundle instead of asking them one at a time as they arise.

## Phase 3: The precondition

For a change to something that already exists, current behaviour gets written
down before anything plans to alter it.

This is one paragraph, not a document: what the thing does today, who depends on
it, and where that is visible in the tree as a file:line or a command. Derive it
by reading rather than by recall, and say plainly when you could not establish
part of it.

The reason is specific. A plan that never states current behaviour cannot carry
a parity check, and the account's most frequent recent serious failure (first
in every recency window, fifth all-time; re-derive with
`bash ~/.claude/scripts/atone.sh list`) is a rebuild that replaced working
behaviour with nothing representing the old version, so no gate could fail on
its absence. The statement written here is
what `/build-ui` and `/build-change` turn into a parity ledger.

Do not take the ranking on trust, including from this file. Re-derive it:

```bash
bash ~/.claude/scripts/atone.sh search rebuild-replaced
```

Greenfield work has no such surface, so this precondition does not apply. Say
that it is greenfield rather than silently skipping.

## Phase 4: Hand off

Invoke the instrument for the first need, carrying the named needs, the target,
the current-behaviour statement or the reason there is none, and the user's own
words verbatim. The verbatim ask travels with every hop, because a multi-stage
pipeline drifts from the original request one paraphrase at a time.

When the request carries several needs, hand off to the first and say what comes
next rather than invoking three instruments at once. Sequencing them is the
user's call, and their answer to the first often changes the rest.

Then stop. This skill writes no plan, makes no decision, and edits nothing.

## Phase 5: Record the routing

```bash
bash ~/.claude/scripts/skill-log.sh record plan \
  --task "<the request, trimmed to a line>" \
  --outcome unknown \
  --corrections 0 \
  --note "needs=<Pa,Pd> routed=<skill> precondition=<written|greenfield|blocked>"
```

`--outcome unknown` is the honest value at hand-off, since whether the plan was
kept is decided downstream. Use `revised` with `--corrections 1` when the user
rejects the routing and names a different instrument, because a wrong route is
exactly the rework this skill exists to prevent.

## When NOT to use

- You already know the instrument. Type it.
- The work is a handful of mechanical edits. Do them.
- Nothing is being planned, and the question is what something currently does.
  That is `/arch-qa` directly.
- The plan already exists and needs building. That is `/bloop`.

## Done-condition

- [ ] Every need present in the request named, with the order they are served in
- [ ] Scale and constraint modifiers considered, and applied or dismissed
- [ ] Existing target: a current-behaviour statement written, with a file:line or
      a command behind it; or greenfield declared
- [ ] The user's verbatim ask travels with the hand-off
- [ ] One instrument invoked, and this skill wrote nothing
- [ ] Run recorded via `skill-log.sh record plan`

## See also

- `/validate` is the sibling front door for checking a change once it exists
- `/ui` is the front door for anything on a screen, and routes into `/build-ui`
- `/build-change` is the general specify instrument, and `/build-ui` its UI
  specialisation
- `rules/structure-over-one-shotting.md` for why non-trivial work gets a plan
  before it gets an attempt
