---
number: 0021
title: MAGI setup-independence — evidence partitioning + pre-dispatch gate (D1/D5/D-prereq)
slug: magi-setup-independence
status: complete
date: 2026-06-17
affected_paths:
  - scripts/magi/setup-check.sh
  - scripts/magi/init-archive.sh
  - skills/magi/SKILL.md
---

# Migration 0021 — MAGI setup-independence

## Summary

Attacks the *root* cause the conformance gate (0020) only symptom-treated: magi
runs produced **manufactured convergence** — all voters fed one shared corpus, so
they agreed by construction, and "they converged" became the excuse to skip
voting. This adds **evidence partitioning** (each voter a distinct primary slice)
and a **pre-dispatch setup-independence gate**, so convergence is *discovered*,
not engineered. Second increment of the redesign (D1 + D5 + D-prereq).

## Why

The deep audit (`assets/reports/20260613-fable-vs-opus-efficacy/magi-audit/ROOT-CAUSE-AND-REDESIGN.md`)
measured **evidence-independence 0.15–0.50 (mean 0.33)** across the four runs while
persona-differentiation was 0.55–0.85. Conclusion: **persona richness is a decoy;
evidence independence is the load-bearing axis**, and it was destroyed in *setup*
(shared digest + `research:minimal`) before voters ever ran. Forcing voting (0020)
on echo-prone proposals just rubber-stamps the echo — independence is **upstream**
of voting.

## What changes

| Area | From | To |
|---|---|---|
| Evidence manifest (D-prereq) | none; `02-voter-prompts/` empty 4/4 | `init-archive.sh --params` records `params.voter_evidence` (per-voter `{voter,slice,model}`) at creation — also fixes the Phase-2 params-miss atomically |
| Setup gate (D5) | none | `scripts/magi/setup-check.sh` — CRITICAL when all voters share one slice or a supervisor *interpretive* digest is the shared substrate; WARN on no different-model seat, weak partition, `research:minimal` on breadth. Exit 0/1/2 |
| Where it runs | — | SKILL.md Phase-4 runs it BEFORE the dispatch spend; CRITICAL → redesign the partition, don't dispatch |
| Dispatch (D1) | all voters same corpus | SKILL.md Phase-2/4: assign each voter a distinct evidence slice; scope each voter prompt to ITS slice; never pre-write a supervisor interpretive baseline as the shared substrate |

## Detection logic (setup-check.sh)

Reads `params.voter_evidence`. CRITICAL iff (a) ≤1 distinct slice across >1 voter,
or (b) >1 voter assigned a baseline/digest/sweep/summary slice. WARN: distinct
slices < ceil(n/2); no model other than the main pool; `research:minimal` with
breadth (≥5 voters or `task_breadth:true`). No manifest → WARN (unverifiable =
echo-prone by default). Tested in isolation: echo/shared-digest → CRITICAL;
distinct+different-model+thorough → clean; same-model / no-manifest / minimal-on-
breadth → WARN.

## Backward compatibility

`init-archive.sh --params` is **optional** — omitting it reproduces the old
behavior (`params:{}`). `setup-check.sh` degrades to a WARN when no manifest exists.
So existing magi invocations don't break; the new path is opt-in-by-SKILL-guidance
and enforced pre-dispatch.

## Honest limitation (not yet validated end-to-end)

The setup-check + manifest are **isolation-tested only**. A real `/magi` run spawns
billed Opus voters, which was NOT triggered here — so the full dispatch→setup-
check→voters→finalize chain has not been exercised live. The SKILL.md Phase-2/4
guidance is advisory to the supervisor (the setup-check *script* is the mechanical
part; whether the supervisor runs it pre-dispatch is still spec-directed). A future
real run should confirm the chain and tighten the `>X%`-overlap metric (which needs
the manifest this migration introduces).

## Recovery / revert

`trash scripts/magi/setup-check.sh`; revert the `--params` block in
`init-archive.sh` and the Phase-2/4 SKILL.md edits. The `voter_evidence` field in
any meta.json is inert if unread.

## Cross-references
- Root-cause + redesign: `…/magi-audit/ROOT-CAUSE-AND-REDESIGN.md` (§5 D1/D5/D-prereq)
- Sibling symptom gate: migration `0020` (conformance / voting gate)
- `rules/skill-spec-update-not-honored` — why the mechanical script, not prose, is the binding part
