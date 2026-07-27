<!-- i-dream project brief · 2026-07-18T06:39:54.562146+00:00 · 6 patterns / 0 insights -->
## What this project is about
Personal Claude Code configuration and tooling workspace (`~/.claude`); work spans automation scripts, hooks, skills, and multi-agent IPC infrastructure. Dominant style is incremental hardening — each session graduates a recurring mistake into a rule or hook.

## Things to do (or keep doing)
- Verify IPC peer aliases map to live peer IDs before sending cross-session messages — stale aliases route silently to the wrong session
- Update the Task tool after each logical unit of work; never batch task updates at session end
- Implement shared UI/navigation elements from a single source component, never replicate per-page
- Verify planning docs are current before acting on them after any significant phase gap — superseded plans silently redirect effort

## Things to avoid
- Don't absorb or push commits created by sibling sessions in a shared repo — identify them and leave them alone to avoid ownership collisions
- Don't attribute a high-fire/zero-conversion hook to implementation failure before confirming it's attached to the correct event type
- Don't batch-verify multiple changes at once; verify each independently before moving on
- Don't create tasks, rules, or skill entries without checking for existing equivalents first — duplication is the dominant anti-pattern in this repo

## Open questions / known gaps
- Hook event-type mismatches are a recurring silent failure class with no systematic detection step in the hook-authoring workflow
- No clear signal yet on when to prefer inline work vs. spawning a sub-agent for `~/.claude` maintenance tasks
