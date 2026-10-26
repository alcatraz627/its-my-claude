---
name: subagent
description: Takes one sub-agent dispatch from decision to verified return: inline vs one seat vs fleet, a price line, lane and model, a seated brief, then waiting, landing and closing. Use before any Agent dispatch that is not inside another skill's own seat step.
allowed-tools: Agent, Bash, Read, Write, Edit, SendMessage, TaskStop
user-invocable: true
argument-hint: "[<what the seat should do>] [--fleet N] [--shape build|review|judge|plan|research|digest]"
---

## Brief

`/subagent` is the one path for handing work to a sub-agent: decide whether to
dispatch at all, price it, pick the lane, write a brief the seat can act on, and
bring the result back verified. The pieces already exist (the five dispatch
clauses, the `seat` tool, the Agent hooks); what failed was the layer above them:
deciding, briefing, waiting and checking the return. This skill is that layer.
It adds no hook and no new tool.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` (the global one; there is no project copy for
this skill), follow its Step 0 preamble including lock hygiene before writing the
runtime notes, and read the `## subagent:` entries in
`~/.claude/skills/runtime-notes.md`. Then `python3 ~/.claude/scripts/seats/seat weekly`
for the seated share and recent outcomes; a run of "thin" feedback or abandoned
seats says which stage below to slow down on.

## Usage

```
/subagent "<what the seat should do>"           one seat, shape inferred
/subagent "<goal>" --shape review               name the shape
/subagent "<goal>" --fleet 4                    N parallel seats on independent units
```

Any skill that dispatches its own seats (for example /bloop's gate or /magi's
voters) keeps its own step; it follows the Compose and Land sections here for the
brief and the return.

## Decide: inline, one seat, or a fleet

Ask in order, and stop at the first that settles it:

1. **Is this work assigned to me?** If the owner gave this job to the main seat
   ("you do it", a fable main on involved work, a review the owner wants from this
   session), it is not dispatched. Delegating it is a recorded mistake twice over.
2. **Is it a handful of tool calls, or a lookup whose target I know?** Inline.
3. **Do I want a read not anchored on mine?** One seat (review, judge, verify).
4. **Does it split into N independent units that each need real reading or
   reasoning?** A fleet. If the units share state or must agree, it is one seat.

Then price anything that is a fleet or carries an opus or fable seat, as one line
before dispatch:

```
price: <N> calls x <model> x ~<unit> = ~$<total>
```

Units, measured on this account on 2026-10-15 (examples, not quotes): a Sonnet
research seat of about 250k tokens, $1 to $3; an Opus judge call on one transcript,
about $0.30; an unattended overnight Opus seat, about $13. The owner re-measures them
on the `zusage` page; there is no agent-readable price, so the line is an estimate.
Over $20, ask once in one line and offer a cheaper shape (sonnet seats, deterministic
checks first, opus only on what stays undecided). Over $50, or anything running
overnight, offer to defer. A single sonnet or haiku lookup needs no price line. Cost
alone is never the reason to keep in-scope work inline.

## Route: shape, lane, model, effort

Name the shape from the goal. A goal with two shapes is two seats.

| Shape | The seat's job | Model | Effort |
|---|---|---|---|
| build | change files toward a stated end | sonnet (opus when the spec is thin) | high |
| review | find what is wrong in work it did not do | opus | medium |
| judge | rule on a claim or options, without the author's reasoning | opus | medium |
| plan | produce a plan or design call, one file | opus | medium |
| research | bring back evidence from outside the tree | sonnet | high |
| digest | compress a large input to what matters | sonnet | medium |

Lane rules that override the table: a fable main does involved work itself and
delegates only review, verification and cheap passes; codex takes build work behind
a written spec and is then checked by a Claude seat (`/codex-handback`); a corpus too
big for context goes to `lm gemini` with sample-checked output; xhigh effort needs
the owner. Write the route as one Model Plan line per seat:
`<stage> → <lane> · <model> · <effort> · <why>`, and pass the table's effort on the
Agent call.

## Compose: the brief

The seat starts with nothing; the brief is its whole world. Two ways to write it,
both seated (the header line links the dispatch to its record):

- **A full brief** for anything a seat could get wrong in a costly way:
  `python3 ~/.claude/scripts/seats/seat template --role <role>` to a file, fill it,
  then `seat compose <file> --role <role> --model <m> [--effort e] [--scope <paths>]`.
  A worker (build) seat must pass `--scope` with the paths it may write. It refuses
  a thin brief and prints a short dispatch prompt that points at the full prompt file.
