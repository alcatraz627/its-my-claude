# /adversarial-review — Usage Guide

## What it does

Prosecutes work already declared done. A fresh opus sub-agent, working in an isolated
worktree, presumes the "good enough" verdict was false and tries to prove it: re-running
skipped verification paths, cross-examining claims against docs and your instructions,
and attacking surfaces you already signed off on. Every finding is evidence-tagged and
must pass a relevance gate anchored in your recorded values, so the harshness stays
aimed at things you will care about.

## Usage

```
/adversarial-review [scope]
```

| Argument | Type     | Description                                                                                                 |
| -------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `scope`  | optional | Files, a branch, or a feature description. Default: this session's changed files, widened to their feature. |

## Examples

### Example 1: prosecute the session's work after it "passed"

```
/adversarial-review
```

Builds the claims ledger from this session's done/works/tested claims, dispatches the
prosecutor, and returns an indictment like: "3 counts: dark-theme claim broken on
re-run (EXECUTED), export silently dropped the CSV requirement from your 07-14 message
(CITED), empty-state crash in a flow untouched since round 2 (EXECUTED). Held under 6
other attacks (log attached)."

### Example 2: attack a signed-off feature before it ships somewhere real

```
/adversarial-review the onboarding flow on branch feat/onboarding
```

Ignores the sign-off history on purpose: walks the flow as a hostile first-time user,
induces the states the iterations never revisited, and diffs delivery against the
original ask verbatim.

### Example 3: the clean-verdict case

```
/adversarial-review scripts/metabolism.sh
```

If the work holds, the honest output is "held under N attacks" plus the failed-attacks
log — not manufactured findings. That verdict is the point, and it is trustworthy
precisely because the lane is structured to want the opposite.

## Caveats

- **Not the default review.** Routine post-change review is /skeptical-review (cheaper,
  read-only, constructive). This lane is for post-sign-off, high-stakes, or "tear this
  apart" moments; it costs an opus·high dispatch plus real execution time.
- **It will never bless anything.** Its best-case output is "held under attack". If you
  want a confidence gate, use a precision reviewer instead.
- **Findings can sting on purpose**, including on work you approved. The relevance gate
  is the contract that each one is worth the sting; dismiss any that fail it and record
  the dismissal in dispositions — that feedback tunes the gate.
- Expects a "done" claim to attack. Prosecuting half-built work just indicts known
  scaffolding.

## Dependencies

| Dependency                                            | Type              | Notes                                           |
| ----------------------------------------------------- | ----------------- | ----------------------------------------------- |
| GUIDELINES.md                                         | Shared rules      | Read at start of every run                      |
| personas/adversarial-reviewer.md                      | Persona           | The dispatch prompt's full text                 |
| scripts/review-scope.sh                               | Script            | Scope resolution, shared with /skeptical-review |
| scripts/guidance.sh, scripts/atone.sh, style/derived/ | User-value corpus | Feeds the relevance gate                        |
| scripts/review-marker.sh, scripts/persona-log.sh      | Scripts           | Coverage + efficacy trail                       |
| Agent tool (worktree isolation)                       | Runtime           | The prosecutor must be able to build/run        |

## Tips

- Run /skeptical-review first on big changes; let this lane hunt what survived it.
- Feed dispositions back honestly (rejected-with-reason especially) — the rejection
  reasons are exactly what future relevance gates mine.
- Pair with /decision-wizard when the indictment lands ≥5 findings needing verdicts.
