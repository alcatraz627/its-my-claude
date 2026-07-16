<!-- i-dream project brief · 2026-07-15T18:50:35.630158+00:00 · 20 patterns / 4 insights -->
## What this project is about
This is the `~/.claude` meta-configuration project — rules, skills, hooks, scripts, and memory that govern all Claude Code sessions on this machine. Work here is infrastructure-level and directly affects every concurrent agent.

## Things to do (or keep doing)
- **Breadth-first pass first**: sweep all affected surfaces before polishing any single item; partial completions leave peers operating on stale assumptions
- **Treat state-ledger writes as blocking**: TaskUpdate, IPC reply, and git commit of agent edits must execute immediately after completing a unit of work — deferring them is the primary source of drift
- **Re-verify state at action time**: task ownership, file contents, and config validity are point-in-time snapshots — re-read before acting, never trust planning-time state
- **Dispatch an adversarial reviewer after implementing complex features**: a fresh sub-agent reliably catches HIGH-severity bugs the authoring agent misses

## Things to avoid
- **Don't touch or drop guard mute-files**: dropping a mute file disables a safety gate machine-wide for all concurrent sessions until manually removed
- **Don't claim IPC delivery from sender logs**: confirm round-trip receipt from the peer; log inspection is not delivery confirmation
- **Don't use `rg -rn`**: `-r` means `--replace`, silently mangling output; use `rg -n` for line numbers in recursive searches
- **Don't default-zero on missing data**: `bb.get('x', 0)` fabricates plausible values; prefer an explicit error when input is unknown

## Open questions / known gaps
- Multi-agent task-list staleness: agents starting items already completed by peers is a recurring coordination failure with no mechanical gate yet
- IPC reply discipline at session end: unreplied peer queries trigger repeated stop-hook fires; no systematic enforcement beyond the hook reminder
