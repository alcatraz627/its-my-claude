# 0032 — Resume Contract: Standing constraints + Standing caveats fields

## Summary

The `/core-dump` Resume Contract grows from six to eight fields: **Standing
constraints** (plan-level invariants and protected assets, verbatim, each with
the check that would catch its loss) and **Standing caveats** (unverified
claims, unreviewed-work notes, undispositioned findings, verbatim). Both lead
the block; `/catchup` parses them and surfaces them FIRST in the briefing as
binding scope fences / inherited debt. Companion rule:
`rules/invariant-graduation.md` (stay-claims in docs must be promoted to a task
+ a Standing-constraints entry; mixed thread-vs-rebuild framing resolved with
the user before implementation).

## Why

Two 2026-07-16 incidents, one engine, opposite directions. doc-22
(versable-builder): three days of owner-reviewed UI rebuilt-then-purged because
the doc's threading language never became a constraint and no checkpoint carried
it (atone `mist-20260716-074938-54`). claude-ipc hardening: honest caveats
("8 commits, none independently reviewed") dropped by a successor's resume
briefing — "checkpoint compression laundered the debt" (RCA at
`~/Code/Claude/claude-ipc/.claude/output/20260716-rca/RCA.md`). Constraints and
caveats are exactly what summarization drops while task momentum survives. Full
analysis: `assets/reports/20260716-gcc-structural-audit/REPORT.md` (P12, P13,
P16).

## Scope

Format/contract change only. No paths move; no headings change (the six parsed
`##` headings are untouched — the new fields are bullets inside
`## Resume Contract`), so pre-0032 checkpoints parse exactly as before and the
new fields are tolerated-missing on them.

## Label changes

None.

## Path moves

None.

## Files affected

| File | Change |
|---|---|
| `skills/core-dump/SKILL.md` | §2.6 two new leading fields + verbatim rule; template block; mini-mode carries them when non-empty; "6-9 lines" → "8-12" |
| `skills/catchup/SKILL.md` | §1.3 parse list; binding-semantics paragraph (fences / debt); §3.1 briefing surfaces the two fields first |
| `rules/invariant-graduation.md` | NEW — the promotion rule + mixed-framing clause |
| `features/context-retention.md` | Compaction-preservation section: verbatim-carry clause |
| `rules/00-index.md` | Regenerated |

## Phases

1. ✅ 2026-07-16 — all doc/skill/rule edits (this migration; single phase).
2. ⏳ Enforcement rung, if prose alone does not bind (see
   `rules/skill-spec-update-not-honored-by-running-session.md`):
   `scripts/checkpoint/write.sh` could warn when a full-mode checkpoint's Resume
   Contract lacks the two field labels. Not built — file via `propose.sh` if the
   field is being skipped in practice.

## Recovery

Revert the five files above (single commit). Old checkpoints are unaffected
either way; the fields are additive and tolerated-missing.

## Cross-references

- `assets/reports/20260716-gcc-structural-audit/REPORT.md` — the audit that
  produced P12/P13/P16
- atone `rebuild-replaced-accumulated-ux-without-parity-audit`
  (`mist-20260716-074938-54`)
- Sibling extension 2026-07: the "Decaying prerequisites" field (commit
  c464ad8) — same surface, forward-looking counterpart
