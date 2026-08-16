---
name: tasks
description: Show the current task list as a table, sized so it never has to be scrolled to. Width is free, height stays within 44 lines, and the rows the owner can act on come first. Use when asked to show the task list, the todo list, the queue, what is left, what is pending, or the status of open work.
argument-hint: "[--json | --compact | --session <sid8>]"
user-invokable: true
allowed-tools: Bash, Read
---

## Brief

Renders the live task list as one table. The problem it solves is not formatting.
It is that the list was asked for fifteen times in two days and answered a
different way each time: sometimes a table, sometimes prose, once as forty-six
full descriptions. One of those asks arrived twice in a row with "check properly"
appended, which is what an answer that missed looks like.

## The owner's ruling, which the renderer enforces

From 2026-08-13, verbatim:

> The issue with large ones is needing to scroll all the way up to see the task
> list. It can be wider, that's fine. Also have more detail if needed, but the
> height need not exceed 1.25 times this preview.

So **width is free and height is capped at roughly 44 lines**, the same law the
catchup briefing follows. Detail is welcome inside that budget. Past it the table
truncates loudly and names what it dropped, because a silently trimmed list reads
as a complete one.

## Run it

```bash
bash ~/.claude/scripts/task-table/task-table.sh
```

| Flag | Use |
|---|---|
| (none) | the framed baseline table |
| `--json` | full data, including every resolved reference |
| `--refs` | just the reference glossary |
| `--compact` | a three-line digest, for injection or a status line |
| `--session <sid8>` | a specific session's store |

## The script owns the facts. You own the presented table.

Put the table in a code fence, before any prose. Never re-render it from your own
memory of the task list: that was the original defect and it is the one thing that
stays forbidden.

**But read the header before you show it, and check it against what you expect.**
Trusting the script over your memory is right for the CONTENT and wrong as a
reason to skip the sanity check. Those are compatible, and only the first used to
be stated here.

Concretely: does the session id in the header match the store you meant? Do the
counts sit anywhere near what this session has been doing? Are the task names ones
you recognise? A peer caught the wrong-session bug on exactly this signal, and
noticed that the old wording told them to distrust it. If the header disagrees
with your expectation, say so and resolve it before rendering. Reproducing a
confident table about another session's work is the worst outcome available here,
because it looks exactly like the right answer.

The baseline is a **floor, not a ceiling**. Add a context column when this queue
needs one, and drop back to the baseline when it does not. Freedom lives in the
columns; it never extends to the facts.

### Column vocabulary

Core columns are always present: id, task, source, ref count.

Optional columns each have a bar to clear, and the bar exists because a column
that is present in every table stops carrying information:

| Column | Earns its place when |
|---|---|
| **blockers** | more than one open row is waiting on something nameable, and the blockers differ from each other |
| **domain** | the queue spans several areas of the goal set and the reader is choosing between them, not just reading down |
| **notes** | several rows carry a caveat that changes what the reader would do |
| **model** | RARELY. Only when the queue genuinely mixes expensive planning and review, straight execution, cheap scouring, and real local-model work. A queue of ten similar build tasks does not need it. The owner's words: do not overindex on this. |

Read that last row as one example of the class rather than a standing feature.
The point is that columns answer the question the reader has today.

### Dereference anything a stranger could not parse

Owner ruling, 2026-08-15: a bare task number, proposal id, disposition code, or
file path tells an out-of-context reader nothing about the premise of the row.
Every such reference gets a one-line gloss or an absolute path.

`--refs` resolves them in bulk: proposal ids against the ledger, task numbers
against the store, files by existence check, atone ids to their lookup command.
Use it whenever the reader is not the person who filed the work, which includes
the owner returning after a day away.

### Output surface

Chat, essentially always. A `.md` file is the exception, not an equal option, and
it is right only when the content genuinely cannot meet the height cap, such as a
full ledger with descriptions and provenance.

## What the grouping means

