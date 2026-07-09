---
migration: 0028
title: Checkpoint pointer collision-preservation — <slug>.<uuid8>.json siblings
session: audit-gcc-7c@2026-07-09
status: complete
date: 2026-07-10
---

# Migration 0028 — Checkpoint pointer collision-file schema

## Why

Session slugs are only 2-hex disambiguated, and a live collision existed
(`local-models` held by two different session UUIDs; the per-slug pointer file is
last-writer-wins, so `/catchup --session-id local-models` silently resolved to
whichever session wrote last). Found by the 2026-07-09 core-dump audit (Finding E);
fix reviewed by review-coredump.md (S2/S3 hardening included).

## What changes

| From | To | Why |
|---|---|---|
| `~/.claude/checkpoints/<slug>.json` is the only per-session pointer shape | On slug collision (existing pointer's `session_uuid` differs from the writer's), the old pointer is preserved as `<slug>.<uuid8>.json` before the new primary is written | The older session stays reachable by name, not just via `--pick` |
| `resolve.sh --session-id X` reads only `X.json` (legacy fallback aside) | When `X.json` is absent, falls back to the newest `X.*.json` whose recorded `session_id` == X (identity-checked, so a dotted-slug primary like `web.api.json` can never masquerade for a query of `web`); multi-match prints a `note:` on stderr | Collision-preserved sessions resolvable by slug |

Edge semantics (write.sh): a uuid-less NEW writer still preserves an old
uuid-bearing pointer ("" != uuid). A uuid-less OLD pointer cannot be
distinguished → overwritten with a stderr warning; the append-only `index.jsonl`
retains every entry regardless (reachable via `--pick`).

## What does NOT change

- `index.jsonl` (append-only chronological log) — untouched, still the ground truth.
- `<session-uuid>.json` naming for the pointer files themselves (still slug-keyed).
- The deprecated `_last-checkpoint.json` back-compat slot (still pending migration
  0008 reader removal, `prop-20260515-141140-44`).

## Verification

- [x] Sandbox HOME replay: same slug, two UUIDs → old preserved as `<slug>.<uuid8>.json`, resolve serves the newest primary; after primary removal, serves the newest matching collision file
- [x] Dotted-slug masquerade (review-coredump S2 repro): query `web` with only `web.api.json` present → exit 3, NOT served
- [x] uuid-less new writer (S3 repro): old pointer still preserved; uuid-less old pointer → legible stderr warning, index intact

## Rollback

```bash
cd ~/.claude
git checkout HEAD -- scripts/checkpoint/write.sh scripts/checkpoint/resolve.sh
# Orphaned <slug>.<uuid8>.json files are inert (nothing reads them post-rollback);
# trash them at leisure.
```

## Notes / followups

- Consumers of `resolve.sh --session-id` should parse only the JSON object (a
  `note:` line may appear on stderr) — catchup SKILL.md Phase 0.3 documents this.
