---
name: quiz
description: Makes the owner think through the hard parts of agent-built work (spec, plan, diff, app, feature, analysis, deck, docs). Optionally writes a plain explainer first, then asks about 6 nuance questions, some worked out from the code, each followed by a terse explanation, right or wrong. Use when the owner has lost the feel of what was built or wants to understand something they did not write.
allowed-tools: Read, Glob, Grep, Bash, Write, Agent, Monitor, mcp__inputs__wizard, mcp__inputs__pick_one, mcp__inputs__confirm
user-invocable: true
argument-hint: "<path | git range | PR | url> [--explain] [--kind K] [--page] [--fresh] [--rounds N]"
---

## Brief

A quiz about an artifact instead of a read of it. The owner gave the requirement
and knows how the result should behave, but did not write it, so reading it cold
is slow and leaves gaps they cannot see. Being asked about it, a few questions at
a time, finds those gaps and opens exactly the part of the artifact that fills
each one.

The goal is the feel of the work, not recall. Owner, 2026-11-03: "push me to think
and even look up in the code if needed ... whatever works that lets me figure out
the hard parts without being a mammoth homework". A wrong answer costs nothing and
is often where the understanding starts.

The agent writes the chunk map and the questions. Everything else (linting,
rendering, grading, the record) is `~/.claude/scripts/quiz/quiz.py`, which never
calls a model. Plan and reasoning:
`~/.claude/assets/reports/20261024-quiz-skill/plan.md`

## Step 0

Read `~/.claude/skills/GUIDELINES.md` and this skill's `runtime-notes.md` if present.

## Usage

```
/quiz <path | git range | PR | url>   explainer if wanted → map → round → grade → map out
  --explain     write the plain explainer first (section 0)
  --kind K      spec | plan | code-change | app | feature | analysis | presentation | docs
  --page        rounds go on a decision page (answer later, or images)
  --fresh       a sonnet fork builds the map cold, for a reader that did not build it
  --rounds N    stop after N rounds (default 2, about 6 questions and 10 minutes)
```

## 0. The explainer (optional)

Write it when `--explain` is passed, or when the owner says they are lost. If a
plain doc already exists, name it and skip this. Otherwise offer it in one line when
the artifact is code or a feature.

One page, in plain sentences, with no vague words. Sections, in this order:

1. The situation before this work.
2. The ask, quoted, and your read of it, including where you departed from it and why.
3. The changes, and what is left before it is live.
4. How a person uses the result, as worked examples with real names and numbers.
5. Known limits.

Worked model: `winhere-pim/docs/016-info-export-builder-explained.md`. Save it in the
project's docs if it belongs there, otherwise in the record folder. Say the path, let
the owner read at their pace, and start when they say go. The doc orients; the quiz
goes past it, so never key a question on a sentence the doc states outright.

## 1. Inputs

1. Resolve the artifact to files on disk: a path, the files a git range or PR
   touches (read at HEAD), the doc set, or for an app, screenshots saved into the
   record folder plus the routes.
2. Detect the kind from the path and the first 40 lines and headings; `--kind`
   overrides. Pick; do not ask (`rules/refusal-is-not-a-fix.md`).
3. Load the owner's original ask: the goal record (`gs`), the session's first
   message, or the brief the artifact was built from. Quote it.
4. Reuse explaining output that already exists: `/summarize-changes`, a
   `/feature-doc-set` review contract, `DECK.md`, `review.md`.
5. `quiz.py init --artifact <ref> --kind <k> --path <file> ... --ask "<quoted ask>"`
   prints the record folder. Pass every file the quiz reads as `--path`: they feed
   the change hash, and without them `check` fails because an edited artifact
   could not be detected.

## 2. The map

Write `quiz.json` in the record folder. Chunks are what the owner needs to hold,
one per section, step, behaviour, screen, contract row, claim or slide (table in
the plan, "How a quiz is generated from each artifact kind"):

```jsonc
"chunks": [{ "id": "c1", "title": "Backoff", "depends_on": [],
  "claims": [{ "id": "c1.1", "text": "Jobs retry three times.",
    "key_phrase": "retry three times",            // must appear in the slice
    "slice": { "path": "/abs/spec.md", "lines": [4, 5] } }] }],   // or "anchor": "Heading" (markdown only), or "image": "/abs/shot.png"
"questions": [{ "id": "q1", "round": 1, "chunk": "c1", "claim": "c1.1",
  "type": "which-is-true", "requirement": true,
  "stem": "...", "options": [{ "code": "a", "label": "..." }, ...],
  "key": "b", "why": "one sentence: why the key is right",
  "wrong": { "a": "one sentence: what a gets wrong" } }]
```

Rules for the questions:

1. **Round 1 carries one requirement question** built from the owner's ask:
   which requirement this satisfies, and which it does not. `check` refuses a
   round 1 without one.
2. **Distractors are true-sounding and false**, never nonsense. Each one is a
   mistake a smart reader would make, such as the obvious design that was rejected.
3. **Every question is keyed on a claim with a slice.** A question with no slice
   is cut. Prefer behaviour questions ("input X now gives what?") over recall.
4. **Latency:** write round 1 from the first two chunks, render and fire it, and
   write the rest of the map while the owner answers.
5. The session that holds the artifact writes the questions. Never a cheap model
   lane: a wrong key teaches the owner a false fact they cannot detect.
6. **Ask the hard parts first, and only those.** Pick chunks by what the owner would
   get wrong by assuming: a trade-off, a rejected obvious approach, a surprising
   consequence, a failure mode, a place the result departs from the ask. Cut anything
   a person could answer by remembering a name, count or path.
