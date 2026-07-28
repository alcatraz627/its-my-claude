<!-- i-dream project brief · 2026-07-28T01:06:54.234726+00:00 · 20 patterns / 10 insights -->
## What this project is about
Cross-session IPC broker for Claude Code agents — enabling peer discovery, message routing, and multi-agent coordination. Work is typically multi-agent: concurrent sessions coordinating via this system while also dogfooding it.

## Things to do (or keep doing)
- **Pre-negotiate task ownership via IPC before parallel work begins** — overlapping claims without coordination produces clobbered edits and drift.
- **Verify IPC delivery with a round-trip reply**, not send-side logs or telemetry — a successful send is not proof of receipt.
- **Default access-gate decisions to DENY on unknown input** — a default-ALLOW fallback for unrecognized CLIs renders the entire gate bypassable.
- **After any parallel burst, treat all cached state as stale** — task lists, branch state, file contents all drift; re-sync before acting.

## Things to avoid
- **Don't use `rg -rn`** — `-r` is `--replace`, not recursive; use `rg -n` for line numbers.
- **Don't quote IPC message bodies with backticks in shell** — special characters get consumed, producing zero-byte or corrupted messages; escape or use a heredoc.
- **Don't claim a bug is fixed without exercising the fix on the running dev server** — repeated false-assurance cycles are a known trust-damager here.
- **Never commit or push** — this repo is protected; prepare the diff and hand it to the user.

## Open questions / known gaps
- Unanswered peer queries at session end trigger repeated stop-hook fires — there's no clean session-teardown handshake yet.
- Default-open bias (re-enabling disabled configs, over-generalizing scope) recurs across sessions; the gate infrastructure exists but enforcement is incomplete.
