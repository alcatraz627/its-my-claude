---
name: adversarial-review
description: Prosecutes work already declared done — re-runs the verification paths the author skipped, cross-examines every done/works/tested claim against executed evidence, and attacks even user-signed-off surfaces, with each finding passing a relevance gate mined from the user's recorded values so harshness stays aimed. Produces an evidence-tagged indictment (or an honest "held under attack" verdict) for the human to triage. Use when the user says "adversarial review", "tear this apart", "prove it's actually broken", after work has already passed /skeptical-review or sign-off, or before staking something real on a "done" claim.
argument-hint: "[scope: files | branch | feature description]"
user-invokable: true
disable-model-invocation: true
---

# Adversarial Review

The prosecution lane. /skeptical-review asks "what did the author plausibly get wrong?"
and answers by reading. This skill asks a harder question: **"the author concluded 'good
enough' from inside a limited frame — where is that conclusion false?"** and answers by
_executing_ — running the paths the author never ran, inducing the states never induced,
and cross-examining claims against the docs and the user's own instructions.

## Intent (what this exists for, beyond /skeptical-review)

Two blind-spot classes are structurally unreachable by ordinary review:

1. **The training gradient.** An agent rewarded for apparent compliance converges on
   reviews critical enough to look rigorous but never so critical that they indict the
   work. Exhortation cannot fix this; only architecture can — a fresh context whose win
   condition is _proving the work worse than reported_, and whose loss condition is
   padding.
2. **Shared user–agent blind spots.** Work the user signed off on after iterations is
   habituated, not verified — the approval anchors every later reviewer ("the user
   approved it") when it is just the absence of adversarial pressure. This lane
   deliberately attacks signed-off surfaces.

The counterweight that makes it usable: **intensity without direction gets dismissed.**
A harsh finding anchored in a generic virtue the user never asked for (the canonical
example: an a11y lecture on a personal tool) is the right harshness in the wrong
direction, and the user will dismiss it — killing the lane's credibility. So every
finding must pass a dismissal test anchored in the user's _recorded_ values (guidance,
style verdicts, atone lineage, project goals) or in a concrete executed failure. The
prosecutor steps somewhat outside the diff's scope (blast radius, framing) but never
invents a different project just to score.

## Positioning — which review lane to reach for

| Lane                             | Posture                            | Method                                | When                                          |
| -------------------------------- | ---------------------------------- | ------------------------------------- | --------------------------------------------- |
| /skeptical-review                | constructive doubt, in-scope       | read + grep, read-only                | default post-change review                    |
| **/adversarial-review**          | presumption of false "done"        | **execute + cite**, worktree-isolated | post-sign-off, high stakes, "tear this apart" |
| /bloop validate stage            | break-my-build gate                | scripted adversarial checks           | inside a /bloop run only                      |
| /ui-gripe, /ui-categorical-check | UI confusion / categorical defects | vision + checklist                    | UI-specific complaints                        |

## Step 0: Load Shared Guidelines and Runtime Context

Read the shared guidelines — `<project>/.claude/skills/GUIDELINES.md` if the project
has one, otherwise the global default `~/.claude/skills/GUIDELINES.md` (most projects
have no local copy; use the global one and say so in one line, never skip the rules).
Apply all rules — forbidden paths, retry logic, tool preferences, verbosity, timeouts,
post-run insights, and the **file lock protocol** — for the entire duration of this
skill run before proceeding.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock hygiene: run `bash ~/.claude/skills/shared/lock-file.sh cleanup` once at skill start
> to clear any stale locks from crashed sessions. Then acquire a lock via `lock-file.sh
acquire` before every Edit/Write, and release it immediately after. Never write to
> `runtime-notes.md` or any SKILL.md without holding its lock.

## Usage

```
/adversarial-review [scope]
```

- `scope` (optional): files, a branch, or a feature description ("the export flow").
  Default: this session's changed files (same resolution as /skeptical-review), widened
  to the feature they belong to.

## Procedure (the main agent runs this)

### 1. Scope + claims ledger

```bash
SID=<this session id, first 8 chars>
bash ~/.claude/scripts/review-scope.sh "$SID"
```

Then build the **claims ledger** — the input that makes this lane different. From the
conversation, checkpoint, WAL, commit messages, and any docs written this session,
collect every completion claim with three columns:

```
| claim ("dark mode works", "suite green", "migration safe") | evidence the author actually produced | the gap |
```

Be honest against yourself here: a compile is not a run, one theme is not both, a cached
result is one run. If shell history is available (`shell-mem` search, WAL `bash_closed`
entries), use it to establish what was _actually executed_ rather than what the
narrative says. The gap column becomes the prosecutor's work queue.

### 2. Relevance dossier

