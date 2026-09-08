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

## The shape (ruled 2026-09-04 and 2026-09-05; every /tasks run, every session)

Each goal is its title in plain text over a closed box with a rail down its left
edge (a one-row goal is the title and the row, no box). The ball leading the
title answers one question: can this goal continue WITHOUT the owner. The emoji
beside it identifies the goal and never moves when the ball does. A rendered store, as
the tool prints a five-row fixture (two goals, a gate, a running row, one in
review, one deferred), which unlike a live-store snapshot does not go stale:

```
TASKS  session-skillfx1  ·  🎯 armed, on the /goal line below  ·  🟢 2 goal tags, 0 met  ·  🏁 0 of 3 milestones  ·  🔴 1 need you  ·  1 running
  store session-skillfx1, found by the --session you passed  ·  grouped by goal, then batch, auto, 100% of open rows carry it
/goal A teammate ships one workbook through the console alone

⚡ CLEAR NOW   1 of 1 waiting on you, across 1 goal and 1 lane
   1  #1    Rule on the notes-and-asks redesign
                ▸ do    open the decision page and rule

🔴 · 📋  The owner sees every decision he owes on one page
╭▏───────────────────────────────────────────────────────────────────────────────────  ·  0m
│  ▱▱▱▱▱▱▱▱▱▱  0 of 1 milestone   ·   next: DEC
│
│  ▸ DEC
│    ─────
│    🔴 ! #1    Rule on the notes-and-asks redesign
│         ◆ owner ◇ opus   ▪ decide ▫ kanban   » USER: open the decision page and rule
│    🔵 ▶ #2    Force the Decisions group open when any decision is pending
│         ◆ hands ◇ sonnet ▪ build  ▫ kanban
│    🟠 ~ #3    Board tab title carries the pending count
│         ◆ hands ◇ sonnet ▪ build  ▫ kanban   » after #2
╰▏

🟣 · 🏭  A person drives the job page end to end without stumbling  ·  0m
     🟣 = #4    Skeleton for the parts table while it loads
          ◆ hands ◇ opus   ▪ ui     ▫ forge    » PR open, awaiting a peer read

💤 · 💤  later · deferred, or after V1  ·  0m
     💤 z #5    Export XLSX rich formatting, the rest of it
          ◆ hands ◇ sonnet ▪ build  ▫ forge    » out of scope for v1 by decision
  🔴 needs you (!)   🟠 after a task (~)   🔵 running (▶)   🟣 in review (=)   💤 deferred (z)
  ─────────────────────────────────────────────────────────────────────────────────────────
  ◆ lane   ◇ tier   ▪ kind   ▫ domain   »  note, shown only when it changes what you do   ·   the emoji beside a box's ball is that goal's badge   ·   height 33/44   ·   -h for flags
```

What the pieces mean:

