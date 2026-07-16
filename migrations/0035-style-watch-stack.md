# 0035 — async style watcher (Stop-hook stack, absorbs prose-smell as tier 0)

## Summary

Turn-boundary watcher for INTERNAL surfaces only: `scripts/hooks/style-watch-stop.sh`
(Stop, registered after prose-smell; collects the session's edited files, drops
critic-gated artifacts via the sha-keyed voice-passed marker, spawns a DETACHED
worker — zero turn latency) → `scripts/style/style-watch-worker.sh` (tier
resolution approximating scope-map.json; tier-0 free screen: detect.py for code,
tells-regex for prose; tier-2 sonnet via `claude -p --output-format json`, capped
1 call/run, may cite ONLY active thesaurus entry ids) →
`hinters/02-style-watch.sh` (next-turn injection, cwd-scoped, consume-on-deliver,
24h age-out). Telemetry (instances + real token counts) →
`logs/style-watch.jsonl`; `thesaurus.sh review` prints the kill-or-keep block.
Chat prose stays prose-smell's lane; deliverables stay the readers-advocate
critic gate's lane (mig 0034) — the watcher never re-nags either.

## Why

Audit P19 + user design corrections 2026-07-16: post-delivery nudges about a
report the user already read arrive exactly when they give their own feedback
(validated fear) — so deliverables get the SYNCHRONOUS critic gate and the
watcher covers only in-flight internal surfaces; gemini/local screens, sonnet
judges; no freelance taste (entry ids only); telemetry from day one because the
prose-smell precedent (60 fires, heeded:unknown, review parked) shows a watcher
without a working feedback loop is expensive noise.

## Verification (all exercised live, 2026-07-16)

Fake-judge e2e (fire → note → inject → consume → processed-dedupe) · clean-file
skip (`watcher-skip medium/screen-clean`) · critic-marker suppression ·
wrong-cwd isolation · REAL sonnet run: 3 findings, entry `thes-20260716-165410-4a`
cited, 109,492 tokens logged (mostly cache-read from the nested CLI — the cost
evidence for the screen-first + 1-call-cap design).

## Files affected

`scripts/hooks/style-watch-stop.sh` (NEW) · `scripts/style/style-watch-worker.sh`
(NEW) · `hinters/02-style-watch.sh` (NEW) · `scripts/style/thesaurus.sh`
(review: telemetry block) · `settings.json` (Stop registration; pre-edit backup
at /tmp/settings.json.bak-prewatch) · `migrations/MIGRATIONS.md` (row).

## Kill switches / caps

`touch ~/.claude/.no-style-watch` (machine-wide) · `STYLE_WATCH_OFF=1` (process)
· `STYLE_WATCH_TIER2_CAP` (default 1 sonnet call/run) · worker caps 3 files/run,
20/batch · notes age out at 24h. Weekly `thesaurus.sh review` is the
kill-or-keep checkpoint: if heed-rate stays "unknown"/low, retire the watcher
rather than mute-and-forget.

## Phases

1. ✅ 2026-07-16 — everything above.
2. ⏳ Heed-rate automation (today the injected note asks the agent to log
   `--heeded yes|no`; measure compliance at the first weekly review).
3. ⏳ Tier-1 lm/gemini screen between regex and sonnet (worker goes straight
   regex→sonnet today; add `llm-mini` screen if fire volume makes sonnet spend
   material).
4. ✅ 2026-07-16 — prose-smell P6 verdict (user): STAYS DRY-RUN. Grounds: heed
   metric only accurate since the C1 fix (61 fires/July, 6 heeded:true post-fix),
   both source RCAs asked flag-not-block, file lane now covered by the critic
   gate. Re-review ~2026-08-16 with a clean month of heed data; escalation path
   if heed <~30%: review option (b), block on two structural tells, em-dash
   demoted to warn.

## Recovery

Remove the settings.json Stop entry (or `touch ~/.claude/.no-style-watch`),
delete the three NEW scripts + `style/pending-watch-notes.txt` +
`style/.watch-processed-*`. Telemetry log keeps (data ledger).

## Cross-references

mig 0033 (thesaurus/scope-map consumed) · mig 0034 (critic marker this dedupes
against) · `assets/reports/20260716-gcc-structural-audit/REPORT.md`