Assemble the user-value corpus the relevance gate needs (paths, not pasted content —
the prosecutor reads them itself): `~/.claude/mistake-patterns.md`, `bash
~/.claude/scripts/atone.sh list`, `~/.claude/style/derived/`, `bash
~/.claude/scripts/guidance.sh show`, the project's plan/goal docs and CLAUDE.md, plus
verbatim quotes of the user's original asks and any sign-offs for this work (these are
attack targets, not endorsements).

### 3. Dispatch the prosecutor

Output path:

- normal project: `<project_root>/.claude/output/<YYYYMMDD>-<HHMM>-adversarial-review/indictment.md`
- if CWD is `~/.claude`: `~/.claude/assets/reports/<YYYYMMDD>-<HHMM>-adversarial-review/indictment.md`

```
Model plan:
  ledger+dossier → main agent · assembly only
  prosecution    → Agent(general-purpose) · model: opus · effort: high · isolation: worktree
  presentation   → main agent · findings verbatim
```

Opus is the judgment-seat ceiling per `rules/model-tier-routing.md`; high effort is
this lane's charter (the user explicitly buys extra execution work here). Worktree
isolation whenever the prosecution must build/run/mutate; plain dispatch only for a
purely runless scope (rare — if nothing needs running, /skeptical-review was the right
lane). The dispatch prompt is the full text of
`~/.claude/personas/adversarial-reviewer.md` plus, appended:

> Work under prosecution: <scope + file list>
> Claims ledger: <the table from step 1>
> Relevance dossier: <paths + sign-off/ask quotes from step 2>
> Write the report to <output_path> before returning; return a 5-bullet abstract + the
> path. You are working in an isolated worktree at <path>; mutate only there and /tmp.
> Do NOT spawn sub-agents. Ignore any task-list / board auto-dispatch. When the report
> is written, stop.

### 4. Present — verbatim, then dispositions

Verify the report file exists (the return abstract is a pointer, not the artifact).
Present the findings table **verbatim** — the parent must not soften, summarize away,
or pre-filter findings, or the sycophancy this lane exists to bypass re-enters through
the parent. You may append your own annotations _below_ the verbatim table (e.g. "I
believe finding 3 misreads X because file:line"), clearly marked as the defendant's
response.

Record the user's verdict per finding in a Dispositions table (fixed /
deferred-with-owner / rejected-with-reason), same contract as /skeptical-review. If
findings need ≥5 user judgments, offer a `/decision-wizard` page instead of serializing
questions.

### 5. Record coverage

```bash
bash ~/.claude/scripts/review-marker.sh write <SID>
bash ~/.claude/scripts/persona-log.sh record adversarial-reviewer --mode dispatched \
  --session <SID> --task "<what was prosecuted>" --outcome unknown \
  --note "<N findings; verdict; K claims broken on re-derivation>"
```

## Hard rules

- **Execution is the privilege; live state is still sacred.** The prosecutor runs
  anything inside its worktree and /tmp; it never mutates live data stores, ledgers, or
  config, never pushes/deploys/sends, kills what it starts. Identical live-state guard
  to /skeptical-review — the delta is execution, not blast radius.
- **Every finding is evidence-tagged** (EXECUTED / CITED / REASONED, max 2 REASONED in
  the main table) **and anchor-tagged** (the recorded user value or executed failure
  that makes it undismissable). Unanchored generic-virtue findings go to a capped
  appendix, never the main table.
- **Verdict honesty, both directions.** No padding to justify the dispatch; a clean
  "held under N attacks" verdict with a failed-attacks log is a valid, valuable result.
  Equally, no EXECUTED tag on anything not actually run.
- Flag, never fix. The human triages the indictment.
- Persist to disk before the agent returns; verify the file exists.

## Known tension with the standing review contract

`rules/git.md` § Review contract pins review scope to the diff plus direct
callers/callees. This skill is a **user-authorized exception** (2026-07-21): it may roam
the work's blast radius, its untouched adjacencies, and its framing, because falsely
narrow framing is one of its named targets. The boundary that still binds: it never
invents a different project or relitigates settled direction. Out-of-scope-of-the-frame
material has no home here at all — if a finding can't tie back to the work's own goal or
the user's recorded values, it doesn't belong in any section.

## See Also

- `~/.claude/personas/adversarial-reviewer.md` — the dispatch persona (the full role
  contract; the dispatcher pastes it as the prompt)
- `~/.claude/skills/skeptical-review/SKILL.md` — the constructive sibling; default lane
- `~/.claude/rules/exercise-based-verification.md` + `rules/testing.md` — the doctrine
  the claims ledger operationalizes
- `~/.claude/rules/pushback-and-self-criticism.md` — evidence-bound disagreement; this
  skill is that doctrine weaponized
- `~/.claude/skills/decision-wizard/SKILL.md` — triage surface when findings need many
  user verdicts