**NOW** is in-progress work. **NEEDS YOU** is the only section the owner can act
on, so it sits above the rest: it holds anything gated on a phrase, an owner
review, a decision, or their presence. **AGENT-READY** is work that needs nothing
from them. **DONE** collapses to a row of ids, because a finished task's detail
belongs in the ledger rather than in a status view.

The `backlog` and `session` marker is derived from whether the description carries
a `prop-` id, which is a real property of the data rather than a guess about
intent.

## When they want more than the table

The table is a status surface, not a record. For descriptions and provenance,
generate a ledger instead and hand over the path, because that content cannot fit
the height cap and should not try:

```bash
# see assets/reports/<date>-task-ledger/ledger.md for the shape
```

## The hook that calls this

`scripts/hooks/task-table-inject.sh` runs on UserPromptSubmit. When the prompt
asks for the list in any of the phrasings actually observed, it renders the
baseline and injects it with the render-from-this-data instruction. It also nudges
after twelve quiet turns.

A hook cannot print to the human transcript (`features/hooks-tui-limits.md:36`),
so the hook renders and the agent prints. The agent is the display layer, which is
why the ban is on rendering from memory rather than on choosing columns.

## Confirm which store you are reading

**The store is named for the session that CREATED the tasks, and a task list
survives `/clear`, so the live session id routinely does not name its own store.**
There is no filesystem pointer from a live session to its store.

On 2026-08-16 a bare run rendered a different session's queue with complete
confidence: fifty-nine tasks, one open, none of them ours. "Most recently
modified" is whichever session wrote last, not whichever is asking.

The resolver now runs a ladder, and declares a guess rather than making one
quietly:

1. `--session <sid8>` when the directory exists.
2. A store matching `CLAUDE_CODE_SESSION_ID`, which usually does not exist.
3. The newest populated store, printing `!! STORE NOT CONFIRMED` in the header.

**When you see that warning, pin the store before trusting the table.** Run
`ls ~/.claude/tasks/` and pass the right `--session`. A status surface showing the
wrong status is worse than one showing nothing, and this one has done it once.

Mute: `touch ~/.claude/.no-task-table-inject`, machine-wide until removed.

## How this pairs with the kanban board

They serve the same goal, visibility, from different altitudes, and the owner has
already ruled that they must not collapse into each other.

`rules/todo-discipline.md:52-64`, owner ruling 2026-08-10: the board is "an
independent artifact and never a mirror of the Task list". A project outlives one
session, so the board carries what the owner needs across the whole project, the
way a sprint board differs from a checklist in a pull request. That section exists
specifically to stop an agent finding a board that disagrees with the task list,
concluding the board is stale, and reconciling it into a copy. That reconciliation
destroys the durable record, which is the only thing the board is for.

So the flow between them is deliberately narrow:

- **Share vocabulary, not state.** The `domain` column should use the board's
  lane names, so both surfaces call the same work by the same word. A shared
  vocabulary is not a mirror.
- **Cite, do not import.** A task may carry an optional `board_card` in its
  metadata, set by hand, and the table may show it. The link is one-directional
  and the board's state is never read in as truth.
- **Never generate.** Do not create board cards from tasks, and do not fold board
  state into the table. That is the collapse the ruling names.

The table answers "what is this session doing right now". The board answers "where
is this project". A reader who wants the second question answered is on the wrong
surface, and the right response is to point at the board rather than to widen this
table until it becomes one.

## Notes

- **Add observed phrasings, never guessed ones.** The trigger list in the hook
  came from grepping two days of transcripts. When a real ask misses, add that
  exact wording. Inventing phrasings inflates the false-fire rate for no gain.
- **The classification the owner asked for is not built yet.** They asked which
  items need thoughtful planning first and which are small backlog items wrapping
  up a goal. The task store has no field for that, and inferring it from
  description text would be wrong in a way nobody could see. It wants a metadata
  key set at creation time. The plumbing is built and proven (task-table.sh reads metadata.class / metadata.domain / metadata.board_card), but only tasks created WITH that metadata populate the columns. Set it at TaskCreate time going forward.
