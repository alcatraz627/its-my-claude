---
name: tasks
description: Show the current task list as ONE grouped, tagged, sequenced table (project's ruled key; width free, height within 44 lines). Also the write path when the harness has no Task tool (task.sh). Use for the task list, todo list, queue, what is left or pending, or to regroup it.
argument-hint: "[--group batch|domain|class|actor] [--set-group <key>] [--json | --compact | --session <sid8>]"
user-invocable: true
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

## The shape (owner-ratified 2026-08-19, every /tasks run, every session)

```
TASKS · <store> · <alias> (<model>) · N open, M done · open rows written Xm ago
  grouped: goal › batch (project view file) · needs you: #… · running: #…
────────────────────────────────────────────────────────────────────────
GATES (you)   (n)                       ← first, always
  🔴 #id  task                                     owner        tags
         ↳ blocked: <the blocked_on text> · note: …
────────────────────────────────────────────────────────────────────────
GOAL <name>   (n open, k sequenced)
  BATCH <name>
    ○ #id  task                                    lane·tier    class · domain
    ⛓ #id  task  (after #x)                        lane·tier    …
         ↳ refs: #x (gloss) · prop-… (title)
────────────────────────────────────────────────────────────────────────
LATER · deferred / after V1   (n)
────────────────────────────────────────────────────────────────────────
legend: ✅ done · ▶ running · ○ ready · ⛓ after #x · 🔴 needs you · ⏳ needs you (inferred)   lanes: …
done (M): #…      height h/44 · regroup … · --detail · edit: task.sh
```

No vertical box borders (a glyph's terminal width can then never break the frame); rows
inside a batch follow the `blockedBy` chain; every stored field prints (blocked_on text,
lane, tier, goal, note, priority, refs gloss); an unset tier is a loud `?`; `--detail`
prints descriptions and the full glossary. Rulings and provenance:
`assets/reports/20260819-tasks-audit/plan.md`.

## Grouping comes first, and a project ruling outranks the baseline

The owner, 2026-08-18: `/tasks` "should show a structured, grouped, tagged,
batched sequence; I get to tell the agent to re-arrange it or it does it anyway;
this is FOR MY visibility", and typing two lines to get that by hand was "a HUGE
FRICTION". So the bare command is already grouped, and the grouping key resolves
in this order, highest first:

1. `--group <key>` on the call, a one-off rearrangement ("group these by class").
2. **The project's view file**, `<project>/.claude/tasks-view.json` (inside the
   gcc itself: `~/.claude/tasks-view.json`), which holds `group`, an `order` of
   group keys, and `labels`. **A project-level grouping ruling lives HERE, in a
   file the tool reads, and it outranks everything below.** If the owner has ruled
   how a project's list is grouped (slack-automation: by goal lane A..E, ruled
   four times), that ruling belongs in this file, and `task-table.sh --set-group
   <key>` writes it so it is said once. A ruling that lives only in a memory note
   is the shape that produced a 4th-occurrence S3 on 2026-08-18
   (`mist-20260818-130748-e4`).
3. Auto: `goal` if any open row carries `metadata.goal` (with `batch` as the sub-band),
   else `batch`, else `domain`, else the actor split.

Whatever the grouping, the actor split is never lost: it rides as the row glyph
(🔴 gated on you · ⏳ gated by inference · ▶ running · ○ ready · ⛓ waits · ✅
verified) and as one `needs you: … · agent-ready: …` line under the header. The
`tags` column carries class / domain / batch (whichever is not the group key) and
`seq` carries `⛓ #N` (waits on) or `→ #M` (blocks).

**Rearranging is yours to do, and welcome.** When the owner says "group by X" or
"put the deck stuff first", run it with `--group` and, if it is a standing
preference, `--set-group` (plus `order` / `labels` edited in the file). When you
can see a better grouping than the current one, use it and say so in one line;
the owner asked for that. The one thing that stays forbidden is re-typing the
facts from memory.

