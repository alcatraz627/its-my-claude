---
name: gcc-explore
description: Sit down with the gcc and look around. Renders the config as three panels (SHAPE, what it is; MOVEMENT, which way it is drifting; CYCLE, the loops keeping it alive) from artifacts that already exist, then holds a dig-deeper conversation where both sides reach out. Use when the user wants to feel the shape of their config rather than find a defect in it: "show me the gcc", "what is this thing", "how is it moving", "walk me through it". For "what is broken" use /gcc-map instead.
argument-hint: "[shape <dir> | vital <name> | cycle <loop>]"
user-invokable: true
allowed-tools: Read, Grep, Glob, Bash
---

## Brief

The exploratory sibling of `/gcc-map`. The map is an X-ray that hunts defects. This
skill is the room itself, rendered so a human can look around it. It CONSUMES the
instruments that already exist rather than re-scanning: the map's durable chart, the
vitals EKG, and the schedulers and ledgers the config already keeps. It adjudicates
nothing. Where it notices something that smells like a defect, it points at the map
and stops.

The base run answers three questions in three panels. Then the agent speaks second,
with what it finds genuinely notable in today's numbers, and offers ways to dig in.

## Step 0: Load Shared Guidelines and Runtime Context

Read `~/.claude/skills/GUIDELINES.md` (this project has no local copy, so use the
global one). Apply all rules for the whole run: forbidden paths, retry logic, tool
preferences, verbosity, timeouts, post-run insights, and the file lock protocol.

Also read `~/.claude/skills/runtime-notes.md` for past runs of this skill. Continue
without it if absent.

## Usage

```
/gcc-explore                    base run: three panels, then the reach-out block
/gcc-explore shape rules        open one area's census and what the indices claim
/gcc-explore vital learning     one vital's history and what moved it
/gcc-explore cycle nightly      walk one loop end to end with its last real runs
```

A bare invocation is the main event. The verb forms are the same thing the
dig-deeper block offers, reachable directly when the user already knows where they
want to look.

## Phase 1: The base run

Run the renderer once and show its output verbatim:

```bash
bash ~/.claude/scripts/gcc-explore.sh
```

That script owns every number. Do not recompute, round, re-summarize, or retype its
panels. A figure retyped by the model is a figure that drifts, and the panel footers
exist so the user can trace each one to an absolute path. If the script fails,
report the failure and stop. Never hand-assemble a substitute.

Three things the renderer does that you must not undo:

1. **Freshness is declared, never papered over.** Past 14 days the SHAPE panel says
   the map is stale and prints `/gcc-map` as the fix. Between 7 and 14 days, or any
   time migrations landed under the map, it adds a shallow probe naming how much
   moved. Never soften that line into "roughly current".
2. **The structural census is live; the map's FINDINGS are not.** When the map is
   stale the counts are still true, because they come from disk this second, but
   nothing the map concluded is carried forward. Keep that distinction if asked.
3. **Every panel names its sources.** Absolute paths, in the footer.

## Phase 2: Both of us reach out

The panels are the config speaking. Now you speak, briefly.

Read the same data as structured JSON, so your observations rest on values rather
than on parsing your own rendered text:

```bash
bash ~/.claude/scripts/gcc-explore.sh --json
```

Offer **at most three observations**, each genuinely notable in TODAY's numbers, and
each tagged to its panel. A good observation names a relationship the panels show
but do not spell out: an intake rate far above a retirement rate, one folder holding
most of a month's churn, a loop whose ledger has gone quiet, a rising mistake curve
against a flat rule count. If nothing in the data is actually notable, **print no
observations at all**. An empty section is omitted, never padded to look thorough.

Then offer the dig-deeper paths and stop:

```
  I notice:
    · movement — [observation]
    · cycle    — [observation]

  dig deeper:  1 shape · a folder      2 movement · a vital's history
               3 cycle · one loop end to end      or ask anything
  →
```

Typed numbers and free-form questions both work. **Never use a dialog tool** for
this (`AskUserQuestion`, `mcp__inputs__*`). They are unusable in the owner's
fullscreen TUI, and a picker that hangs is a failed exploration. Plain text, then
wait.

## Phase 3: Dig deeper

