<!-- i-dream project brief · 2026-07-16T07:34:42.014549+00:00 · 20 patterns / 1 insights -->
## What this project is about
Multi-agent orchestration and IPC coordination work, likely on a product codebase, with heavy use of parallel sub-agent fleets, review pipelines, and cross-session message passing.

## Things to do (or keep doing)

- **Batch sequential work autonomously** — halt only at genuine decision points or destructive ops; never ask for lightweight go-aheads mid-run
- **Treat state writes as blocking obligations** — update tasks, reply to IPC peers, and commit agent edits immediately after completing each unit of work, not at session end
- **Checkpoint peer IPC aliases and session IDs** in core-dump artifacts so successor sessions can resume messaging without re-discovery
- **Prefer fleet coverage over per-item depth** on broad reviews — more agents at lower cost beats fewer expensive ones; salvage finished work and re-dispatch only failed agents on API errors

## Things to avoid

- **Don't confirm IPC delivery from send-side logs** — wait for an actual round-trip reply; the user rejects log-based assertions of successful delivery
- **Don't leave IPC peer queries unanswered at session end** — stop hooks fire repeatedly for each unreplied message; reply before closing
- **Don't strip technical substance when toning a document** — adjust register only; overcorrecting toward accessible prose leaves engineers without implementation detail
- **Don't defer task list reconciliation** — high-parallelism bursts silently stale the task list; reconcile explicitly after each sub-agent completion wave

## Open questions / known gaps

- IPC aliases become stale after a session restart; no clean fallback strategy is established — bare sessionId addressing works but isn't consistently used
- Interactive MCP input tools fail silently in TUI fullscreen mode; no established pattern for detecting this and falling back to prose prompts
