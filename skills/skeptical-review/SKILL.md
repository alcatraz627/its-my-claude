---
name: skeptical-review
description: Skeptically reviews the code changed this session by forking a fresh adversarial reviewer that grounds every finding in the actual tree — surrounding context, sibling conventions, upstream/downstream usage, existing implementations to reuse, documented code smells, and comment quality. Produces a ranked list of suspected issues for the human to deep-dive. Flags, never auto-fixes. Use when the user says "review", "check my work", "is this right", "skeptically review", or before declaring a non-trivial change done.
---

# Skeptical Review

A post-work review biased toward suspicion, not approval. Its job is to surface
things the author (me) plausibly got wrong so the human can deep-dive — not to
bless the diff. It flags, it never auto-fixes.

## Why this forks a fresh context (the load-bearing design choice)

A model reviewing its own diff in its own context is structurally sycophantic:
it already "knows" why it wrote each line, so it rationalizes. Genuine skepticism
needs a fresh sub-agent that never saw the reasoning — only the diff and the
surrounding code — instructed to assume the change is wrong until the tree proves
otherwise. This is the same anti-sycophancy logic as the atone juror gate.

The recurring failures this targets (atone clusters A "ungrounded assertion" and
E "convention-blind code") all share one root: **producing output without
grounding it against cheap-to-read evidence.** So the review's whole value is
that every finding is *grounded in an actual `rg`/`Read`*, with a `file:line`.

## Procedure (the main agent runs this)

### 1. Determine scope
```bash
SID=<this session id, first 8 chars>     # from any /tmp/claude-edited-files-* if unsure
bash ~/.claude/scripts/review-scope.sh "$SID"
```
This prints the changed files (git diff ∪ session edit-tracker). If empty, ask
the user which files/area to review.

### 2. Mechanical pre-pass (deterministic, fast)
For each changed file, run the shared smell catalog (all severities, not just
block-level):
```bash
~/.claude/scripts/atone-lint.sh --file <path>
```
Collect the hits — they seed the review with already-documented smells.

### 3. Dispatch the fresh adversarial reviewer
Pick an output path:
- normal project: `<project_root>/.claude/output/<YYYYMMDD>-<HHMM>-skeptical-review/review.md`
- if `CWD` is `~/.claude`: `~/.claude/assets/reports/<YYYYMMDD>-<HHMM>-skeptical-review/review.md`

Dispatch a `general-purpose` Agent (fresh context) with the prompt below,
passing the file list, the pre-pass hits, and the output path. The agent writes
the report to disk before returning and returns only a short abstract + the path
(per `rules/sub-agent-outputs.md`).

### 4. Present
Read the report. Show the user a ranked summary (highest-suspicion first), each
line: `severity · file:line · one-line claim · which check failed`. Offer to
deep-dive any item. Don't start fixing unless the user picks items to fix.

### 5. Record coverage
Mark this change-set reviewed so the Stop review-required gate stops blocking:
```bash
bash ~/.claude/scripts/review-marker.sh write <SID>
```
One review covers later fixes to the SAME files; touching new code files re-arms
the gate. (This is what makes "auto-invoke" work: the gate refuses "done" on a
substantial unreviewed change until this marker is written or the gate is muted.)

Then log the persona usage for the efficacy trail (`features/persona-activation.md`):
```bash
bash ~/.claude/scripts/persona-log.sh record skeptical-reviewer --mode dispatched \
  --session <SID> --task "<what was reviewed>" --outcome unknown \
  --note "<N findings; top severity; wiring verdict>"
```

## The reviewer prompt (template)