Each verb answers from artifacts and ends by offering the next hop, so exploration
chains without the skill being re-invoked.

| Verb | What it opens | Reads |
|---|---|---|
| `shape <dir\|channel>` | one area's live census against what the indices claim about it | the directory, `LOOKUP.md`, `FOLDERS.md`, `PLACEMENT.md`, `rules/00-index.md` |
| `vital <name>` | one vital's history and what moved it | `atone/events.jsonl`, `proposals.jsonl`, `migrations/`, git log, file timestamps |
| `cycle <loop>` | one loop walked end to end, with its last three real executions | the loop's launchd plist, its ledger, its derived outputs |

Rules for every answer:

- **Cite the artifact you read, absolute path.** A claim about how a subsystem works
  needs the file:line that proves it (`rules/structural-claim-without-reading-code.md`).
- **`vital <name>` has no timeline feed and never will.** History is derived from what
  already exists: file timestamps, session logs, migration entries, git log. The
  `vitals/timeline.jsonl` idea was dropped by owner verdict, not deferred. Do not
  propose it, and do not create it.

  A writer for it already exists and has never run: `~/.claude/scripts/vitals-timeline.sh`
  appends one dated reading to `~/.claude/vitals/timeline.jsonl`, and that directory
  is absent, so the script has produced nothing. It is deliberately unscheduled. Do
  not wire it up for this skill, and do not read it as evidence the feed was merely
  deferred. Whether that script stays or goes is the owner's call, not this skill's.
- **Notice, never adjudicate.** If a divergence looks like a real defect, say what you
  saw and point at `/gcc-map`. Ranking it, scoring it, or calling it broken is the
  map's job.
- End with the next hop offered.

## Out of scope

- **No writes.** This skill is a reader. The only file it may write is its own
  runtime note. It never edits config, never fixes what it notices, never commits.
- **No re-scanning.** If a number would require redoing the map's work, it belongs to
  the map. Consume, do not duplicate.
- **No sub-agents, no fan-out.** The base run is main-lane only, and completes from
  existing artifacts plus one live vitals read.
- **Not a health report.** Findings, severities, and verdicts belong to `/gcc-map`.

## When the other skill is the right one

The two are siblings sitting next to each other, and neither should pretend the
other does not exist. Route out loud, mid-run, whenever the user's actual question
fits the neighbour better:

- **Send to `/gcc-map`** when the question is diagnostic: what is broken, what is
  orphaned or stale, what does an index claim that disk contradicts, what is the
  always-on budget doing to a session. Send there too whenever this skill's own
  freshness line says the map is stale and the user wants to trust its findings.
- **A mix is often right.** "Refresh the map, then explore what changed" is a normal
  two-step, and so is "explore first to find the area, then map that area deeply".
  Say so rather than making the user discover it.
- **The pointer is the whole handoff.** `/gcc-map` sets `disable-model-invocation:
  true` (`~/.claude/skills/gcc-map/SKILL.md:6`), so it is deliberately user-triggered
  and you cannot run it for them. Name the command and let them decide.

## Notes

- **Why a script owns the numbers.** `~/.claude/scripts/gcc-explore.sh` is the same
  shape as `~/.claude/scripts/gcc-vitals.sh`: deterministic measurement with a
  `--json` mode, so the skill layer contributes judgment rather than arithmetic. It
  also means the base run is testable without a model in the loop.
- **Consumer, not collector.** Every source already existed before this skill. If a
  future panel needs data nobody keeps yet, that is a proposal, not a quiet new
  ledger.
- **Honest bounds travel with the numbers.** Token figures are chars/4 estimates.
  "Touched since the map" uses mtime, which a reformat trips as readily as a rewrite.
  Say so if a user leans on a figure harder than it can bear.

## Provenance

Built 2026-08-14 from the spec at
`~/.claude/assets/reports/20260814-1655-gcc-explore-spec/spec.md`, ratified with
four owner verdicts: the name, no timeline feed, the 14-day and 7-day freshness
rule, and the SHAPE, MOVEMENT, CYCLE panel order. The mutual-routing section above
is the first verdict's binding rider, in the owner's words: "I don't need artificial
silos when the other skill is sitting right next to it."
