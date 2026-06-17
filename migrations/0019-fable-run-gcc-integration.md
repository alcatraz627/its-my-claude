---
number: 0019
title: Fable-run gcc integration — verification enforcement (2 hooks) + paste-ready canon
slug: fable-run-gcc-integration
status: complete
date: 2026-06-15
affected_paths:
  - scripts/hooks/declared-ready-stop.sh
  - scripts/hooks/guard-rg-replace-bundle.sh
  - scripts/hooks/guard-duplicate-symbol.sh
  - rules/exercise-based-verification.md
  - rules/cache-externally-mutated-state.md
  - conventions/run-and-observe-affordance.md
  - rules/testing.md
  - rules/corrections.md
  - conventions/doc-writing.md
  - skills/core-dump/SKILL.md
  - settings.json
  - proposals.jsonl
---

# Migration 0019 — Fable-run gcc integration

## Summary

Integrates the durable, defect-fixing findings from the 2026-06-13 cross-model
audit (4 Fable sessions reviewed by Opus + `/magi`, consolidated in
`~/.claude/assets/reports/20260613-fable-vs-opus-efficacy/`). The load-bearing
change is **mechanical verification enforcement**: two new hooks that bind
patterns which were advisory-only and recurring, plus one hook false-positive
fix, plus paste-ready rule/convention text. Net new always-load (CLAUDE.md) cost:
**zero** — everything is hooks, trigger-loaded rules, or appends.

## Why

The audit's headline: the Opus↔Fable efficacy gap was **~70% enforcement +
friction, ~0% knowledge** — Opus already knew to verify; nothing *made* it. Two
patterns had been diagnosed repeatedly and never mechanized:

- `declared-ready-without-runtime-exercise` (S3, **5–6× recurrence** across
  unrelated projects/models) — advisory topic-tag only, no gate; ~90 soft warnings
  and still worsening.
- The `rg -r` footgun (`prop-20260612-110331-da`) — diagnosed 5×, "only a hook
  fixes this" every time, never built (the `metadata→mnidata` mangling).

Advisory text does not bind in-flight sessions; only a hook does. This migration
builds the gates.

## What changes

| Area | From | To |
|---|---|---|
| declared-ready | atone slug + `testing.md` topic-tag (advisory) | **Stop hook** `declared-ready-stop.sh` + Tier-1 `rules/exercise-based-verification.md` (shipped as a pair) |
| rg -r footgun | open proposal, no enforcement | **PreToolUse[Bash] guard** `guard-rg-replace-bundle.sh`; prop closed |
| dup-symbol guard | false-positived on git-tracked bundles (`content.js`), got muted ~5× | `is_build_output()` filter — bundle twins no longer count (suppress-only, never adds a block) |
| verification friction | implicit | `conventions/run-and-observe-affordance.md` — one-command run-and-observe per project (the friction-first headline) |
| testing canon | — | `testing.md` += `[collect-not-run]`, `[known-gap-tripwire]`, `[test-as-spec]`; probe-before-fix in `[root-cause]`; screenshot read-back in §UI |
| cache safety | — | `rules/cache-externally-mutated-state.md` (Tier-2) |
| corrections | step 2 generic | += "generalize the correction to its class, not the user's literal example" |
| doc voice | — | `doc-writing.md` §7: route the voice pass to a fresh agent (you can't see your own AI-voice) |
| worktree handoff | — | `core-dump` SKILL.md: Quick Summary leads with worktree path + branch |

## Scope

Additive and reversible. No canonical paths moved, no scripts renamed, no schemas
changed. Two new `Stop`/`PreToolUse` entries in `settings.json` (validated by
`guard-settings-write.py`). The dup-symbol change is subtractive-only by design
(can shrink a block to nothing, never create one).

## Files affected

New: `declared-ready-stop.sh`, `guard-rg-replace-bundle.sh`,
`rules/exercise-based-verification.md`, `rules/cache-externally-mutated-state.md`,
`conventions/run-and-observe-affordance.md`.
Modified: `guard-duplicate-symbol.sh`, `rules/testing.md`, `rules/corrections.md`,
`conventions/doc-writing.md`, `skills/core-dump/SKILL.md`, `settings.json`,
`proposals.jsonl` (closed `prop-20260612-110331-da`).

## Hook contracts (for future maintainers)

- **declared-ready-stop.sh** (Stop, direct settings.json entry, NOT via
  orchestrator — needs to carry a decision): blocks a turn that edited
  source/test files and claims success when no run signal appears that turn.
  Carve-out: collect/compile/lint ≠ run. Loop-safe (`/tmp/claude-declared-ready-<sid8>`,
  blocks once per claim then steps aside). Mute: `~/.claude/.no-declared-ready-gate`.
- **guard-rg-replace-bundle.sh** (PreToolUse[Bash]): blocks short `-r` on an `rg`
  invocation (scoped per pipeline segment, so `jq -r`/`sort -r` don't trip it);
  allows long `--replace` as the explicit-intent escape. Mute:
  `~/.claude/.no-rg-replace-guard`.

## Recovery / revert

Remove the two `settings.json` hook entries (Stop + PreToolUse), `trash` the two
new hook scripts, revert the `guard-duplicate-symbol.sh` `is_build_output` block.
The rule/convention files are inert if unreferenced. Reopen the proposal with
`propose.sh` if reverting the rg guard.

## Deferred (NOT in this migration — by decision)

- **Mode-gated construction-prime hinter** (JIT, evidence-shaped pressure gated to
  `intent=feature`): touches the hinter pipeline and is the piece most able to
  "overwhelm"; held for a separate confirmation pass.
- **Prune the 26 rule files** (de-dilution): destructive/judgment-heavy; filed as a
  proposal, not done unilaterally.

## Cross-references

- Consolidated study: `~/.claude/assets/reports/20260613-fable-vs-opus-efficacy/CONSOLIDATED-REPORT.md`
- Hook design: `features/declared-ready-stop-hook.md`
- Per-session magi archives: `~/.claude/assets/magi/20260613-{1610,2011,2016,2025}-*`