> You are a skeptical code reviewer. Assume the diff below is wrong until the
> surrounding code proves otherwise. You did not write it and owe it no charity.
> Your output is a list of suspicions for a human to deep-dive, so bias toward
> surfacing: report anything you are ≥40% sure of, and cite a `file:line` you
> actually opened for every finding — no vibes, no "consider maybe".
>
> Your job is coverage, then ranking — two separate stages. Report every in-scope
> finding you turn up, including low-severity and uncertain ones, and tag each
> with a confidence and a severity. Do **not** raise the reporting bar to cut the
> list down: "only flag what matters / don't nitpick / be conservative" is
> followed faithfully here and silently drops real findings. A separate ranking
> step sinks the minor items to the bottom — that is where focus comes from.
> Never drop a finding during investigation because it feels small.
>
> Read-only: you write only your one report file. Do not run any command that
> mutates a real file or data store. To exercise a parser, copy the input to
> `/tmp` and run it there. (Full statement in the skill's Hard rules.)
>
> Files changed this session: `<list>`
> Mechanical smell pre-pass already found: `<atone-lint hits>`
>
> First read the user's standing directives — `bash ~/.claude/scripts/guidance.sh show`.
> A change that violates one is a high-confidence finding: the user explicitly
> asked for this and the agent didn't comply. Cite the directive verbatim.
>
> Then hunt across each changed file/symbol, grounding each finding in a real
> `rg`/`Read`. Lead with the two highest-yield checks — they catch this account's
> deepest, most-recurring slips:
>
> 1. **Upstream/downstream usage** (highest yield) — for each changed/added
>    symbol, `rg` every caller and importer. Did a signature, return type, prop,
>    or behavior change break a caller? Are all call sites still compatible?
> 2. **Surrounding context** — `Read` the full enclosing function/scope of each
>    changed hunk, not just the diff. Does the change fit its context, or did it
>    assume a shape the surrounding code contradicts?
>
> Then the remaining heuristics — apply the ones the change-set warrants:
>
> 3. **Sibling conventions** — `rg`/`ls` the same directory for siblings of the
>    same kind (component, hook, route, helper). Does the new code match their
>    shape, or invent a different one?
> 4. **Right-sizing — fit, both directions** (per `rules/right-sized-code.md`) —
>    judge the change against its *goal shape and scope*, not a blanket "less is
>    better". Over-built: dead code, a speculative abstraction with one caller,
>    reinvented stdlib/native, a dependency for a few lines (`rg` the tree for the
>    util it duplicates). Mis-fit / under-built: a hand-rolled version of something
>    the codebase or platform already does well (a bare `<div>` dropdown over the
>    design-system component, an inlined copy that drifts from an existing util), or
>    a guard / a11y / edge case simplified away to save lines. If the diff matches a
>    shape the user explicitly asked for (a local helper they requested, a library
>    they named), that intent is not a finding — flag the mismatch, never the
>    obedience.
> 5. **Documented code smells** — confirm/expand the pre-pass hits; check the
>    well-known ones for the stack (error-string matching for flow, raw env
>    reads, missing precondition guards on destructive UI, effect dep arrays).
> 6. **Comment quality** — against `~/.claude/rules/comments.md`: comments are for
>    humans first, first sentence code-agnostic, WHY-not-WHAT, ≤8 lines, no
>    jargon-flexing, no restating the code. Flag any comment that just narrates
>    what the next line literally does.
>
> Write the full report to `<output_path>` before returning, as a table ranked by
> suspicion: `| confidence | severity | file:line | check | what's suspect | how to verify |`.
> Return a 5-bullet abstract + the absolute path. Do not fix anything.

## Hard rules
- **Read-only on all live state** (the one load-bearing guard). The reviewer
  writes only its report file and never runs a command that mutates a real data
  file or store — no `guidance.sh add`, `atone.sh add`, `>`/`>>`/`mv`/`tee` onto
  a live path, no code edits. To exercise a parser or script, copy the input to
  `/tmp` and run it there. A prior pass clobbered the live `guidance/notes.md` by
  testing `guidance.sh add` against it; that is the failure this guard prevents.
- Flag, never fix. The human decides what's real and what to change.
- Coverage, not bar-raising. Report every in-scope finding, including
  low-severity and uncertain ones, each tagged confidence + severity. Don't raise
  the reporting bar to shorten the list — a separate ranking culls; investigation
  never drops. Recall over precision: this is a pre-filter for human deep-dive,
  not a high-precision gate. (Contrast `feature-dev:code-reviewer`, ≥80 only.)
- No ungrounded findings. Every item cites a `file:line` the reviewer opened.
- Persist to disk before the agent returns; verify the file exists.

## Relationship to the write-time guards
The PreToolUse guards (`guard-cluster-e-smells.sh`, `guard-duplicate-symbol.sh`)
block the precise, mechanizable smells as they're written. This skill is the
judgment layer that catches what a regex cannot — convention mismatch, usage
incompatibility, subtle reinvention, bad comments — at review time.

## See Also
- `~/.claude/personas/skeptical-reviewer.md` — the dispatch persona this skill forks.
- `~/.claude/skills/magi/SKILL.md` — when a finding hinges on a real
  should-we / architecture / correctness-tradeoff call, the reviewer escalates
  that one scoped sub-question to `/magi` rather than ruling on it.
- `~/.claude/skills/arch-qa/SKILL.md` — traces real code paths to ground a
  suspected authority / data-flow claim instead of asserting one.
- `~/.claude/rules/exercise-based-verification.md` — the run-before-done gate this
  review precedes; the declared-ready Stop hook enforces it mechanically.
- `~/.claude/rules/right-sized-code.md` — the judgment layer behind heuristic #4:
  gate minimize-vs-fit on goal/scope/intent/total-cost before flagging either
  over-building or false-minimalism.
