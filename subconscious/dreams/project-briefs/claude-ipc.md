<!-- i-dream project brief · 2026-07-27T20:03:20.551429+00:00 · 20 patterns / 6 insights -->
## What this project is about
claude-ipc is a cross-session IPC broker for Claude Code instances — named-session registration, message delivery, and peer discovery. Work style is verification-heavy with a hard boundary between "sent" and "received."

## Things to do (or keep doing)
- **Survey the full affected surface before writing any code** — enumerate all sibling pages, consumers, or states that share a pattern; depth-first on the first item encountered is the recurring failure shape here
- **Run the actual code path to confirm delivery** — send-success is a proxy, not proof; dogfood the IPC path end-to-end before claiming a message flow works
- **Propagate uncertainty on empty lookups** — when a probe returns nothing, emit UNCERTAIN/DENY, never a synthesized zero or default-ALLOW
- **State blocking conditions explicitly** — if pausing mid-task, name the stopping reason and what the user must do; silent pauses cost a check-in round-trip

## Things to avoid
- **Don't treat send-success as delivery confirmation** — the failure mode is a plausible-looking positive (exit 0, success status) that masks non-delivery; verify the receiver side
- **Don't patch one instance of a pattern** — when fixing a bug or applying a convention, find all callsites/pages that share the same shape before declaring done
- **Don't commit or push without explicit user instruction** — this project is in the protected-repos registry; prepare the diff and hand it to the user
- **Don't source UI labels or flows from code conventions** — consult design mocks first; internal naming patterns have caused complete rework

## Open questions / known gaps
- Recurring tension between proxy evidence (test-pass, send-log) and direct evidence (actual peer receipt) — verification gates may need architectural reinforcement
- Task lists drift silently across long sessions; reconcile with the Task tool before stopping on any multi-turn change
