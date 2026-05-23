---
name: skeptical-review
description: Skeptically reviews the code changed this session by forking a FRESH adversarial reviewer that grounds every finding in the actual tree — surrounding context, sibling conventions, upstream/downstream usage, existing implementations to reuse, documented code smells, and comment quality. Produces a ranked list of SUSPECTED issues for the human to deep-dive. Flags, never auto-fixes. Use when the user says "review", "check my work", "is this right", "skeptically review", or before declaring a non-trivial change done.
---

# Skeptical Review

A post-work review that is **biased toward suspicion, not approval**. Its job is
to surface things the author (me) plausibly got wrong so the human can deep-dive
— not to bless the diff. It **flags, it never auto-fixes**.

## Why this forks a fresh context (the load-bearing design choice)

A model reviewing its own diff *in its own context* is structurally sycophantic:
it already "knows" why it wrote each line, so it rationalizes. Genuine skepticism
requires a **fresh sub-agent that has never seen the reasoning** — only the diff
and the surrounding code — with an adversarial instruction to assume the change
is wrong until the tree proves otherwise. This is the same anti-sycophancy logic
as the atone juror gate.

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
passing the file list, the pre-pass hits, and the output path. The agent **must
write the report to disk before returning** and return only a short abstract +
the path (per `rules/sub-agent-outputs.md`).

### 4. Present
Read the report. Show the user a ranked summary (highest-suspicion first), each
line: `severity · file:line · one-line claim · which check failed`. Offer to
deep-dive any item. Do **not** start fixing unless the user picks items to fix.

### 5. Record coverage
Mark this change-set reviewed so the Stop review-required gate stops blocking:
```bash
bash ~/.claude/scripts/review-marker.sh write <SID>
```
One review covers later fixes to the SAME files; touching new code files re-arms
the gate. (This is what makes "auto-invoke" work: the gate refuses "done" on a
substantial unreviewed change until this marker is written or the gate is muted.)

## The reviewer prompt (template)

> You are a skeptical code reviewer. Assume the diff below is **wrong** until the
> surrounding code proves otherwise. You did not write it and owe it no charity.
> Your output is a list of **suspicions for a human to deep-dive**, so bias
> toward surfacing (report anything you are ≥40% sure of), but **every finding
> MUST cite a `file:line` you actually opened** — no vibes, no "consider maybe".
> You are STRICTLY READ-ONLY except for your one report file. You may NOT edit
> code, and you may NOT run any command that appends to / overwrites / moves a
> real file or data store — that explicitly includes things like `guidance.sh
> add`, `atone.sh add`, `>`/`>>`/`mv`/`tee` onto a live path. To exercise a
> parser or script against data, COPY the input to `/tmp` and run it there,
> never against the live file. (A prior review pass clobbered the live
> `guidance/notes.md` by testing `guidance.sh add` against it — never again.)
>
> Files changed this session: `<list>`
> Mechanical smell pre-pass already found: `<atone-lint hits>`
>
> First read the user's standing directives — `bash ~/.claude/scripts/guidance.sh show`.
> Any change that violates one is a HIGH-confidence finding: the user explicitly
> asked for this and the agent didn't comply. Cite the directive verbatim.
>
> Then run these six checks against each changed file/symbol, grounding each in
> real `rg`/`Read`:
>
> 1. **Surrounding context** — `Read` the *full enclosing function/scope* of each
>    changed hunk (not just the diff). Does the change actually fit its context,
>    or did it assume a shape the surrounding code contradicts?
> 2. **Sibling conventions** — `rg`/`ls` the same directory for sibling files of
>    the same kind (component, hook, route, helper). Does the new code match
>    their established shape, or did it invent a different one?
> 3. **Upstream/downstream usage** — for each changed/added symbol, `rg` every
>    caller and importer. Did a signature, return type, prop, or behavior change
>    break a caller? Are all call sites still compatible?
> 4. **Reuse vs reinvention** — `rg` the tree for an existing function/type/util
>    that already does what the new code does. Was the wheel reinvented?
> 5. **Documented code smells** — confirm/expand the pre-pass hits; check the
>    well-known ones for the stack (e.g. error-string matching for flow, raw env
>    reads, missing precondition guards on destructive UI, effect dep arrays).
> 6. **Comment quality** — against `~/.claude/rules/comments.md`: comments must be
>    for humans first, first sentence code-agnostic, WHY-not-WHAT, ≤8 lines, no
>    jargon-flexing, no restating the code. Flag any comment that just narrates
>    what the next line literally does.
>
> Write the full report to `<output_path>` BEFORE returning, as a table ranked by
> suspicion: `| confidence | file:line | check | what's suspect | how to verify |`.
> Return a 5-bullet abstract + the absolute path. Do not fix anything.

## Hard rules
- **Flag, never fix.** The human decides what's real and what to change.
- **Read-only on all live state.** The reviewer writes ONLY its report. It must
  never run a command that mutates a real data file/store (`guidance.sh add`,
  `atone.sh add`, redirects/`mv`/`tee` onto a live path). Test parsers against a
  `/tmp` copy. The dispatch prompt must restate this every time.
- **No ungrounded findings.** Every item cites a `file:line` the reviewer opened.
- **Suspicion bias.** Recall over precision — this is a pre-filter for human
  deep-dive, not a high-precision gate. (Contrast `feature-dev:code-reviewer`,
  which reports only confidence ≥80.)
- **Persist to disk** before the agent returns; verify the file exists.

## Relationship to the write-time guards
The PreToolUse guards (`guard-cluster-e-smells.sh`, `guard-duplicate-symbol.sh`)
block the *precise, mechanizable* smells as they're written. This skill is the
*judgment* layer that catches what a regex cannot — convention mismatch, usage
incompatibility, subtle reinvention, bad comments — at review time.
