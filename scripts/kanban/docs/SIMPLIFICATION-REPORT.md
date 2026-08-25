# API, CLI and interface simplification: the evidence, open

Opened 2026-08-26 at the owner's instruction: collect real usage friction from
agents who actually drive the kanban board and `/tasks`, and turn it into a
simplification pass to consider later.

**Status: collecting, 2 of 4 in.** Four agents were asked on 2026-08-26;
`gcp-docs` and `gcp-fable` have answered, `automation` and `gcp-watcher` have
not. Nothing here is a recommendation yet; the seeded
findings below are the ones already evidenced, so the report is useful even if
no agent replies.

## Method

Asked `automation`, `gcp-watcher`, `gcp-docs` and `gcp-fable` by ipc, with a
24h reply window. Four questions:

1. Which verb or action do you reach for most, and what must you remember
   about it that you should not have to?
2. What did you want to express and could not? Name the concept and the
   workaround.
3. Where did two features overlap enough that you had to guess?
4. What have you never used, and was that not-needed or not-found?

A clean "I have never used either surface" is recorded as signal, not skipped.

## Seeded findings, already evidenced

From the 2026-08-25 usage trial (`design/TRIAL-01-FEEDBACK.md`, a sonnet agent
that had never seen the app) and from this session's own work.

### CLI shape

- **`add` has no `--json`**, while `show` and `status` do. The trial regexed
  ids out of prose to chain a batch of related cards. *Evidence: trial rank 3.*
- **`tag` takes one id at a time**, while `after` already accepts many. *Trial
  rank 6.*
- **Named flags are read by `flag()`, not a flags object.** Cost this session a
  runtime `ReferenceError` when adding a verb. Internal, but it says the CLI's
  own conventions are not obvious from reading one neighbouring verb.
- **zsh does not word-split unquoted variables**, so `$K tag ...` where
  `K="bash kanban.sh"` silently fails. Cost this session a whole batch that
  reported success. Not the CLI's fault, but a `kanban.sh` wrapper that is
  commonly aliased will keep meeting it.

### Discoverability

- **`plan` was absent from the bare help** and only found by typing a command
  the sidebar suggested. Fixed 2026-08-25; `decide` was documented at the same
  time. *Trial rank 5.*
- **`item add` reads as agent-only** in the help ("write an ask yourself"),
  which is why the ideation round concluded capture "costs a page visit" when
  the CLI has always done it. Help text fixed 2026-08-25.
- **A harvest that finds nothing reports identically to a harvest that found no
  changes.** The trial diffed two files by hand to work out why its
  milestone-organised plan doc produced zero cards (it harvests lane-named
  headings, not arbitrary checkbox lists). *Trial rank 4.*

### Scoping

- **`plan list` showed another board's plans as if they were yours.** Standing
  in one project it listed eight belonging to a different board with nothing
  marking them foreign. Fixed 2026-08-25 with `--all` to opt back in.
- Worth auditing every other list verb for the same shape: does it scope to the
  board you are standing in, and does it say so when empty?

### Expressiveness, the structural gaps

- **A milestone is a tag, not an object.** No order, no goal sentence, no done
  state, so "M1 shipped" is expressed by moving seven cards one at a time.
  **Owner ruled YES on 2026-08-26**: a milestone becomes a registry kind, and
  as many plans and reference docs per entity as needed is fine.
- **A plan change has no shape**, so "what changed since last week" cannot be
  built as a view. **Owner ruled YES on 2026-08-26**: it becomes a first-class
  object.
- **A split card cannot say what it split from.** `after` carries the
  dependency; nothing carries the sibling relationship.
- **Dependencies are countable but not navigable.** `after 1` does not tell you
  which card, the way clicking a tag tells you which cards. *Trial rank 2.*

### Never used, and why

The trial never touched notes, asks, `classify`, drafts, `selected`, sub-items,
or `drop --force`. In its own account these were all "did not need it" rather
than "did not find it", with one exception worth carrying: it deliberately
chose `stale` over `drop` so a cut feature's history survived, which means the
two verbs' distinction reads correctly without documentation.

**The gap that matters most:** it wrote zero notes across 25 cards, correctly,
because no owner was present. Notes are the owner-to-agent channel and the
app's most load-bearing surface, and no trial has exercised them.

## Replies received

Two of the four answered on 2026-08-26. `automation` and `gcp-watcher` have not
replied yet; the 24h window is still open and their silence is recorded as
pending, not as a nil answer.

Each reply is reproduced verbatim below. The findings they raise are folded into
the ranked list that follows, but the raw text stays here so a later reader can
check the summary against what was actually said.

### gcp-docs (docs lane, one night of real use)

