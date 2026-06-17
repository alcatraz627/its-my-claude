---
number: 0020
title: MAGI conformance gate — enforce full-mode voting at Phase-11 finalize
slug: magi-conformance-gate
status: complete
date: 2026-06-17
affected_paths:
  - scripts/magi/conformance-check.sh
  - scripts/magi/cost-estimate.sh
  - skills/magi/SKILL.md
---

# Migration 0020 — MAGI conformance gate

## Summary

Adds a mechanical conformance check to the `/magi` run so a **full-mode run that
skips the Phase-6 voting round is caught and surfaced**, instead of passing
silently. First increment of the magi redesign from the 2026-06-13 fable-audit
meta-review (`assets/reports/20260613-fable-vs-opus-efficacy/magi-audit/`).

## Why

The meta-audit found **all four** full-mode `/magi` runs on 2026-06-13 skipped
Phase-6 voting (every `04-voting/` empty) while citing convergence — bypassing the
anti-groupthink mechanism (anonymized scoring + bias-matrix + scope-dissent)
exactly where it mattered. The spec mandated voting in full mode but **wired no
enforcement**, so per `rules/skill-spec-update-not-honored` the mandate was
advisory and nothing caught the skip. This builds the enforcement.

## What changes

| Area | From | To |
|---|---|---|
| Phase-6 skip detection | none (advisory SKILL.md text) | `scripts/magi/conformance-check.sh` — CRITICAL when voting was expected (voting:true / mode:full / jester present / ≥5 voters) but `04-voting/` has no scores/matrix and `--no-voting` wasn't set |
| Where it runs | — | invoked by `cost-estimate.sh` (the MANDATORY Phase-11 finalize), so the verdict rides on a step the supervisor can't skip; CRITICAL → non-zero exit after the cost block |
| Phase-2/4/11 hygiene | unchecked | same script warns on empty `params{}`, empty `02-voter-prompts/`, unfinalized `totals`/`finished_at` |
| SKILL.md §Phase-8 | "pick directly" easily mis-read as a skip license | explicit note: Phase 8 is POST-voting; only `--no-voting` (at dispatch) skips Phase 6; convergence is not a mid-run skip license |
| SKILL.md §Phase-11 | cost block only | documents the conformance gate + that a CRITICAL must be resolved before "done" |

## Detection logic (for maintainers)

`voting_expected = params.voting==true OR params.mode=="full" OR a jester voter
present OR ≥5 voter proposals` (lite=3, full=5/7 — the count is the robust
fallback when params are unrecorded and the jester is numerically named, e.g.
`voter-5`). `voting_ran = any 04-voting/*scores*.json or matrix*.md`. CRITICAL iff
`voting_expected AND NOT voting_ran AND NOT --no-voting`. Verified against all four
2026-06-13 archives (all CRITICAL) + synthetic lite/voted/no-voting runs (all
pass). Exit: 0 ok · 1 warn · 2 critical. Writes a `conformance` block into
meta.json.

## Scope / not-yet-built

This is the **A1 voting gate** + Phase-2/4/11 hygiene only — the mechanical tier.
The deeper redesign (D1 evidence partitioning, D5 pre-dispatch setup-independence
gate, the per-voter evidence manifest that the `>X%`-overlap test needs) is **not**
in this migration; it requires a dispatch-flow change and is the next increment.

## Recovery / revert

Remove the conformance-call block appended to `cost-estimate.sh`, `trash`
`conformance-check.sh`, revert the two SKILL.md notes. No data migration; the
`conformance` block in any meta.json is inert if unread.

## Cross-references
- Root-cause + redesign: `assets/reports/20260613-fable-vs-opus-efficacy/magi-audit/ROOT-CAUSE-AND-REDESIGN.md`
- Conformance audit: `…/magi-audit/MAGI-AUDIT.md`
- Sibling enforcement-over-advisory build: migration `0019` (declared-ready hook)
- `rules/skill-spec-update-not-honored` — enforcement must live at the data-write
