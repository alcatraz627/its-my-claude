---
number: 0025
title: Event-ledger system bootstrap — spec, shared writer, proposals domain, alert layer (P0-P3)
slug: ledger-system-bootstrap
status: in-progress
date: 2026-06-27
session: rightsize-rev@2026-06-27
affected_paths:
  - skills/shared/ledger-format.md
  - scripts/ledger/ledger-common.sh
  - scripts/ledger/evaluate-detectors.sh
  - ledger/goals.toml
  - ledger/detectors.toml
  - ledger/alerts.jsonl
  - ledger/detector-state.json
  - proposals-domain/
  - i-dream/domains/proposals.toml
---

# Migration 0025 — Event-ledger system bootstrap

## Summary

Bootstraps a centralized event-ledger over `~/.claude`, extending (not replacing)
the existing i-dream domain registry. Design + adversarial critique + MAGI panel +
phased plan: `assets/reports/20260626-ledger-design/` (`00-DESIGN`, `01-CRITIQUE`,
`03-PLAN-REVISED`, `04-P2-PROPOSALS-RUNBOOK`) and `assets/magi/20260627-0026-gcc-ledger-eval/`.
This migration covers phases P0-P3; the build is incremental and gated, so it is
marked in-progress.

## What changed (new canonical paths)

- **`skills/shared/ledger-format.md`** (P0) — the canonical event-line contract
  (minimal envelope `{id, ts, domain-classifier}`, the family-boundary test, the
  corrected i-dream registration mechanism). No behavior change; a spec doc.
- **`scripts/ledger/ledger-common.sh`** (P1) — the one sanctioned ledger writer
  (`ledger_id` / `ledger_ts` / `ledger_append` / `ledger_commit` / `ledger_seal_*`
  / `LEDGER_STRIP_EMPTY` / `ledger_split_array`), extracted byte-for-byte from
  atone/affirm/propose. **Not yet wired into atone/affirm/propose** (owed); its
  first live caller is the alert evaluator below.
- **`proposals-domain/` + `i-dream/domains/proposals.toml`** (P2) — registers
  `~/.claude/proposals.jsonl` as an i-dream dream-domain (dedup/stale surfacing).
  Native-emitted; events symlinked as `{root}/events.jsonl`; deterministic
  `_tldr.txt` via `consolidate.sh`. Verified end-to-end (runbook §4).
- **`ledger/goals.toml`** (P3) — the value-system alerts are downstream of (the
  binding rule: no `goal_ref` here → an alert downgrades to a silent LOG).
- **`ledger/detectors.toml`** (P3) — alert detectors (v1: `atone-s3-burn`,
  burn_rate). Central + evaluator-owned for v1; per-domain `[[detector]]` blocks
  deferred (i-dream's parser rejects some unknown keys — see runbook §5).
- **`scripts/ledger/evaluate-detectors.sh`** (P3) — the stateless alert evaluator:
  spec-lint + offset-cursor lint + staleness + the binding rule + burn-rate math
  with two-window/hysteresis/cooldown. Appends `kind:"alert"` records via
  `ledger-common.sh`. 8/8 unit tests; live run fired a real ticket (25 S3 in 30d).
- **`ledger/alerts.jsonl` + `ledger/detector-state.json`** (P3) — the alert log +
  per-detector firing state (created at first run).

## Compatibility / rollback

- Additive. No existing path moved or renamed; atone/affirm/propose are unchanged
  (the P1 lib has no live caller in those scripts yet).
- The proposals domain is removable with two `trash` commands (manifest +
  `proposals-domain/`); `proposals.jsonl` is untouched. Runbook §6.
- The alert layer is removable by deleting `ledger/` + `scripts/ledger/`; nothing
  else reads them yet.

## Owed / follow-ups (tracked in the Task list + filed proposals)

- Wire `ledger-common.sh` into atone/affirm/propose (the dedup half of P1).
- Schedule `evaluate-detectors.sh` on the existing atone/i-dream cadence (no new
  cron) + its Calendar companion; add a `/doctor` "ledger alerts" section.
- Auto-file a `propose.sh` gate candidate on a `graduate-to-mechanism` ticket.
- Per-domain `[[detector]]` blocks once parser tolerance is confirmed.
- A guard-whitelist note: `evaluate-detectors.sh` reads atone raw; running it by
  hand with the path inline trips `protect-atone-raw.sh` (the script's own read is
  fine; only an inline-path Bash call is blocked).
