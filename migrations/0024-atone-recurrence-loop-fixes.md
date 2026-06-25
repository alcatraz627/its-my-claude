---
number: 0024
title: Atone-recurrence-loop fixes — stakes tiering, session counter, schema + juror-health fields, circuit breaker, stakes-gated blocks, efficacy metric
slug: atone-recurrence-loop-fixes
status: complete
date: 2026-06-25
session: atone-fixes-2b@2026-06-25
affected_paths:
  - stakes.json
  - scripts/stakes-tier.sh
  - .session-atone-slugs/
  - atone/events.jsonl
  - atone/feedback.jsonl
  - atone/derived/intervention-efficacy.json
  - scripts/atone.sh
  - scripts/atone-juror-dispatch.sh
  - scripts/atone-consolidate.sh
  - scripts/atone-consolidate/build-efficacy.sh
  - scripts/atone-consolidate/build-meta.sh
  - scripts/atone-consolidate/build-curated-atone.sh
  - hinters/10-atone-circuit-breaker.sh
  - hinters/50-atone-periodic-refresh.sh
  - scripts/hooks/guard-structural-claim.sh
  - scripts/hooks/guard-comment-hygiene.sh
  - scripts/hooks/guard-subagent-output.sh
  - scripts/hooks/atone-fired-and-ignored-check.sh
  - scripts/hook-orchestrator/Stop.tasks
---

# Migration 0024 — Atone-recurrence-loop fixes

## Summary

The atone system recorded mistakes well but the same classes kept recurring. An
audit + MAGI deliberation (`assets/reports/20260625-atone-recurrence-audit/`,
`assets/magi/20260625-1533-atone-recurrence-loop/`) found four causes: awareness
is saturated (rules/nudges score ~0 on behaviour change), advisory text never
binds an in-flight session, the gates that exist were leaking (the juror was
bypassed/unavailable on 9 of 19 June events and ran the same Opus model as the
offender), and the loop was blind to its own failure (no measure of whether any
fix worked). This migration ships the fixes: friction now scales with stakes,
the juror is independent and reliable, the unambiguous advisory hooks now block
in high-stakes repos, a same-session repeat trips a hard circuit breaker, and a
falsifiability backbone measures recurrence before vs after each intervention.

It is a migration (not an in-place edit) because it changes a **data store
schema** (`events.jsonl` gains `stakes` + `juror_health`), creates **new canonical
paths** (`stakes.json`, `scripts/stakes-tier.sh`, `.session-atone-slugs/`,
`derived/intervention-efficacy.json`), and changes **hook architecture** (a new
Stop task + three advisory hooks escalated to conditional blocks).

Governing constraint held throughout: **cost attaches to repeat, never to
confession** — nothing here makes *recording* a mistake harder. And net machinery
goes DOWN: every escalation upgrades an existing advisory or removes a channel; no
new always-on nag was added (the one new hinter fires on <2% of sessions, and an
ambient-noise hinter was disabled).

## What changes

