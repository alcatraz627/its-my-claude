# 0034 — readers-advocate critic persona + report/review/comment consumers

## Summary

New dispatch persona `personas/readers-advocate.md` (sonnet, fresh-eyes,
structured findings only, enforces `style/` thesaurus digests, never invents
taste) wired as: pre-delivery gate for heavy-tier reports
(`conventions/report-writing.md`, NEW — the genre contract: per finding
symptom → impact → path → detail, caveats verbatim, dispositions table),
pre-commit comment pass + review contract (`rules/git.md`), harshness lane +
detect.py pre-pass + self-voice-pass + dispositions in
`skills/skeptical-review/SKILL.md`, report-contract inheritance clause in
`rules/sub-agent-outputs.md` (checklist item 5). Telemetry appender
`scripts/style/style-log.sh` → `logs/style-watch.jsonl`; its critic-pass
record (artifact sha256) doubles as the voice-passed marker the batch-4
watcher dedupes against (tested: absent → present → stale-on-edit).

## Why

Audit P2/P4/P10/P11/P17/P18 (`assets/reports/20260716-gcc-structural-audit/`):
author-blindness is positional — opus/fable reviewers write violations into
their own reviews — so every writer gets a fresh cheap reader; structured
findings have no surface on which to smell.

## Scope / Label changes / Path moves

Additive; no labels; no moves. `logs/style-watch.jsonl` is a data ledger
(rsync, untracked) like every other log.

## Files affected

`personas/readers-advocate.md` (NEW) · `scripts/style/style-log.sh` (NEW) ·
`conventions/report-writing.md` (NEW) · `rules/git.md` (+2 sections) ·
`rules/sub-agent-outputs.md` (+item 5) · `skills/skeptical-review/SKILL.md`
(3 edits) · `migrations/MIGRATIONS.md` (row).

## Phases

1. ✅ 2026-07-16 — all of the above.
2. ✅ 2026-07-16 (later same day) — /magi SKILL.md Phase 10: ledger-derived tone
   + readers-advocate gate + critic-pass logging; intermediates stay tier off.
3. ⏳ Advisory→hook rung for the pre-commit comment pass if it gets skipped in
   practice (same pattern as mig 0032 phase 2).

## Recovery

Revert the commit; delete the three NEW files. No data-path dependencies until
batch 4 consumes the marker.

## Cross-references

mig 0032 (Standing caveats carry the dispositions debt) · mig 0033 (digests +
scope map this persona loads) · `assets/reports/20260716-gcc-structural-audit/`
