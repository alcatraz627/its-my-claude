<!-- i-dream project brief · 2026-05-29T23:25:23.417841+00:00 · 20 patterns / 10 insights -->
## What this project is about
A Next.js frontend product (Versable enhancement-product) with long multi-session implementation cycles, heavily reliant on /core-dump and /catchup for state continuity across context compactions.

## Things to do (or keep doing)
- **Checkpoint proactively**: run /core-dump at every major milestone and before context hits 70% — don't wait for the end of a session
- **Reconstruct intent from WAL/checkpoint on entry**: when starting with "this session being continued from", read the checkpoint file before doing anything else
- **Scope-gate before executing**: confirm the task boundary explicitly at session start; within it, execute autonomously; outside it, do nothing

## Things to avoid
- **Never commit or push without fresh per-push approval** — prior approval in the session does not carry over; each push requires an explicit in-turn "yes, push this"
- **Don't expand scope silently** — even "obvious improvements" outside the stated task are violations; ask first
- **Don't treat session-level approval as blanket authorization** — one approval covers one action, not a class of future actions

## Open questions / known gaps
- Pattern extraction is over-indexing on the WAL markdown→JSONL migration (appears 4+ times); deduplication of near-identical patterns is a known gap in the memory/atone pipeline
- Tension between "minimal changes" preference and "50-150 tool autonomous sessions" is real but resolved by scope-gating: confirm boundary once, then execute fully within it
