<!-- i-dream project brief · 2026-07-27T00:45:33.818518+00:00 · 20 patterns / 10 insights -->
## What this project is about
A multi-agent IPC broker for Claude Code sessions — enabling cross-session messaging, peer discovery, and coordinated parallel work. Development style is exploratory and multi-agent-heavy, with repeated corrections around verification discipline and parallelism hygiene.

## Things to do (or keep doing)
- **Verify IPC delivery via round-trip reply**, not send-side logs or telemetry — a successful send proves nothing about receipt.
- **Reply to all unanswered peer messages before ending a session** — stop hooks fire repeatedly for each unreplied message; this is enforced, not advisory.
- **After any burst of parallel work**, treat all cached state (task lists, branch, file contents) as stale and re-read before acting.
- **Default gates to DENY for unrecognized inputs** — default-ALLOW on unknown CLIs/commands silently bypasses the entire access control layer.

## Things to avoid
- **Don't treat absence of failure as success** — zero-defaults fabricate plausible data, send-success masks non-delivery, clean diff ≠ working code; require a positive existence proof.
- **Don't claim a UI or runtime bug fixed without running the dev server** — inspection and diff review are not verification.
- **Don't use `rg -rn`** — `-r` means `--replace` in ripgrep, not recursive; it silently mangles output. Use `rg -n` for line numbers.
- **Don't route low-value go-aheads through the user** — batch sequential work autonomously and halt only at genuine branch points with enough context to answer in one shot.

## Open questions / known gaps
- Multi-agent ownership negotiation via IPC before parallel work begins is the stated solution to edit conflicts, but no pre-negotiation protocol is yet enforced mechanically.
- Orchestrator death leaving sub-agents blocked is a known failure mode with no dead-peer self-report timeout implemented yet.
