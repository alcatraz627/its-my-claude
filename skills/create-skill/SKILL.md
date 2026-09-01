---
name: create-skill
description: Turns a skill idea (a spec, intent, or checklist answers) into a finished SKILL.md with a tailored validation rubric and ledger steps, reviewed by a fresh seat for intent-vs-verbatim before it is written. Use when someone wants a new skill, slash command, or reusable workflow.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent
user-invocable: true
argument-hint: "[skill-name] [--global | --project] [--dry-run <dir>] | subagent-prompt [--shape S] [--persona P] [--out PATH]"
---

## Brief

`/create-skill` writes a skill the way this house writes them: the owner's words are
intent to be modelled, not text to be pasted; the structure is fixed (frontmatter with
the real field names, a Brief, Step 0, phases, a Validation rubric suited to what the
skill is for, the two ledger steps); the destination is absolute; and a seat that did
not draft it reads the draft for the one failure that keeps recurring, the owner's
input dumped in verbatim. It closes its own loop: lint, index, ledger.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` (§8 and the Authoring Conventions are the
contract this skill implements). Read the `## create-skill:` entries in
`~/.claude/skills/runtime-notes.md` and the archives:
`rg -n "^## create-skill" ~/.claude/skills/runtime-notes*.md`. Regenerate and read the
menu so the new skill is not a duplicate: `bash ~/.claude/scripts/skills-index.sh`
then `~/.claude/skills/00-index.md`.

## Usage

```
/create-skill <name>                     spec-first: take what the owner gave, ask only for gaps
/create-skill <name> --project           write to <cwd>/.claude/skills/<name>/ (a repo-local skill)
/create-skill <name> --global            write to ~/.claude/skills/<name>/ (the default from the gcc)
/create-skill <name> --dry-run <dir>     write to <dir>/<name>/ and stop before index + ledger
```

Destination rule (cs-01): global when CWD is `~/.claude` or `--global` is passed;
project when CWD is a repo with a `.claude/` directory and `--project` is passed or
CWD is not the gcc. Always absolute paths. Never `.claude/skills/<name>` relative to
CWD: from the gcc that nests one level too deep and `block-nested-claude.sh` refuses
it.

## Mode: subagent-prompt

When the first argument is `subagent-prompt`, this skill writes the brief a sub-agent
will receive instead of a SKILL.md. The whole mode, with the shape table, the six-line
checklist, the section order and the traps, is in `subagent-prompt.md` beside this
file; read it and follow it, then return here for nothing. Owner ruling 2026-08-26
(decision page skills-0826, D5a): seed the structure from the shape of the goal, do not
overconstrain, name what moves the needle, the pitfalls, and the claims to prove or
contradict; ask the owner one batched question only when the checklist has blanks.

## Phase 1: what the skill is (spec-first)

The owner usually hands over the answers already, in a prompt, a spec file, or a
conversation. Read those first. The checklist below is what a skill must answer, not
a script of questions; ask only for a row that is genuinely missing, in one message,
numbered.

| # | the skill must answer | formalise into |
|---|---|---|
| 1 | name | `name:` (lowercase, hyphens), unique in the index |
| 2 | what it does and for whom, and WHEN to reach for it | `description:` verb + input + output + "Use when ..."; under 300 characters |
| 3 | how it is invoked | `argument-hint:` with `<required>` / `[optional]`; under 120 characters |
| 4 | what it must not do | a `## Boundaries` list, or "GUIDELINES defaults" |
| 5 | which tools | `allowed-tools:` (`Agent`, never `Task`) |
| 6 | what efficacy means for THIS skill | the `## Validation` rubric (below) |
| 7 | what it chains with, what it writes, where | the phases and the output contract |