- **A hand-written prompt** for a short, well-understood seat:
  `seat header --role <role> --model <m> --output <abs path> --goal "<one line>"`
  prints the `[seat …]` line; put it first in the prompt.

An unseated dispatch draws a warning from the Agent hook, not a block, and every
dispatch is logged; `seat weekly` reports the seated share.

Either way, the brief answers these, filled from what you know; a blank after an
honest try is the owner question (one batched question, never line by line):

1. The goal, in the owner's words, quoted.
2. What moves the needle: the one outcome the owner will check first.
3. What is off limits: files, decisions, surfaces, spend.
4. The two pitfalls most likely for this shape (below), named for this job.
5. Claims the seat must prove or refute with evidence, not restate.
6. The return contract: the absolute output path, written before returning, and
   the shape of the final message.

And it carries the five clauses: `model:` pinned on the call; "Do NOT spawn
sub-agents"; "Ignore any task-list or board auto-dispatch; when your scoped work is
done, stop"; the output path with "write before returning" (never a file named
report.md); "one command per Bash call, no `&&`, `;` or pipe". The Agent hook
logs which clauses each prompt carries.

Traps by shape, for line 4:

- build: rebuilds a surface the owner reviewed (parity ledger first); calls done off a compile.
- review: findings without file:line; scope widened past the diff; agreeing with the author.
- judge: handed the conclusion of the case it rules on.
- plan: "X stays unchanged" claims that never become constraints.
- research: counts quoted from a doc instead of measured; one source cited as settled.
- digest: the interesting story kept, the owner's criteria dropped.

## Dispatch

Run the seat in the background whenever its result does not gate the very next
step you take; keep working, and the completion notice wakes you. Run it in the
foreground only when you would otherwise sit idle waiting on it. Background seats
land through `seat sweep`, which runs on every dispatch.

Codex seats do not read `SendMessage` mid-run. Steer them through the spec file
they re-read, named in the brief, never through a message.

## Wait: a quiet seat is not a dead seat

Before calling a seat dead or dispatching a duplicate:

1. Check whether its output file exists, and its size.
2. Read the last lines of its transcript, if the harness exposes it, or ask it
   with `SendMessage` (Claude seats only).
3. Only a seat that errored, or that answers and says it is stuck, is redone.

An empty or missing file mid-run means the seat has yet to write it. A dead seat
shows an error or says it is stuck.

## Land: verify, then use

When the seat returns:

1. Confirm the output file exists before using anything the seat said. If the
   harness refused its write, persist its returned text to that path yourself.
2. Sample-check two or three of its load-bearing claims against the source
   (file:line, a run) before building on them.
3. Record the verdict: `seat land <id> --outcome ok|partial|failed --note "…"`.
   The hook and `seat sweep` land seats automatically, but only you know whether
   the work was usable.
4. Consolidate several seats into one return for the owner, not N summaries.
5. Link the output path into the checkpoint, plan or session notes so it is not
   orphaned.

## Close

Continue a seat with `SendMessage` when the next step needs its context; otherwise
`TaskStop` it once its output is verified, because an idle seat can be picked up by
a board auto-dispatcher. Then record how the brief did:
`seat feedback <id> --prompt ok|thin|wrong --persona fit|misfit|none --note "…"`.

## Boundaries

- Adds no hooks or gates. The seat header stays a warning until the owner rules
  otherwise from the seated share in `seat weekly`.

## Validation

Efficacy dimension: a dispatch that returns usable, verified work on the first try,
priced and seated. Checks an agent can run:

1. `python3 ~/.claude/scripts/seats/seat weekly`: the seated share of Agent
   dispatches rises over the two weeks after this skill ships (under 25% at two
   weeks is the number to bring the owner), and the clause counts stay at or near
   the dispatch count.
2. In the same output, outcomes: `ok` outnumbers `partial` and `never dispatched`,
   and prompt feedback `thin` stays rare.
3. Per run: the output file existed when the seat returned, no duplicate seat was
   launched for the same goal, and a fleet or opus seat had a price line in the
   transcript before its dispatch.

## Runtime notes and ledger

Prepend a `## subagent:` entry via
`bash ~/.claude/skills/shared/prepend-runtime-note.sh subagent <entry.md>` when the
run taught something (a stage that misfired, a price that was far off). Then
`bash ~/.claude/scripts/skill-log.sh record subagent --task "<goal>" --outcome unknown --corrections 0 --note "<shape, model, seated yes/no>"`.