- **Header.** `🎯 armed, on the /goal line below` (or `no /goal armed`), then `N
  goal tags, M met` and `🏁 closed of total milestones`. His goal itself rides
  its own `/goal <text>` line under the provenance line, whole, wrapped with the
  continuation at column 0 and nothing else on it, so he can select and paste it
  (owner ruling unblock-0908 D2b, 2026-09-08; the Q7a clip at 96 chars cut goals
  at their second promise). Goals are what the owner measures, never task counts ("I CARE
  ABOUT GOALS BEING DONE AGAINST THEIR MEANINGFUL BEHAVIORIAL INDENDED CHANGE; be
  it 3 tasks or 30 tasks"). The count says "goal tags" because it counts the
  `metadata.goal` strings on rows, which are not his armed goal: on 2026-09-08 the
  header read "1 goal, 0 met" about a tag the owner had already retired, beside
  the goal he had just armed. When the two differ, relocate the open rows under
  the armed goal's text; the old tag keeps its done rows and reads as met.
  `🔴 N need you` counts every owner gate, in the legend's own words. Owner ruling
  Q1a, 2026-09-05: every `USER:` gate reaches CLEAR NOW, capped at three with the
  rest counted; the steer/errand split is gone. A gate's do-line is a declared
  closer when it has one and otherwise the owner's own prose after `USER:`.
- **Goal box.** The title first, as plain text: `<ball> · <emoji>  <title>`,
  wrapped with the continuation at column 0 and no rail glyph anywhere in it
  (owner, 2026-09-08: "the box around the goal makes it hard to copy paste it,
  no fancy characters between the terminal text flow"). Then the opening corner
  carrying the full-width rule and the age, `╭▏────  ·  <age>`, then the meter
  `▰▰▱▱ closed of total milestones · next: <milestone>`. Boxes are separated by
  one blank line. The box holding a gate renders first. **A goal with one row
  draws no box** (D3a, same ruling): its title line carries the age and the row
  follows without a rail, because six lines of chrome around one row hid seven
  rows on a small store in the turn the owner asked what was left.
- **Milestone band.** `▸ <name>` on the rail with a short rule under it. A
  milestone names a STATE ("Right now, …" parses true or false), never activity.
  A three-letter acronym is the floor for its name (owner, 2026-09-05).
- **Row.** `<ball> <twin> #id  subject`, then ONE trait line `◆ lane ◇ tier
  ▪ kind ▫ domain`, one trait per column, never stacked (D1 note, verbatim: "use
  column for one trait only (no stacking of lane / model / other tags in a single
  col)"). A note rides the trait line when it fits and drops to its own `»` line
  when it would be clipped to a stub. A row with no traits prints no trait line.
  There is NO blank line between rows; blanks sit under milestones and between
  boxes only (owner, 2026-09-05).
- **Nine states the tool draws, two channels each.** 🔴 `!` needs you · 🟠 `~`
  after a task · 🔵 `▶` running · 🟢 `○` ready · 🟣 `=` in review · 💤 `z`
  deferred · ⚪ `·` unassigned · 🤝 `@` delegated (handed to a peer, unconfirmed
  until it acknowledges) · ✅ `x` done. The seven RULED states (REDESIGN.md D7a)
  are the first seven plus done; `delegated` is a renderer distinction inside
  `active`. Colour is never load-bearing alone. The legend lists only the states
  present.
- **Delegated is written by the agent that dispatches, or it never shows.** The
  renderer reads `metadata.delegated_to`; nothing sets it for you. When you hand
  a row to a sub-agent or a peer, run `task.sh update <id> --delegated-to <agent>`
  in the same turn as the dispatch, and `--delegated-confirmed true` when the seat
  acknowledges (`--undelegate` if it never does). vb dispatched twelve seats on
  2026-09-05 and every one rendered as ready, because none carried the field
  (#55). Automatic writing from the dispatch hook is filed as
  prop-20260905-062648-5a.
- **UNFILED.** Rows with no goal land in their own loud box (D3b). A holding pen,
  not a home.
- **Footer.** Height `h/44`; when rows did not fit, the overflow line accuses the
  DATA with a measurement (median subject length, rows with no goal), never the
  tool.

Width is free. Height is a forcing function at 44: past it the render degrades
(notes collapse before traits; traits never drop) and then truncates loudly,
naming what it hid. `--detail` prints every line. Rulings and provenance:
`skills/tasks/REDESIGN.md` (the model, D1 through D7) and
`assets/reports/20260904-tasks-visual-variants/final.md` (the layout, rev 2).

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
3. Auto: the first of `goal`, `batch`, `domain`, `class` that at least 70% of open
   rows carry (`goal` gets `batch` as its sub-band); if none reaches the bar, the
   best-covered of them; if none is set at all, the actor split. The bar exists
   because "goal if any" once put 98 of 180 owner rows into one nameless band
   (2026-09-04). Rows without the chosen key land in UNFILED, loudly.

Whatever the grouping, the actor split is never lost: it rides as the row's ball
and ASCII twin (the seven states above) and as the CLEAR NOW band under the
header, which lists up to three owner gates with their do-lines and counts the
rest. Lane, tier, kind and domain
each keep their own trait column under the row.

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
task.sh close <id> --by "<the check, run or artifact>"   ·   task.sh start <id>   ·   task.sh meta <id> batch=B owner=me   ·   task.sh list
task.sh add "…" --origin asked|measured|inferred     # 🗣 the owner asked · 📏 a number or file:line behind it · 💭 an agent inferred it
task.sh goal <id|"goal text"> --direction "<🧭 the direction it serves>" --when "<✅ the check that closes it>"   # goal-level, once per goal, in <store>/.goals
```

**What a goal says about itself (P3, 2026-09-08).** A goal is a tag rows carry,
so its direction and its closing check have no row to sit on. `task.sh goal`
writes them once, keyed by the goal's text, and the table draws the 🧭 line
above the box (once for a run of boxes sharing it) and `✅ when:` under the
meter. Both are absent until set; `--json` carries them under `goals`. This is
the owner's own hierarchy, direction to goal to milestone to task, and it is
what answers the fourth question, what each row serves, at the level above the
row.

**The close rule.** Close a row when the work has landed, not when the edit is
made, and say what proved it: `close <id> --by "<the suite, the command, the
screenshot>"`. `--by true` means you ran it, `--by prod` means you saw it live,
`--by false` means nothing did, and then one clause says why the row closes
anyway. `done` still works and says aloud that no instrument was named; the
footer counts those rows, because check 9 (`scripts/alignment-checks`) reads
them: 361 of 379 closes in the week to 2026-09-08 named nothing.

**The round report.** After each round of work, one line to the owner in this
shape, and nothing else about the round: `<check or row> · <flip: what changed> ·
<mutation: what went red to prove it> · <suites: name and verdict>`. A round with
no mutation says "no mutation" in that slot rather than dropping it. Name the
suite and "green", not its pass count: five rows cited one suite at four
different counts inside twenty minutes on 2026-09-08, each true of a tree that
no longer existed.

Set `goal`, `batch`, `class`, `domain`, `lane`, `tier`, and `blocked_on` at
creation, whichever tool you use: this table groups, gates, and draws its trait
columns from metadata. A row with no goal lands in UNFILED; a gate is only a gate
when `blocked_on` says `USER:`; an unset tier is a loud `?` in the header; a row
with no traits prints no trait line at all.

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

**running** is in-progress work. **needs you** is anything gated on the owner (a
phrase, a review, a decision, their presence); every gate reaches CLEAR NOW (Q1a).
**ready** needs nothing from them. **after a task** is sequenced behind an open
row (`blockedBy`). **in review** is held short of done on purpose; **deferred** is
out of scope by decision. **done** collapses to a row of ids. Under any grouping
these are the row's ball and twin, never separate sections.

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

The renderer runs a ladder and never guesses (this list is the script's own,
`task-table.sh` "STORE RESOLUTION"; an earlier version of this section described
a newest-populated rung the script never had, and it misled a reader on
2026-09-08):

1. `--session <sid8>`: wins, or refuses with candidates. Never falls through.
2. The pin `--pin` wrote for this live session (`~/.claude/tasks-pins/<sid8>`).
3. `resolve-store.sh`, whose rungs are (`resolve-store.sh`, 2026-09-08): the
   store literally named for the session when it holds rows; the cached answer
   from an earlier run; a content match of task subjects against the transcript;
   the ONE populated store stamped with this project (`.project`), which is the
   project's queue whichever session created it; a refusal naming the stamped
   stores when two or more exist and the own store is empty; the empty own store
   when nothing is stamped at all; else a refusal. `~/.claude` itself is never
   resolved by stamp, because many unrelated streams keep stores there. The
   header says which rung answered (`found by the pin`, `found by project-stamp`,
   `found by content-match`), and `--explain` prints the rung on stderr.
4. Refuse, with the candidates and the two commands that pin one.

**On a refusal, pin the store before trusting any table.** Pass `--session` or
`--pin <sid8>`. A status surface showing the wrong status is worse than one
showing nothing, and this one has done it once. Stores carry their project in
`<store>/.project`, written by any `task.sh` write and by `--pin`, so the
project's view file is found from any shell directory.

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
- **Never generate.** Do not create board cards from tasks in bulk, and do not
  fold board state into the table. That is the collapse the ruling names. The
  one legal move is `task.sh to-board <id>`: a hand-moved row that leaves the
  store and closes here with the card id as its pointer. Owner extension of the
  2026-08-10 ruling, 2026-09-08: "relocation, not generation".

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
- **The goal band and the armed /goal may differ; no code reconciles them.**
  Owner ruling Q3c, 2026-09-05, verbatim: "Let the goal be nudged towards
  reconciling with the goal but allow it to be free-floating for local focus or
  external constraints, the agent should not be confused but in case I specify
  or ask for a goal it should not fight me just politely remind and reconcile."
  Read a band that names a local focus as intended. When the owner sets or asks
  for a goal, remind him in one line what the band says, then reconcile in his
  direction. Never argue. The fuller doctrine is in
  `rules/goal-statement-on-starting-work.md`.