7. **Make them reason.** Set a concrete situation and ask what happens or which choice
   holds: "A customer's price column is renamed next month. What happens to the saved
   export?" The answer should follow from understanding, not from having read a line.
8. **At least one question per round sends them to the source.** Give it a `look`:
   `{ "path": "/abs/file.ts", "lines": [40, 60], "hint": "how the columns are stored" }`.
   Keep it under about 20 lines of reading, and never point at the line that states
   the key. It is optional to follow; a guess is fine.
9. **Every answer cites the code.** Right or wrong, the owner gets `path:line` for
   the claim, and that citation is often what teaches most. A pointer need not be
   hyper-specific. Name the file and lines inside `why` or `catch` too when a second
   place matters, such as the test that pins the behaviour.
10. **Teach the words too.** Include at least one definitional or ontological
   question in a run: what a domain term means here, what kind of thing it is (a real
   trade concept, a field in this codebase, or just an example), whose data it is, and
   what it is not. Spell out an acronym in the stem. The owner did not write this
   vocabulary, so never assume it. Ask what the word implies, not a bare ABCD
   definition: "a rotor is sold plain and coated; how many catalog rows is that?"
11. **Feedback is terse.** `why` and each `wrong` line are one sentence, at most 240
   characters. Add a `catch` where it earns its place: the nuance even a right answer
   can miss. It prints right or wrong. Use it to give the feel, not a second lesson.

Run `quiz.py check <dir>` until `READY`. It confirms every key is an option,
every wrong option has its line, every slice still contains its key phrase, and
the ids, rounds and chunks agree. It cannot tell whether a key is actually
right; that rests on the question writer reading the slice.

## 3. Asking

- Text round: `quiz.py render <dir> --round N` prints the arguments for
  `mcp__inputs__wizard`, one step per question, each with a `?` "not sure"
  option so a guess does not read as understanding. Pass them through unchanged,
  then grade with `q1=<pick>` per step. If that tool is not available, ask through
  AskUserQuestion with the same stems, options and `?`, four questions at most per call.
- One retry question: `mcp__inputs__pick_one` with the same options.
- Image or a code block over about 12 lines, or `--page`: `quiz.py render <dir>
  --round N --surface page` gives a decision page config. Scaffold it with
  `decision-page.sh new quiz-<slug>-rN`, write the config, `decision-page.sh check`,
  and arm the answer watcher in the same turn (`/decision-wizard` step 5). The
  page's recommended option is a neutral `x` "answer below", so nothing leaks the
  key. Pass the submitted answer string's tokens straight to `grade` (`Q1b Q2x`);
  `x` means left untouched and is reported as unanswered, never as a miss.

A decision page may hold a whole run as one round of up to six, since the owner
answers it at their own pace. Otherwise, three questions per round, two rounds by default. Stop there and offer more in one
line; never run until every chunk is asked. Between rounds the owner may say `skip`,
`stop`, or `more on <chunk>`. A cancelled wizard still grades what was answered.

## 4. Grading

`quiz.py grade <dir> q1=b q2=a ...` records the picks and prints the result:
a right pick gets its `why`; a wrong pick gets its `wrong` line, the answer and
`why`, and the slice read from disk now (first 6 lines). Either way any `catch`
follows. Relay that output to the owner as it is, one question at a time, with no
praise and no added lecture. If the artifact changed since the map, grading stops with
exit 3: remap the changed chunks, `quiz.py check`, then `quiz.py hash <dir> --accept`.

An unknown code or an already-answered question is refused and nothing is
recorded. A retry is always a new question.

`quiz.py retry <dir>` lists chunks missed once. Each gets one more question in
the next round from an unused claim of the same chunk. Missed twice, the chunk is
marked missed and the quiz moves on.

## 5. The map out

`quiz.py report <dir>` writes and prints `map.md`: held (never wrong), shaky
(wrong before, right last), retry due (wrong once), missed (wrong twice), and up
to three slices to read, each the one behind the question actually missed, ranked by
how many chunks depend on them. No percentage. Show it in full. If a workspace
notes file is open, add one line pointing at the record folder.

A later `/quiz` on the same artifact offers "retest the missed chunks only" when
a record with the same `artifact.ref` exists under `~/.claude/assets/quizzes/`
(find it with `rg -l '"ref": "<ref>"' ~/.claude/assets/quizzes`; the script has no
lookup command yet).

## Boundaries

Never publishes anything. Never changes the decision page template or the inputs
MCP. Never uses a cheap lane for question content. Never spawns an agent except
`--fresh`, which is read-only, pinned to sonnet, and follows
`rules/subagent-dispatch-prompt.md`. Never keys a question on a claim without a
slice.

## Validation

Efficacy dimension: the owner's read of the artifact improved.
Checks, each from the run's own records:
1. Every question's slice still contains its claim's key phrase: `quiz.py check`
   prints `READY` on the final `quiz.json`.
2. The first question fired within one model turn of invocation (the WAL action gap).
3. On a re-run against the same artifact, missed chunks are asked first and the
   map shows them moving to held.
4. Each round has a question with a `look`, and no run exceeds its rounds unless the
   owner asked for more (`quiz.json`).

## Ledger

When a run taught something, write the entry to a file (heading
`## quiz: <what this run did> · YYYY-MM-DD HH:MM`, no trailing `---`) and run
`bash ~/.claude/skills/shared/prepend-runtime-note.sh quiz <entry-file>`. Then
`bash ~/.claude/scripts/skill-log.sh record quiz --outcome unknown --note "record=<dir>"`.