| From | To | Why |
|---|---|---|
| (no stakes notion) | `stakes.json` config + `scripts/stakes-tier.sh` (longest-prefix → high\|low; unlisted-with-remote logged to `.stakes-pending.jsonl`) | scale friction to how much a wrong move costs (Versable*/gcc = high; local tooling = low) |
| `events.jsonl` rows | + `stakes` field (every event) and + `juror_health` field (ok\|bypassed\|timeout\|unparseable\|unavailable\|not-applicable) | session-precise stakes signal + measurable juror reliability without parsing suspect_fields |
| (no per-session atone state) | `.session-atone-slugs/<session>.json` (one line per atone) + `.breaker-fired` + `.fi-emitted` markers | the session-precise counter the circuit breaker and the fired-and-ignored detector read |
| juror inherits Opus, 200-line persona, frequent timeouts | `atone-juror-dispatch.sh`: model default **sonnet** (ambiguous→opus), compact prompt, `json.loads(strict=False)` | fox-guards-henhouse fix + the 4-min-timeout that caused the June juror-unavailable events |
| `ATONE_NO_JUROR=1` self-exempts silently on S3 | requires `ATONE_NO_JUROR_REASON`, recorded in suspect_fields | the agent may not silence its own oversight on the riskiest events |
| `guard-structural-claim.sh` non-blocking in ALL repos | high-stakes → BLOCK once (loop-safe step-aside), low-stakes → unchanged note; + "just a ..." phrasing + [UNVERIFIED] carve-out | the #1 recurrer (10×) was not bound by an advisory note |
| `guard-comment-hygiene.sh` advisory in ALL repos | high-stakes + unambiguous noise (plan-ref/archeology/pure-rule-line, EXCLUDING `[claude@]` blocks) → BLOCK | bind the unambiguous comment noise; preserve sanctioned agent-notes |
| `guard-subagent-output.sh` advisory in ALL repos | high-stakes + explicit material verb + no persist instruction → BLOCK | bind the unambiguous "material work, zero persistence" case; quick lookups stay advisory |
| (no circuit breaker) | `hinters/10-atone-circuit-breaker.sh`: same slug ≥2× in one session + (high-stakes OR cluster A/C/E) → hard STOP + precheck | the second same-session occurrence is the proven momentum signature |
| (no objective recurrence signal) | `scripts/hooks/atone-fired-and-ignored-check.sh` (Stop.tasks): slug ≥2×/session → objective `fired-and-ignored` to feedback.jsonl | converts the loop's central blind spot into a counted indicator, no agent diligence needed |
| (no efficacy measure) | `derived/intervention-efficacy.json` via new `build-efficacy.sh`: per slug, recurrence before/after its rule/hook shipped, split by stakes | the falsifiability backbone — read this, not raw counts, to know if a fix worked |
| `_meta.json` | + `juror_health` rollup | weekly juror reliability at a glance |
| `mistake-patterns.md` header | + "honest floor" note (gateable→~0, cognitive→down 20-35%, not zero) emitted by the consolidate builder | stop overselling "break the loop"; point at the efficacy metric |
| `hinters/50-atone-periodic-refresh.sh` (fires every 12 turns) | disabled (renamed `_disabled-...subsumed-by-breaker-and-dream-insights`) | turn-count ambient noise; its job is now done better by the breaker (at the moment) + dream-insights |
| `atone.sh` FEEDBACK_LOG hardcoded to $HOME | derived from `$ATONE_DIR` (like JUDGMENTS_LOG) | the ATONE_DIR override's stated purpose is isolated testing; feedback was the lone outlier |

## What does NOT change

- `events.jsonl` stays kernel-locked append-only; the new fields are added to NEW
  rows only. Older rows simply lack `stakes`/`juror_health` and bucket as
  "unknown"/"unset" in the splits — expected, not backfilled.
- Low-stakes repos see NO new blocking. All three escalated hooks keep their exact
  prior advisory behaviour there; only high-stakes + the unambiguous subset blocks.
- `[claude@]` agent-note blocks (permitted by `rules/comments.md`), em-dash, emoji,
  and long-comment-blocks are never blocked by comment-hygiene — advisory only.
- `30-atone-nudge.sh` (correction-time, real signal) is untouched.
- The juror still gates only S3 events; S2/S1 are `juror_health: not-applicable`.
- `triggers.json`, cluster pages, and the rest of the derived/ views are unchanged
  in shape.

## Verification

- [x] Circuit breaker (`10-atone-circuit-breaker.sh`): 6/6 e2e — fires on high-stakes
      repeat + on cluster-A repeat (real precheck pulled from events.jsonl), silent on
      low-stakes-uncategorized + single occurrence, dedups, honors `.breaker-off`.
- [x] guard-structural-claim: 8/8 e2e — high-stakes block, loop-safe step-aside,
      low-stakes note, file:line + [UNVERIFIED] carve-outs, "just a ..." form, mute.
