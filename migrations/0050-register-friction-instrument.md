# 0050: the register-friction instrument (lede block, counter gate, weekly audit)

**Date:** 2026-08-20
**Type:** new subsystem (renderer + two Stop hooks + scheduled audit) + taxonomy/thesaurus additions
**Sessions:** docs-skill (fc30c063)

## What changed

Owner-approved D1-D7 from the register-friction sweep
(`assets/reports/20260820-register-friction-sweep/PROPOSAL.md`; evidence run
`style/sweep/20260820-regfric-fc30/`, 43% confirmed friction over 72h).

1. **Lede renderer**: `scripts/box/close.sh` — owns position 1 of substantial
   owner-facing replies (verdict · needs-you with authority-tagged drafted asks ·
   next). Emits a per-invocation nonce to `/tmp/claude-lede-<sid8>/nonce`.
   Deviation from the proposal as written: needs-you rows come from
   `task-table.sh --json` piped through jq instead of a new `--owner-close` mode,
   so the shared script is untouched and gcc-work's /tasks lane is not collided with.
2. **`scripts/hooks/reply-lede-stop.sh`** (Stop, DRY-RUN tier): WOULD-BLOCK note
   when a reply >1200c carries owner-owed vocabulary and position 1 lacks the
   current nonce's lede signature. Enforce later via `REPLY_LEDE_ENFORCE=1`.
   Mute: `.no-reply-lede-gate` (machine-wide) / `REPLY_LEDE_OFF=1` (process).
3. **`scripts/hooks/counter-gate-stop.sh`** (Stop, TELEMETRY tier): measures every
   ≥400c reply as numbers → `logs/counter-gate.jsonl` (chars vs prompt-derived
   budget, first-question position, completion verbs, cluster-aware bare-id count);
   systemMessage only on budget breach. Never re-counts prose-smell's tells.
   Mute: `.no-counter-gate` / `COUNTER_GATE_OFF=1`. Both hooks registered in
   settings.json Stop chain before prose-smell.
4. **Weekly audit**: `scripts/style/friction-audit.sh` (+ `friction-extract.py`,
   the sweep's pair extractor productized) — trailing-7d rerun of the pipeline on
   the gemini lane, one summary row per week → `style/friction-ledger.jsonl`.
   Scheduled `friction-audit` weekly mon 09:30 via gcc-schedule, calendar companion
   5083D23C. Baselines to bend: friction rate 43%, buried-question answer rate 5%,
   silent give-ups 13/72h.
5. **Taxonomy**: `conventions/language-quality.md` gains bare-ids, buried-question,
   option-menu (sweep-confirmed at volume). **Thesaurus**: 5 active entries
   thes-20260820-165353-{b4,52,2b,03,db} from the owner's mined verdicts.
6. **D7**: prose-smell promotion decision deferred to counter-gate telemetry
   (addendum in `assets/reports/20260710-queue-reviews/1.5a-prose-smell.md`);
   one promotion decision, taken together, on numbers.
7. **Phase 2 (approved, not built)**: claim ledger (`claim.sh` +
   `claim-scope-stop.sh`), blocked on 2 weeks of D1/D2 telemetry — task #47.

## Rollback

Remove the two hook entries from settings.json Stop; `schedule.sh rm
friction-audit`; trash `scripts/box/close.sh`, `scripts/hooks/{reply-lede,counter-gate}-stop.sh`,
`scripts/style/friction-audit.sh`. Ledgers and taxonomy additions are additive.
