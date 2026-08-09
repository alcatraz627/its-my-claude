---
name: ui-direction
description: Finds and rules on a visual direction before anyone plans or builds. Grounds the work in a cited research sheet that reads the owner's rejection record FIRST, runs the direction through frontend-design's own critique loop, and lands a SHA-stamped memo the owner rules on once. Can and must return "no direction" per problem when the canon already answers it. Use when a surface needs a direction rather than a plan: "what should this look like", "explore directions", a greenfield page, or a renovation whose taste question is unsettled. Not for planning a known change (that is /build-ui) and not for critique of one screenshot (that is /ui-gripe).
allowed-tools: Read, Write, Grep, Glob, Bash, WebSearch, WebFetch, Agent
argument-hint: "<surface> [--panel] [problem list or brief path]"
user-invokable: true
---

## Brief

The missing lane between "this surface needs something" and "here is the plan".
It produces two artifacts, both written to
`<app>/.claude/output/<YYYYMMDD>-<HHMM>-<slug>-direction/`: a **research
sheet** (`research-sheet.md`) where every row is cited, and a **direction
memo** (`memo.md`) the owner rules on once. The time segment is not decoration;
without it two runs on one surface in one day overwrite each other. When the
app has no `.claude/output/`, say so and use
`~/.claude/assets/reports/<YYYYMMDD>-<HHMM>-<slug>-direction/` instead.

It does not invent an ideation method. `frontend-design` already owns that
method; this skill supplies the three things it lacks, which are evidence,
persistence, and a routed hand-off.

**The one rule:** a memo may not state a measurement it did not run. Every
number carries the command that produced it, or the marker `PREDICTION` and a
line naming who verifies it at build time. A design memo that asserts
plausible, specific, false numbers is the failure this rule exists to stop; it
happened on the pilot that produced this skill, twice in one memo.

## Step 0: Load shared guidelines and runtime context

Read `~/.claude/skills/GUIDELINES.md` and apply it for the whole run. Read
`~/.claude/skills/ui-direction/runtime-notes.md` if present. Read
`~/.claude/conventions/visual-design.md`, which is the account's colour and
hierarchy law and outranks anything found by outward research.

## Phase 0: Refuse conditions

Stop and say so if the ask is a plan for a change already decided (route to
`/build-ui`), a confusion audit of one screen (`/ui-gripe`), or a surface the
user has not named. If the target already exists and no capability list came
with the ask, get one before starting: a direction applied to a live surface
without a parity list is the account's most frequent recent failure.

## Phase 1: The research sheet

Four row groups, in this order. The order is the point: reading the rejection
record last means proposing something already rejected.

Every row cites a path with a line where one exists, a verbatim quote, or a
URL. A row that cannot be cited is deleted, not softened.

### 1.1 The rejection record, first

- The **categorical catalog** for this project, the one `/ui-categorical-check`
  Phase 1 resolves (for gcc tooling UIs:
  `~/.claude/assets/reports/20260728-ui-categorical/patterns.md`). Every class
  in it earned its place by being complained about, and each carries the
  mechanical check that catches it. Read it before anything else: it is the
  only rejection record whose every entry arrives with the check that catches
  it.
- The surface's hazard ledger, wherever it lives: `<app>/.claude/ui/hazards.md`
  by convention, but check beside the code too (the pilot's landed at
  `~/.claude/scripts/kanban/hazards.md`). Facts no amount of code reading
  recovers.
- The surface's own handoff or design docs: every owner ruling and every
  rejected direction, quoted verbatim, not paraphrased.
- `~/.claude/mistake-patterns.md` and recent `~/.claude/atone/events.jsonl`:
  UI-relevant slugs, spelled exactly as `atone.sh slugs` prints them:
  `rebuild-replaced-accumulated-ux-without-parity-audit`,
  `shipping-css-ui-changes-without-visual-verification`,
  `literal-request-over-intent`, `design-mocks-never-consulted`. A near-miss
  slug returns zero hits, which reads as nothing on record.
