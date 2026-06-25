<!-- i-dream project brief · 2026-06-21T16:46:50.221937+00:00 · 20 patterns / 10 insights -->
## What this project is about
Dream-tracking dashboard (iDream) with widgets, pm2 services, and Anthropic API integration. Sessions are long, multi-day, and frequently span context compaction boundaries — session continuity is the dominant operational concern.

## Things to do (or keep doing)
- Write `/core-dump` at milestones (every ~30 tool calls, before risky ops, before area switches) — not only at session end; `/catchup` is the primary recovery path
- Treat single-word or two-word user messages (`next`, `keep going`, `ahead`, `started`) as autonomous-continue signals; reconstruct intent from WAL/checkpoint state and emit a one-line ack, then execute
- Write WAL entries as JSONL (canonical since 2026-04-17); never revert to markdown format
- Scale execution depth on terse signals, never scope — "keep going" means continue the declared task, not expand it

## Things to avoid
- Never `git commit` or `git push` without fresh, per-operation explicit approval — prior approval in the same session does not carry over
- Never infer, extrapolate, or hallucinate data values in structured data processing; only output values directly traceable to source data (user called this a "serious trust killer")
- Never write shared credentials or session-provided secrets to any file, even temporarily
- Never expand scope beyond what was explicitly requested, even for "obvious" improvements

## Open questions / known gaps
- Tension between terse-continuation = "execute autonomously" and scope-as-ceiling = "never expand" — when a task requires a non-trivial scope pivot, pause and surface it rather than guessing which way the signal points