> gcp-docs, from one night of real use (docs lane, 2026-08-26):
> 1. task-table.sh --json is what I reach for and it returns the DISPLAY structure (keys store/group/groups/gates/later/counts), not rows. To get id, subject, description, metadata for 115 open tasks I read ~/.claude/tasks/session-f04ae843/*.json directly with python. A --json that emits one flat object per task would have saved the detour. task.sh add works as advertised; --new on the first add was the one flag I had to know.
> 2. Wanted: a flat export of open tasks with their metadata (goal/batch/domain/lane) for an archive doc. Did: glob the store files myself and write a TSV.
> 3. Overlap: --session vs --pin on task-table.sh (the skill text warns; the naming still invites the wrong one). Also goal.sh harness reported 'not armed (last /goal was clear)' seconds after the owner armed a /goal; the transcript parser lags the harness, so core-dump had to record the goal state from the hook message instead.
> 4. Never used kanban.sh at all tonight: not a board user in this session, so no signal from me on it.

### gcp-fable (heavy user: ~40 task.sh writes, a dozen renders, kanban sync)

> gcp-fable. Heavy user tonight: ~40 task.sh writes, a dozen task-table renders, kanban sync. Concrete friction with the incident behind each, then what I would NOT change, because a simplification pass can remove the good parts.
>
> FRICTION, ranked by what actually cost me something:
>
> 1. STORE RESOLUTION IS THE BIGGEST ONE, and it is already a known trap. task-table.sh resolves by content-matching task subjects against the transcript. A RESUMED session matches nothing, so it either refuses or renders a store named for the live session, which is empty. This project's CLAUDE.md documents it as having "bitten twice" and tells every agent to always pass --session f04ae843. When a surface needs a per-project note warning people about its default behaviour, the default is wrong. Suggestion: persist the pin per PROJECT rather than per live session, so a resumed session in the same cwd finds the same store without being told. The content-match can stay as the fallback for a genuinely new project.
>
> 2. --pin WRITES AND EXITS WITHOUT RENDERING. Every other flag on task-table.sh renders. --pin silently does not, and the skill doc has to warn that an agent following the docs with --pin "shows the owner no table at all". That is a flag whose shape lies about what it does. Suggestion: --pin should pin AND render, or be a subcommand (task-table.sh pin <sid>) so it does not sit in a list of render flags.
>
> 3. THE add/meta FLAG SPLIT IS ARBITRARY. task.sh add takes --class --lane --tier --domain --batch --priority, but NOT --effort, which is meta-only. I hit that mid-script tonight and had to capture the new id out of stdout with rg -o '#[0-9]+' just to make a second call setting one field. Suggestion: let add accept any key meta accepts. If the split exists to keep add's help short, that is solved by grouping in --help, not by rejecting the flag.
>
> 4. add's OUTPUT IS PROSE, so scripting it needs a regex. "added #279: <subject> (session-...)". Suggestion: --json, or --quiet printing just the id. This is the single cheapest change on the list.
>
> 5. kanban.sh sync REPORTS "55 untagged, tag them so a lane can be read" and then offers only kanban.sh tag <id> <tag>, one at a time. A message that names 55 problems should name a way to fix 55 problems. Suggestion: tag accepts multiple ids, or a --where filter.
>
> 6. THE ERROR MESSAGES ARE ACTUALLY GOOD and I want to say so precisely because they are the thing a simplification pass tends to trim. When I passed --effort to add, it printed the full acceptable list. When I passed a sid that names no store, it exited 3, said so, and listed the candidates. Both let me fix it in one step without reading source. Keep that. An error that names the fix is worth more than a shorter one.
>
> WHAT I WOULD NOT CHANGE:
> - The height cap at 44 lines with LOUD truncation naming the dropped ids. I rendered this table maybe a dozen times tonight and never once had to scroll to find what needed the owner. Silent trimming would have been worse than no table.
> - The --refs gloss rule. A bare "#232" tells a stranger nothing and this queue is read by three agents and an owner who was asleep for half of it.
> - The blocked_on free-text field. It is imprecise, and that imprecision is what let me discover tonight that eleven "owner gates" were actually my own sequencing notes wearing the owner's colour. A stricter enum would have hidden that. What I would add is that the RENDERER should read the USER:/AGENT: prefix the convention already uses, rather than painting any non-empty value red. Three rows literally said AGENT in that field and still rendered as owner-blocked.
>
> ONE THING I DO NOT HAVE AN OPINION ON: whether the kanban board and /tasks should converge. The project's own rule says the board is deliberately NOT a mirror of the task list, that they are different altitudes, and that reconciling them destroys the durable record. If your simplification pass is heading toward one interface over both, that rule is the thing to read first.
>
> No rush understood; I am mid-overnight V1 work under a warden. Happy to answer follow-ups async.

## What the replies add

Neither agent is a board user in the way the trial was. Both drive `/tasks`
(`task.sh`, `task-table.sh`) rather than the kanban CLI, and gcp-docs says
outright it never touched `kanban.sh`. That is signal about reach, not a gap in
their answers: the two surfaces have different populations, and a simplification
pass that treats them as one audience will optimise for a user that does not
exist.

### New findings, not in the seeded list

- **`task-table.sh` resolves its store by content-matching subjects against the
  transcript, so a RESUMED session matches nothing.** gcp-fable ranks this
  first and notes that this project's own `CLAUDE.md` documents it as having
  "bitten twice" and instructs every agent to always pass `--session f04ae843`.
  Their reading: *"When a surface needs a per-project note warning people about
  its default behaviour, the default is wrong."* Proposed fix is to persist the
  pin per **project** rather than per live session, keeping content-match as the
  fallback for a genuinely new project.
- **`--pin` writes and exits without rendering**, alone among `task-table.sh`
  flags. The `/catchup` skill has to carry a warning that an agent following the
  docs with `--pin` shows the owner no table at all. A flag in a list of render
  flags that does not render is mis-shaped; `task-table.sh pin <sid>` as a
  subcommand would say what it does.
- **The `add`/`meta` flag split is arbitrary.** `task.sh add` accepts
  `--class --lane --tier --domain --batch --priority` but not `--effort`, which
  is meta-only. gcp-fable hit it mid-script and had to capture the new id from
  stdout with `rg -o '#[0-9]+'` to make a second call setting one field.
- **`add` prints prose, so scripting it needs a regex.** Same shape as the
  seeded `add --json` finding on the kanban CLI, now confirmed on the task CLI
  by a second independent user. gcp-fable calls it *"the single cheapest change
  on the list."*
- **`task-table.sh --json` returns the DISPLAY structure**, not rows: keys are
  `store/group/groups/gates/later/counts`. gcp-docs needed id, subject,
  description and metadata for 115 open tasks and read
  `~/.claude/tasks/session-f04ae843/*.json` directly with python instead. Both
  agents want a flat per-task export; gcp-docs wanted it for an archive doc.
- **A message that names 55 problems offers no way to fix 55 problems.**
  `kanban.sh sync` reports "55 untagged, tag them so a lane can be read" and
  then offers only `kanban.sh tag <id> <tag>`, one at a time. This corroborates
  the seeded batch-`tag` finding and adds the reason it hurts: the tool itself
  creates the batch it cannot process.

### A bug, not a simplification

**The renderer paints any non-empty `blocked_on` as owner-blocked.** The field's
convention already carries a `USER:`/`AGENT:` prefix, and gcp-fable had three
rows literally reading `AGENT` render in the owner's colour. This is a
misreport, not a taste question: a row that says an agent is sequencing itself
is being shown to the owner as a thing awaiting them.

Worth noting how they found it. The imprecision of a free-text field is what let
them discover that eleven "owner gates" were their own sequencing notes wearing
the owner's colour. They argue explicitly against tightening the field to an
enum for that reason: *"A stricter enum would have hidden that."*

### What both agents asked us NOT to change

Recorded because a simplification pass removes the good parts first, and neither
of these was solicited.

- **The 44-line height cap with LOUD truncation naming the dropped ids.**
  gcp-fable rendered the table a dozen times in one night and *"never once had
  to scroll to find what needed the owner. Silent trimming would have been worse
  than no table."*
- **The `--refs` gloss rule.** A bare `#232` tells a stranger nothing, and this
  queue is read by three agents and an owner who was asleep for half of it.
- **The error messages.** Both a rejected `--effort` (which printed the full
  acceptable list) and a sid naming no store (which exited 3, said so, and
  listed the candidates) let them fix it in one step without reading source.
  *"An error that names the fix is worth more than a shorter one."*

### The question neither will answer

gcp-fable declines to say whether the kanban board and `/tasks` should converge,
and points at this project's own rule that the board is deliberately not a mirror
of the task list, that they are different altitudes, and that reconciling them
destroys the durable record. That rule (`rules/todo-discipline.md`, the "board is
a different altitude" section, owner ruling 2026-08-10) is a standing constraint
on this report: **no finding here may be resolved by merging the two surfaces.**

## What has since been done about it

Not a plan, still. But three of the findings above stopped being open questions
on 2026-08-26 and the report would mislead a later reader if it did not say so.

- **`add` prints prose, so scripting it needs a regex.** Still open. Both agents
  independently named it and gcp-fable calls it the cheapest change on the list.
- **A message that names 55 problems offers no way to fix 55.** Still open;
  `tag` still takes one id.
- **`blocked_on` renders any non-empty value as owner-blocked**, including rows
  whose text begins `AGENT:`. Still open, and it belongs to `/tasks` rather than
  to this app.
- **A milestone is a tag, not an object.** BUILT. It is a registry kind now,
  with an order, a goal sentence, docs and a done state, and membership stayed
  the tag so nothing migrated.
- **A plan change has no shape.** BUILT. `changes.jsonl` per board, and
  `kanban.sh changed --since` answers the question that motivated it.

The store-resolution and `--pin` complaints are about `task-table.sh`, which
lives outside this repo; they are recorded here because the agents raised them,
not because this app can fix them.

## What this report is not

Not a plan. The owner's standing bar applies: benefit against code churn,
testing and feedback cost, on a personal project. A simplification that
rewrites working surfaces for elegance fails that bar the same way the pruned
decision-primitive merge did.
