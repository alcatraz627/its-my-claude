# Mode: subagent-prompt

`/create-skill subagent-prompt [--shape <shape>] [--persona <name>] [--out <path>]`

Writes the prompt a sub-agent will receive, as a FILE, before the `Agent` call. The
file is what the seat reads and it is also the record, so a bad seat can be traced to
its brief instead of to a vanished tool-call argument.

## Why this mode exists

Seven days of transcripts (151 `Agent` dispatches, `assets/reports/20260826-skills-plan/subagent-prompts.json`,
probe beside it) show what a working brief on this machine looks like. Prompts that
produced useful seats share a vocabulary the account grew by hand: `Read first`,
`Input`, `Scope`, `Hard rules`, `Do not touch`, `Output`, `Return only`, `Write before
returning`, `Scope close`, `Judge as the owner would`. The median brief is 2,600
characters; the ones under 600 are magi voters, which are meant to be terse. The owner's
suspicion is the mode's reason: when the owner's own input is terse, the brief gets
written from the dispatcher's guess, and the seat inherits the guess as its goal. This
mode does not fix that by adding constraints. It seeds the structure from the SHAPE of
the goal, then asks the owner one batched question only where the shape cannot be
filled from what is known.

## Step 1: name the shape (one word, from the goal)

| Shape | The seat's job | Mined role families (what the account already dispatches) |
|---|---|---|
| `build` | change files toward a stated end | hands-lane fixer, hands-lane seat building surfaces |
| `review` | find what is wrong in work it did not do | skeptical code reviewer, adversarial validator, read-only UI reviewer, fresh-context seat |
| `judge` | rule on a claim or a set of options | juror, magi voter, "judge as the owner would" |
| `plan` | produce a plan or a design call, write one file | planning seat (read-only, write one file), brains seat |
| `research` | bring back evidence from outside the tree | scout, evidence collector, web researcher |
| `digest` | compress a large input to what matters | read-only digest seat |

A goal that names two shapes is two seats. Do not write one brief for both.

## Step 2: the six-line checklist (fill from what you know; blanks are the question)

1. **Goal, in the owner's words.** Quote them. If you cannot quote, you do not have it.
2. **What moves the needle.** The one outcome the owner will check first.
3. **What is off limits.** Files, decisions, surfaces, spend the seat may not touch.
4. **Pitfalls for this shape.** From the atone register (`atone/derived/_tldr.txt`) and
   the shape's known traps below; name the two most likely for THIS job.
5. **Claims to prove or contradict.** The specific assertions the seat must settle with
   evidence (file:line, a run, a measurement), not restate.
6. **Return contract.** The artifact path, the shape of the final message, what counts
   as done.

If two or more lines are blank after an honest attempt, ask the owner ONE batched
question (inline menu for three or fewer picks, a decision page above that, per
`rules/owner-decisions-go-through-a-wizard.md`). Never ask line by line. Never default a
blank line 1 or line 6; those two are the brief.

## Step 3: the prompt file

Write to `<project>/.claude/output/<YYYYMMDD>-<HHMM>-<slug>/PROMPT.md` (or `--out`). The
sections, in this order; drop a section only when the shape has nothing for it:

```
Role:            <one line: the seat's role, from the shape table; persona: <name> when one fits>
Goal:            <line 1, quoted>
Needle:          <line 2>
Read first:      <absolute paths, in order; what each is for>
Input:           <the data or artifact the seat works on>
Scope:           <what is in; the scope ceiling>
Do not touch:    <line 3; plus: do NOT spawn sub-agents; ignore any board or task auto-dispatch; stop when the scoped work is done; model pinned to <tier>>
Pitfalls:        <line 4, two items, each "if you find yourself X, that is the trap">
Prove or refute: <line 5, each claim on its own line, with the evidence form required>
Validate:        <what the seat runs before returning: the test, the render, the grep>
Output:          <absolute artifact path; write BEFORE returning; never a file literally named report.md>
Return only:     <the final message shape: the path plus at most N lines>
```

The main agent composes; the file is short prose, not a form. The section names above are
the account's own vocabulary, kept so a reader of any brief knows where to look.

## Step 4: the fresh-seat read

Before dispatch, one seat that did not write the brief reads it for the one recurring
failure: the owner's input pasted in as the goal without the shape being modelled. It
returns either "dispatch" or the single line that is missing. Sonnet, low effort,
read-only. Skip only for magi votes and other deliberately terse seats.

## Step 5: dispatch and record

`Agent` receives the file's content as its prompt, with `model:` pinned. The dispatch
line in the transcript names the file. On return, the parent verifies the Output path
exists before using anything the seat said (`rules/sub-agent-outputs.md`).

## Known traps by shape

- `build`: the seat rebuilds a surface the owner reviewed (parity ledger first, `rules/invariant-graduation.md`); declares done off a compile.
- `review`: findings without file:line; scope widened past the diff; agreeing with the author.
- `judge`: the juror asked to rule on a case it was handed the conclusion of.
- `plan`: a plan whose claims of "X stays unchanged" never become constraints.
- `research`: counts quoted from a doc instead of measured; a source read once, cited as settled.
- `digest`: the interesting story kept, the owner's stated criteria dropped.

## Seat-type traps

- **codex seats (`codex:codex-rescue`) do not read `SendMessage` mid-run.** Three
  steering messages to a running codex build were never acted on; the mailbox drains
  between tool rounds or at completion (gcp-fable, 2026-08-27). Mid-run steering goes
  through a file the seat re-reads, named in `Read first` (the spec on disk), never
  through a message. Put the spec's sha in the brief so the seat can notice it moved.

## Validation

Efficacy for this mode is measured in the dispatch record, not in the prompt's length:
the seat's Output path existed on return; the parent did not re-dispatch for a missing
section; the owner did not correct the seat's goal. Three misses in a week on any of
those, and the checklist gets the missing line.