- [x] T1.1 flips: 12/12 e2e — both hooks block only high-stakes + unambiguous subset;
      `[claude@]`-only and plan-ref-on-a-`[claude@]`-line NOT blocked; low-stakes
      advisory; subagent quick-lookup vs material-no-persist split preserved.
- [x] `build-efficacy.sh`: runs against real events; structural-claim before 4/after 7
      (worsened — surfaced honestly), infra-before-grep 5→1, declared-ready 5→1;
      differently-named-rule slugs mapped via content reference; null ship_date for
      un-intervened slugs. Valid JSON.
- [x] fired-and-ignored detector: 5/5 e2e (ATONE_DIR-isolated) — one feedback line per
      repeated slug, none for single occurrence, dedup on re-run, missing-counter safe.
- [x] `juror_health`: S2→not-applicable, S3+ATONE_NO_JUROR→bypassed (live); rollup
      buckets all six values (synthetic). The live ok/timeout/unparseable states are
      logic-verified (simple case block) + rollup-proven, not live-dispatched.
- [x] `bash -n` clean on all 9 modified scripts (incl. the load-bearing `atone.sh`).
- [x] All consolidate builders source + define their functions in the real driver.
- [ ] LIVE in-session confirmation of the two Stop-hook escalations + the breaker
      hinter (hooks/hinters load at session start, so the building session cannot
      self-test the blocking path end-to-end).

## Rollback

```bash
# Hooks: revert the three escalated guards + remove the new Stop task line.
cd ~/.claude
git checkout -- scripts/hooks/guard-structural-claim.sh \
  scripts/hooks/guard-comment-hygiene.sh scripts/hooks/guard-subagent-output.sh
# remove the fired-and-ignored line from scripts/hook-orchestrator/Stop.tasks
trash scripts/hooks/atone-fired-and-ignored-check.sh
# Hinters: drop the breaker, restore the periodic refresh.
trash hinters/10-atone-circuit-breaker.sh
mv hinters/_disabled-50-atone-periodic-refresh.sh.subsumed-by-breaker-and-dream-insights \
   hinters/50-atone-periodic-refresh.sh
# Consolidate: drop the efficacy builder + revert the meta/curated edits + driver.
trash scripts/atone-consolidate/build-efficacy.sh
git checkout -- scripts/atone-consolidate.sh scripts/atone-consolidate/build-meta.sh \
  scripts/atone-consolidate/build-curated-atone.sh scripts/atone.sh
# The new fields on already-written events.jsonl rows cannot be un-written (and
# need not be — consumers tolerate their absence). stakes.json / stakes-tier.sh /
# .session-atone-slugs/ are inert if nothing reads them.
```

Consider rollback if any escalated block traps a session on a false positive that
the mute file + loop-safe step-aside don't relieve, or if the breaker fires on
sessions it shouldn't (it shouldn't — it requires the same slug atoned twice).

## Notes / followups

- **Commit is pending the user's explicit go-ahead** (the session was told not to
  commit until instructed). The working tree is dirty with other sessions' work, so
  the commit must stage ONLY this initiative's files (see the session summary).
- F0 (stakes tiering), F1 (session counter + stakes stamp), T1.2 (rg-replace guard,
  already shipped), T1.3 (juror independence), T1.4 (bypass close) were implemented
  in the prior session; T2.1, T2.2, T1.1, T3.1, T3.2, T3.3, T4.1, T4.3 in this one.
  This migration documents the whole initiative's structural end-state.
- The efficacy metric, juror_health rollup, and the floor note are emitted by
  `atone-consolidate.sh` on its next run (cron every ~2 days, or `--force`).
- Honest ceiling (do not oversell): gateable classes → ~0, cognitive classes
  (structural-claim, speculative-abstractions — no greppable surface) → down 20-35%,
  measured by `intervention-efficacy.json`, not zero.