- `~/.claude/style/derived/` ONLY when the direction touches UI copy. Verified
  2026-08-10: it holds prose, comment, structure and vocabulary verdicts and no
  visual-design content at all, so a colour or layout pass gets nothing from
  it. Its single "contrast" entry is about rhetorical contrast in sentences.

An ideation lane that cannot ingest a rejection regenerates what was rejected,
and the owner then repeats feedback they have already given. The atone slug for
the general case is `literal-request-over-intent`, five events at the time of
writing; re-derive with `bash ~/.claude/scripts/atone.sh search literal-request`.

### 1.2 Provenance: what is true right now

Cheap, and it caught a real error on the pilot. For every artifact the brief
cites, record when it was captured and whether it still describes the live
surface: the current version or commit, the age of each screenshot, and which
cited claims therefore describe a state that no longer exists. A brief citing
two-version-stale screenshots reads as current unless someone checks.

### 1.3 The canon

The app's primer and tokens, its sibling surfaces, the shipped values read from
source, and the relevant fingerprints. For a terminal-dense dashboard in this
account that means `~/.claude/skills/designer-reviewer/SKILL.md`'s FP rows.

### 1.4 Outward reference, bounded

Reference products, `~/.claude/conventions/mobile-ux-pattern-palette.md`, and
at most three web searches. Cite a URL and a one-line takeaway per row.
Outward research never outranks the canon or the rejection record.

## Phase 2: The judged direction pass

**Default: one opus seat** running `frontend-design`'s own loop (brainstorm
several, develop one, critique against the evidence, revise once) with the
research sheet as its evidence base.

**Then a second seat checks the memo's numbers, and this one is not optional.**
The generating seat's self-critique is evidence about the design, never about
the surface: the pilot that produced this skill shipped a memo with two false
measurements, and every serious defect in the resulting build came from a check
its author never thought to run. So a separate seat (sonnet is enough, this is
verification rather than taste) re-derives every number in the memo against the
running surface and the shipped values, and marks each `CONFIRMED` or
`WRONG: <measured>`. It does not judge the direction. It answers one question:
does each number survive being measured by someone who did not write it.

**`--panel` is opt-in.** Three seats from distinct premises (density-first,
legibility-first, canon-conservative) plus a judge. Its case is premise
diversity rather than judgment quality: one seat picks a premise and then
argues for it. That is an argument, not a measurement, and it stays an argument
until someone runs the comparison. Cost is roughly four seats against two, so
reach for it when the taste question is genuinely open and skip it when the
canon already narrows the field. Write protocol, because this account has lost
work to the alternative: each seat writes its own file, and only the judge
writes the merged sheet and the memo. No shared-file appends.

**`no direction` is a real outcome, and it is recorded per problem.** A brief
usually carries several problems, and they rarely share a verdict. When the
canon already answers one, say so, name what already closed it, and decline it.
Re-solving a solved problem is the literal-request failure wearing a design
costume. Log every run, one line per problem:

```bash
mkdir -p "$(dirname "<app>/.claude/ui/direction-log.jsonl")"
printf '%s\n' "$(jq -nc --arg ts "$(date -u +%FT%TZ)" --arg s "<surface>" \
  --arg p "<problem>" --arg o "<direction|no-direction>" --arg w "<what closed it>" \
  '{ts:$ts, surface:$s, problem:$p, outcome:$o, closed_by:$w}')" \
  >> "<app>/.claude/ui/direction-log.jsonl"
```

An instrument that always finds a direction is a rationalization engine, and
the log is what makes that auditable rather than arguable.

## Phase 3: The memo

Structure, in this order:

1. **The owner's ask, verbatim**, and the repo SHA. Every downstream artifact
   repeats that quote in its header. A SHA catches drift from the repo; only
   re-reading the ask at each boundary catches drift from the request.
