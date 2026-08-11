<!-- i-dream project brief · 2026-08-10T11:58:08.186471+00:00 · 20 patterns / 8 insights -->
## What this project is about
Multi-agent Claude Code orchestration tooling — IPC messaging, session coordination, and shared UI across peer agents. Dominant working style is autonomous multi-turn execution with periodic human check-ins only at genuine blockers.

## Things to do (or keep doing)
- **Verify EFFECT, not OUTPUT** — after sending an IPC message, wait for a round-trip reply; after a UI fix, open the page; after a build, run it. Send-success, compile-pass, and notification-received are proxies, not proof.
- **Fix the PATTERN across the whole app** — when a UI element (drawer, nav shell, pagination) needs fixing, audit every sibling instance before reporting done; a per-page fix is a missed fix.
- **Surface the blocker explicitly** — when pausing mid-task, state the stopping condition (blocker, auth needed, decision required) in the same turn; don't make the user ask why.
- **Increase state-sync frequency under parallelism** — update the Task tool after each logical unit; high edit velocity is exactly when deferred updates cause the most drift.

## Things to avoid
- **Don't treat agent-produced artifacts as ground truth** — agent-authored docs, send logs, and mental-model gap assessments are derivatives; verify against user-authored specs, round-trip replies, and actual source files.
- **Don't route rubber-stamp check-ins through the user** — batch sequential autonomous work; halt only when a genuine decision or credential block requires human input, and when deferring an item to a backlog always include the prior decision context and at least two concrete options.
- **Don't verify CSS class names by intuition** — confirm utility class names exist in the project's actual stylesheet or framework config before use.
- **Don't attempt to automate CLI auth steps** — flag interactive-terminal-required commands (cloud logins, browser OAuth) up front and hand the exact command to the user rather than hanging or retrying.

## Open questions / known gaps
- IPC peer alias resolution: a descriptive alias name is not guaranteed to map to the intended live session — verify peer IDs before every send, or false-delivery will recur.
- macOS `timeout`/`gtimeout` absence silently orphans child processes; any long-running shell wrapper needs the pgid-kill pattern or it doesn't actually cap execution.
