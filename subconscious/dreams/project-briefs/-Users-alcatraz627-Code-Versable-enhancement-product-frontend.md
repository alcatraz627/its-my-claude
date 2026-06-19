<!-- i-dream project brief · 2026-06-18T22:48:39.264561+00:00 · 20 patterns / 10 insights -->
## What this project is about
Frontend of the Versable enhancement product — a multi-session, long-running feature development context where the dominant working style is autonomous execution within tight scope gates, with heavy reliance on session continuity tooling.

## Things to do (or keep doing)
- **Checkpoint proactively**: run `/core-dump` at milestones and whenever context approaches 70% — don't wait to be asked; `/catchup` is the primary recovery path after compaction
- **Confirm the task boundary at session start**, then execute autonomously and aggressively within it — terse user messages ("keep going", "move") mean "resume from WAL/checkpoint state, don't ask again"
- **Reconstruct from WAL/checkpoint first** when resuming via "this session being continued from" — re-read task state before taking any action

## Things to avoid
- **Never commit or push without explicit, fresh, per-operation approval** — prior session approval does not carry forward, ever; this is the single highest-severity recurring violation in this project's history
- **Don't expand scope beyond what was explicitly requested** — no "while I'm here" improvements; the user has corrected this pattern multiple times across sessions
- **Don't re-run sub-agents that already wrote output to disk** — triage before re-dispatching after failures

## Open questions / known gaps
- Pattern deduplication in session memory is unreliable — the same WAL migration event appears 4+ times as separate entries; treat repeated pattern signals as noise until deduplicated
- Scope-gating vs. autonomous execution creates ongoing tension: confirm the gate once at session start, then don't re-ask mid-task