**Intent, not transcript.** The owner's words name a goal; a named instance stands for
its class; an example is one sample. Formalise: generalise the instance to the class
it belongs to, size the skill to what a good run needs (long when the model must
evaluate a lot before acting, short when it must not), and write the procedure in the
house voice. Do not paste the owner's prompt into the skill. If a sentence in the
draft is a near-verbatim run of the owner's input longer than a clause, rewrite it or
cut it. (Owner, 2026-08-19: "so many cases where the model just dumps my input to the
skill verbose instead of treating it as intent and what I have in mind".)

## Phase 2: the plan, shown once

Print the plan in one block and ask for a yes or changes, once:

```
/<name>  →  <destination path>
  description   <the 300-char routing sentence>
  argument-hint <…>
  allowed-tools <…>
  brief         <two lines>
  phases        <one line each; what is gathered, decided, done, checked>
  validation    <the efficacy dimension and the two or three checks>
  boundaries    <…>
```

The owner's "looks good", "go", or silence after a terse continuation means write.
Changes mean revise the block and show it once more, not a question per row.

## Phase 3: draft, then the intent review seat

Draft the full SKILL.md in the shape below, to a scratch path
(`~/.claude/scratchpad/create-skill/<name>.SKILL.md`), not the destination yet.

Then dispatch one read-only seat. Build the prompt with
`bash ~/.claude/scripts/seat/seat.sh prompt --role intent-review --out ~/.claude/scratchpad/create-skill/<name>.review.md --subject <draft path> --context "<the owner's original words, verbatim>"`,
dispatch it (sonnet), and `seat.sh check` the verdict file before reading it. The
role file carries this question set:

1. Intent vs verbatim: which sentences of the draft are the owner's input pasted in?
   Which named instance was kept as an instance when it stood for a class?
2. Does the description route: does a reader know what the skill does, on what, and
   when to reach for it, in under 300 characters?
3. Altitude: is it procedure and heuristics, or an essay? Which emphasis words carry
   no gate?
4. Does the `## Validation` rubric measure what this skill is actually for, and could
   an agent run its checks?
5. Anything the house conventions require that is missing (Step 0, Brief, ledger
   steps, absolute paths)?

Fix what the seat found, or say in one line why not, then continue. This gate is not
optional and is not self-review: the author is the worst judge of whether the author
pasted.

## Phase 4: write, lint, index, record

1. Write `<destination>/SKILL.md`. If it already exists, stop and ask (overwrite,
   rename, or abandon); never silently replace a skill.
2. `python3 ~/.claude/scripts/skill-lint.py <destination>/SKILL.md`; fix until no
   errors. Warnings are fixed or named in the delivery message.
3. `npx prettier --write <destination>/SKILL.md` (if prettier is available).
4. `bash ~/.claude/scripts/skills-index.sh` (gcc skills only; the nudge hook also does
   this on write).
5. `bash ~/.claude/scripts/skill-log.sh record create-skill --task "<name>" --outcome unknown --corrections 0 --note "dest=<global|project> review=<n findings, n fixed> lint=<clean|n warn>"`.
6. Runtime note, per GUIDELINES §7, when the run taught something.
7. Deliver: the absolute path, the description as written, what the seat caught, and
   "invoke with /<name>". No USAGE.md (nothing routes on one; write one only if the
   skill has a real quick-reference need).

`--dry-run <dir>` stops after step 3 and prints the path.

## The shape of a generated SKILL.md

```markdown
---
name: <name>
description: <verb + input + output. Use when ...>        # ≤300 chars
allowed-tools: <…>                                         # Agent, never Task
user-invocable: true
argument-hint: "<…>"                                       # ≤120 chars
---

## Brief
<what it IS, in the first sentence, before any rationale; then why it exists.
≤8 lines, human voice. Opening with motivation is the recurring defect here.>

## Step 0
Read `~/.claude/skills/GUIDELINES.md` (or the project's `.claude/skills/GUIDELINES.md`
when one exists) and the `## <name>:` entries in `~/.claude/skills/runtime-notes.md`.

## Usage
<invocation lines + argument table>

## <one heading per stage, each named for what it holds>
<gather → decide → do → check, in whatever order the work needs. Name each heading
for its contents, the way `## Inputs` / `## Sorting open items` / `## Output` do.
Never emit a heading of the form "Phase N": it names your process, not the reader's
question, and a generated skill inherits whatever this example shows.>

## Boundaries
<what it never does; only when there are real ones>

## Validation
<the efficacy dimension this skill is judged on (e.g. "context retention across
/clear", "prose and structure of the output", "useful-to-noise ratio of findings")
and two or three checks an agent can run: what to look at, how, what a pass is.
A rubric, not worked examples.>

## Runtime notes and ledger
Prepend a `## <name>:` entry via `bash ~/.claude/skills/shared/prepend-runtime-note.sh <name> <entry.md>`
when the run taught something. Then
`bash ~/.claude/scripts/skill-log.sh record <name> --task "…" --outcome unknown --corrections 0 --note "…"`.
```

Caps are forcing functions on the budgeted parts (description, argument-hint, Brief,
emphasis words). The body is unbounded.

## Validation

Efficacy dimension: does the written skill do what the owner meant, and is it found
and used. Checks: (1) the review seat's intent-vs-verbatim finding count on the
first draft, trending down across runs; (2) `skill-lint.py` clean at delivery;
(3) the skill's own first `skill-log` record lands within its first real run, and its
runtime note says the outline held.

## Runtime notes and ledger

Prepend a `## create-skill:` entry with `prepend-runtime-note.sh` when the run taught
something (what the seat caught, a checklist row that was hard to fill). The
`skill-log.sh record create-skill` line in Phase 4 is mandatory.
