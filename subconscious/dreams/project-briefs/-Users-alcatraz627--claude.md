<!-- i-dream project brief · 2026-06-09T20:14:00.344921+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the user's global `~/.claude` configuration repo — skills, rules, hooks, WAL infrastructure, and cross-session memory. Work here is meta: maintaining and evolving the agent harness itself.

## Things to do (or keep doing)
- **Checkpoint proactively** with `/core-dump` at milestones, not just session end — `/catchup` is the primary recovery path after compaction
- **Treat terse single-word messages** (`next`, `ahead`, `looks`, `done`) as autonomous-continue directives; increase execution depth, never scope
- **Write WAL entries as JSONL** — the markdown format is legacy; canonical format is JSONL since 2026-04-17, use `scripts/wal/wal.sh`
- **Verify current state before acting** — re-read files, re-check git status; never assume state from earlier in the session

## Things to avoid
- **Never commit or push without fresh explicit per-push approval** — prior approval in the session does not carry over; this is the single most-corrected pattern in this repo
- **Don't fix-thrash** — if a fix attempt fails, stop and form a root-cause hypothesis before trying another patch
- **Never infer or synthesize data values** not explicitly present in source material; flag gaps instead of filling them silently
- **Don't expand scope** beyond the explicit request, even for obvious improvements

## Open questions / known gaps
- Pattern extraction in the atone/affirm pipeline lacks deduplication — the same event (WAL migration) appears 4× as separate patterns; the consolidation script needs a semantic-similarity pass
- Tension between terse-continuation (autonomous execute) and scope-ceiling (don't expand) has caused confusion; when the active task is ambiguous after a `/clear`, clarify before resuming
