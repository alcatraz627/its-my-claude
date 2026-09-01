---
name: recommend
description: Answers what to do next on a session, project, or plan file as a call already made, splitting what it needs from you into gates you can clear today and defaults it took without asking, then the path to the next checkpoint. Use for "what now", "what do you need from me".
allowed-tools: Read, Bash, Grep, Glob, Skill
user-invocable: true
argument-hint: "[scope: this session | <project path> | <plan file>]"
---

## Brief

`/recommend` answers "what should I do now" in four blocks: the call, the gates
only the owner can clear, the defaults it applied without asking, and the
ordered path to the next checkpoint.

It exists because his attention gets spent on approvals the agent could have
made. On 2026-08-26 he ruled seven decisions and took the agent's stated pick on
all seven; only the prose he typed himself carried anything new.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` and the `## recommend:` entries in
`~/.claude/skills/runtime-notes.md`.

This skill implements rules it must not restate. Read whichever apply:
`rules/owner-gate-means-actionable-today.md` (what a gate is),
`rules/never-halt-on-authority-you-hold.md` (what is not one),
`rules/owner-decisions-go-through-a-wizard.md` (splitting by confidence),
`rules/dense-briefing-direct-answer.md` (the reply is the answer).

## Usage

```
/recommend                    the current session's work
/recommend <project path>     a project's live state
/recommend <plan file>        a specific plan or report awaiting a decision
```

## Inputs

Read these before recommending anything. A recommendation built on recalled
state recommends the wrong thing confidently.

| Input | Where |
|---|---|
| the armed goal, which defines the next checkpoint | `bash ~/.claude/scripts/goal/goal.sh show` |
| the task list or board this project actually uses | `bash ~/.claude/scripts/kanban/kanban.sh sync` where a board exists, else the Task tool |
| decisions already waiting | `bash ~/.claude/scripts/kanban/kanban.sh decide list` |
| what this session changed, and what it left unfinished | the session's own edits |
| the previous run's gates | `bash ~/.claude/scripts/skill-log.sh list --skill recommend --limit 1` |

Anything unreadable is named as unknown. An unknown is not a gate.

**Close the previous run.** A run's own gates cannot be graded when they are
raised, because the owner has not answered yet. So each run grades its
predecessor: compare the last record's gates against what the owner actually did
next, and carry that count into `--corrections` below. A gate he took as drafted
was a default that should never have been asked.

## Sorting open items

Every open item lands in exactly one bin. Run these tests in order and stop at
the first that fits.

1. **Waits on other work?** Blocked by that work, whoever eventually decides it.
   A prerequisite mislabelled as an owner gate renders as a real ask and gets
   read back as one.
2. **Already authorised** by the goal, an earlier message, a standing rule, or a
   prior ruling? Then it is done, not asked. Check the ruling's text before
   deciding you need it again.
3. **Settleable by evidence you can gather?** Gather it and decide. The lookup
   costs less than the round trip.
4. **Would he answer "yes, obviously"?** A default. If you can predict the
   answer, you are not asking a question, you are seeking permission.
5. **Everything left** needs taste, an authorisation, or a fact only he holds.
   That is a gate, and there are usually one or two.

A gate must also be clearable **today**. If clearing it needs something that
does not exist yet, it belongs in bin 1.

**Cap: three gates inline.** Above three this is a decision batch and routes to
`/decision-wizard` as a page. Do not merge four gates into three.

## Output

Four blocks, in this order, and nothing else. A block with nothing real in it is
omitted rather than filled; `rules/examples-as-quotas.md` governs this template
as much as any other.

| Block | Contents |
|---|---|
| The call | One line saying what should happen, then at most three sentences of why. Not options. It comes first because it is what he is reading for. |
| Gates | Numbered, each with your drafted answer marked so he replies `1a 2b`, or `ok` to take every draft. One line of context each. Never more than three. |
| Defaults applied, silence means agreement | One line per call you took. Usually the longest block, and the one that buys back his turns. |
| Next, to the checkpoint | Ordered steps to the next real stopping point, plus what is blocked and on what. Tie the checkpoint to the armed goal where one exists. |

**Refuse condition.** When nothing needs him and nothing is genuinely open, say
so in one line and stop. A run that manufactures a gate to fill a block has cost
him the turn this skill exists to save.

## Boundaries

Never implements; it reports and recommends. Never restates a file written this
turn beyond its absolute path and one sentence. Never lists a gate whose real
blocker is unfinished work. Never asks a question whose answer it has already
drafted and believes.

## Validation

Efficacy dimension: **turns bought back**. A good run leaves the owner typing a
ruling and nothing else.

1. **Gate precision**, computed one run late by design. The previous run's gates
   are graded when the next one starts and stored in `--corrections`, the field
   `skill-log.sh` already carries for this signal. `bash ~/.claude/scripts/skill-log.sh summary
   --skill recommend` aggregates it. A gate the owner took as drafted counts against the
   run that raised it, because it should have been a default. The rate should
   fall. A run whose every gate was rubber-stamped failed, however tidy.
2. **Manufactured blocks.** Re-read the output: does a block exist because the
   template has one? Target is zero.
3. **Checkpoint recognisability.** Could he name the checkpoint without reading
   the plan? "Re-measure after 10 new plans" passes. "Continue the work" does not.

## Runtime notes and ledger

Prepend a `## recommend:` entry via
`bash ~/.claude/skills/shared/prepend-runtime-note.sh recommend <entry.md>` when a run
teaches something, especially a gate that turned out to be a default.

`--corrections` carries the **previous** run's rubber-stamped gates. Never
hardcode it to zero; that is the measurement.

```bash
bash ~/.claude/scripts/skill-log.sh record recommend \
  --task "<what was recommended, one line>" --outcome unknown \
  --corrections <gates the previous run should have defaulted> \
  --metrics '{"gates":<n>,"defaults":<n>,"refused":<true|false>,"wizard":<true|false>}' \
  --note "<what the sort got wrong, if anything>"
```
