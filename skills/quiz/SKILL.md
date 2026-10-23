---
name: quiz
description: Quizzes the owner on an agent-built artifact (spec, plan, diff, app, feature, analysis, deck, docs) in rounds of three graded questions; a wrong answer opens the part that answers it, and a map of what held ends the run. Use when the owner wants to understand something they did not write.
allowed-tools: Read, Glob, Grep, Bash, Write, Agent, Monitor, mcp__inputs__wizard, mcp__inputs__pick_one, mcp__inputs__confirm
user-invocable: true
argument-hint: "<path | git range | PR | url> [--kind K] [--page] [--fresh] [--rounds N]"
---

## Brief

A quiz about an artifact instead of a read of it. The owner gave the requirement
and knows how the result should behave, but did not write it, so reading it cold
is slow and leaves gaps they cannot see. Being asked about it, a few questions at
a time, finds those gaps and opens exactly the part of the artifact that fills
each one.

The agent writes the chunk map and the questions. Everything else (linting,
rendering, grading, the record) is `~/.claude/scripts/quiz/quiz.py`, which never
calls a model. Plan and reasoning:
`~/.claude/assets/reports/20261024-quiz-skill/plan.md`

## Step 0

Read `~/.claude/skills/GUIDELINES.md` and this skill's `runtime-notes.md` if present.

## Usage

```
/quiz <path | git range | PR | url>   map → round 1 → grade → more rounds → map out
  --kind K      spec | plan | code-change | app | feature | analysis | presentation | docs
  --page        rounds go on a decision page (answer later, or images)
  --fresh       a sonnet fork builds the map cold, for a reader that did not build it
  --rounds N    stop after N rounds (default: until every chunk is asked)
```

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
2. **Distractors are true-sounding and false**, never nonsense.
3. **Every question is keyed on a claim with a slice.** A question with no slice
   is cut. Prefer behaviour questions ("input X now gives what?") over recall.
4. **Latency:** write round 1 from the first two chunks, render and fire it, and
   write the rest of the map while the owner answers.
5. The session that holds the artifact writes the questions. Never a cheap model
   lane: a wrong key teaches the owner a false fact they cannot detect.

Run `quiz.py check <dir>` until `READY`. It confirms every key is an option,
every wrong option has its line, every slice still contains its key phrase, and
the ids, rounds and chunks agree. It cannot tell whether a key is actually
right; that rests on the question writer reading the slice.

## 3. Asking

- Text round: `quiz.py render <dir> --round N` prints the arguments for
  `mcp__inputs__wizard`, one step per question, each with a `?` "not sure"
  option so a guess does not read as understanding. Pass them through unchanged,
  then grade with `q1=<pick>` per step.
- One retry question: `mcp__inputs__pick_one` with the same options.
- Image or a code block over about 12 lines, or `--page`: `quiz.py render <dir>
  --round N --surface page` gives a decision page config. Scaffold it with
  `decision-page.sh new quiz-<slug>-rN`, write the config, `decision-page.sh check`,
  and arm the answer watcher in the same turn (`/decision-wizard` step 5). The
  page's recommended option is a neutral `x` "answer below", so nothing leaks the
  key. Pass the submitted answer string's tokens straight to `grade` (`Q1b Q2x`);
  `x` means left untouched and is reported as unanswered, never as a miss.

Three questions per round. Between rounds the owner may say `skip`, `stop`, or
`more on <chunk>`. A cancelled wizard still grades what was answered.

## 4. Grading

`quiz.py grade <dir> q1=b q2=a ...` records the picks and prints the result:
a right pick gets its `why`; a wrong pick gets its `wrong` line, the answer and
`why`, and the slice read from disk now (first 20 lines). Relay that output to
the owner as it is. If the artifact changed since the map, grading stops with
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

## Ledger

When a run taught something, write the entry to a file (heading
`## quiz: <what this run did> · YYYY-MM-DD HH:MM`, no trailing `---`) and run
`bash ~/.claude/skills/shared/prepend-runtime-note.sh quiz <entry-file>`. Then
`bash ~/.claude/scripts/skill-log.sh record quiz --outcome unknown --note "record=<dir>"`.