## Run it

```bash
bash ~/.claude/scripts/task-table/task-table.sh                # grouped by the resolved key
bash ~/.claude/scripts/task-table/task-table.sh --group class  # one-off regroup
bash ~/.claude/scripts/task-table/task-table.sh --set-group domain   # sticks for this project
```

| Flag | Use |
|---|---|
| (none) | the grouped table (view file → auto) |
| `--group <batch\|domain\|class\|actor\|auto>` | one-off grouping |
| `--set-group <key>` | persist the grouping for this project (writes the view file) |
| `--json` | full data: `groups`, `group`, `group_source`, every task with metadata and refs |
| `--refs` | just the reference glossary |
| `--compact` | a three-line digest, for injection or a status line |
| `--session <sid8>` | a specific session's store · `--pin <sid8>` remembers it for this live session |

## Writing tasks when the harness has no Task tool

Fable builds (observed 2026-08-18 by three sessions) expose no TaskCreate /
TaskUpdate / TaskList. Use `scripts/task-table/task.sh`, which writes the same
store files the Task tool writes, so this table reads both:

```bash
task.sh add "<subject>" --class fix --domain hooks --batch A --goal "<goal>" --lane <lane> --tier <fable|opus|sonnet|haiku|lm> [--priority P1] [--owner <alias>] [--note "…"] [--blocked-on "USER: …"] [--verified true|false|prod] [--blocked-by 3,4]
task.sh update <id> --status in_progress|completed --append-desc "…" --blocked-on … --clear-blocked-on
task.sh done <id>…   ·   task.sh start <id>   ·   task.sh meta <id> batch=B owner=me   ·   task.sh list
```

Set `class`, `domain`, `batch`, and `blocked_on` at creation, whichever tool you
use: this table groups and gates from metadata, and an unset field is rendered as
inferred (⏳) rather than declared (🔴), which is a weaker claim.

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

Core columns are always present: id (full width, `#121` is never shown as `12`),
task, tags, seq.

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
Every such reference gets a one-line gloss or an absolute path. The stronger
form: a row whose SUBJECT was compressed away is deleted, never shipped. A
subjectless id row is noise wearing a row's shape (mist-20260820-092606-29).

`--refs` resolves them in bulk: proposal ids against the ledger, task numbers
against the store, files by existence check, atone ids to their lookup command.
Use it whenever the reader is not the person who filed the work, which includes
the owner returning after a day away.

### Output surface

Chat, essentially always. A `.md` file is the exception, not an equal option, and
it is right only when the content genuinely cannot meet the height cap, such as a
full ledger with descriptions and provenance.

## What the actor split means

**NOW** is in-progress work. **NEEDS YOU** is anything gated on the owner (a
phrase, a review, a decision, their presence). **AGENT-READY** needs nothing from
them. **WAITING ON ANOTHER TASK** is sequenced behind an open row (`blockedBy`).
**DONE** collapses to a row of ids. Under a batch or domain grouping these become
the glyph and the summary line rather than the sections.

## When they want more than the table

The table is a status surface, not a record. For descriptions and provenance,
generate a ledger instead and hand over the path, because that content cannot fit
the height cap and should not try. One overflow is different: when the rows that
overflow are OWNER-GATED decisions, the route is /decision-wizard, not a ledger
file. A decision queue is answered, not read
(rules/owner-decisions-go-through-a-wizard.md):

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
  key set at creation time. The plumbing is built and proven (task-table.sh reads
  metadata.class / domain / batch / blocked_on / verified / board_card), but only
  tasks created WITH that metadata populate the columns. Set it at TaskCreate time,
  or with `task.sh`, going forward.
- **An empty store says so loudly** (`!! EMPTY STORE`), because a resumed
  session's tasks live in the store that CREATED them, and the empty own-store is
  the usual wrong answer (vb-fable, 2026-08-18).