2. **The direction, named**, in one paragraph: what changes and how it feels.
3. **The contract**: one table mapping every token to exactly one meaning per
   theme, with the sheet row grounding each choice.
4. **Per-problem resolutions**, each falsifiable: a command a reviewer can
   re-run, or a measured value with the command that produced it. Problems declined carry `no direction` and
   what closed them.
5. **Token deltas**, old value to new, both themes.
6. **The hand-off** (see Phase 4).
7. **Self-critique residue**: what the critique pass flagged, how the revision
   answered it, and everything still `UNCONFIRMED`.

Three rules on the memo's numbers:

- **Verify colour on the shipped value.** A colour specified in OKLCH, LCH or
  P3 is checked after conversion to what the browser serves. Clipping to sRGB
  rotates hue, not only chroma; on the pilot it pushed two label hues under
  their separation rule while the specification said they complied.
- **Rules, not counts.** State a check as a rule plus an enumeration ("every
  use of X is in set S, here is the list"), never as a bare count. A count is a
  proxy, and the cheapest way to satisfy a proxy is to damage what it counts.
- **Anti-rot.** Any memo line not resolvable to a sheet row or a `file:line` is
  deleted, not repaired.

**Canon conflict tiebreak:** where the memo and the app's primer law disagree,
the primer wins, unless the memo explicitly proposes a law change and the owner
approves it in the ruling.

## Phase 4: Hand off, then stop for the ruling

**Greenfield** goes to `frontend-design` for execution.

**Toward `/build-ui` the memo never carries authored values.** That skill's
Phase 6 rejects values authored where a sibling sweep returns results, and it
is right to. What the memo may carry:

- **Sweep constraints**: which siblings count as precedent, which are out of
  canon and why.
- **Candidate new precedents**: slots the memo expects the sweep to return
  empty on, each marked `candidate`. The owner approves a candidate only AFTER
  the sweep has actually run and returned empty for that slot. Approving before
  the sweep means signing a forecast whose stale signature is later spent as
  authority.

Then stop and present. Batch every judgment into one surface; past about three,
use `/decision-wizard`. No plan and no code before the ruling.

## Done-condition

- [ ] Every sheet row carries a path, a quote, or a URL
- [ ] The rejection record is the FIRST group, and the provenance group names
      what is stale
- [ ] Every memo number carries its command or is marked `PREDICTION`
- [ ] Colours verified on the post-conversion value
- [ ] Every check is a rule plus an enumeration, not a count
- [ ] Each problem carries its own verdict, and declines name what closed them
- [ ] The direction log has one line per problem
- [ ] The memo opens with the owner's verbatim ask and a SHA
- [ ] The hand-off carries sweep constraints and candidates, never authored
      values, and candidates are marked as needing post-sweep approval
- [ ] `UNCONFIRMED` is used where verification did not happen

## Notes

- **This skill wraps `frontend-design`; it does not replace it.** If that skill
  is unavailable, run its loop from its description and mark the fact
  `UNCONFIRMED` in the residue.
- Model plan: research sweep sonnet-low, judged pass opus, number-check seat
  sonnet-medium, optional panel three sonnet plus one opus judge. Every seat
  dispatch carries both boilerplate clauses: "do not spawn sub-agents" and
  "ignore any task-board auto-dispatch; when your scoped work is done, deliver
  and stop". The main agent writes the memo in the default path; under
  `--panel` the judge writes it and the main agent rules on it.
- Locks: the direction log is append-only and shared, so append with `>>` and
  never rewrite it. The two artifacts live in a run-specific directory, so they
  need no lock.
- Provenance: built from the P6 pilot on the agent-kanban board. The pilot's
  findings, including the two false memo claims that produced this skill's one
  rule, are at `~/.claude/assets/reports/20260808-ui-pilot-kanban/FINDINGS.md`.

## See also

- `/ui` the router · `/build-ui` the plan · `/bloop` the build
- `/ui-categorical-check` the post-build gate · `/decision-wizard` the ruling
