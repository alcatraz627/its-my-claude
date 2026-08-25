# API, CLI and interface simplification: the evidence, open

Opened 2026-08-26 at the owner's instruction: collect real usage friction from
agents who actually drive the kanban board and `/tasks`, and turn it into a
simplification pass to consider later.

**Status: collecting.** Four agents were asked on 2026-08-26 and their answers
arrive asynchronously. Nothing here is a recommendation yet; the seeded
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

_None yet. Each reply gets a subsection here, verbatim, with the agent named._

## What this report is not

Not a plan. The owner's standing bar applies: benefit against code churn,
testing and feedback cost, on a personal project. A simplification that
rewrites working surfaces for elegance fails that bar the same way the pruned
decision-primitive merge did.
