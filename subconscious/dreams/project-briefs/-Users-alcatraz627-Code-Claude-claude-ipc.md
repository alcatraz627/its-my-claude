<!-- i-dream project brief · 2026-07-29T02:41:43.918244+00:00 · 20 patterns / 10 insights -->
## What this project is about
Cross-session IPC broker for Claude Code agents — a CLI tool enabling peer messaging, session registration, and multi-agent coordination. Work is predominantly Go/shell, with parallel-agent workflows as a first-class concern.

## Things to do (or keep doing)
- Verify IPC delivery at the **reception point** (round-trip reply or peer-confirmed receipt), never at send-side telemetry alone
- Default gates to **DENY** for unrecognized commands; absence of a match is never ALLOW
- Pre-negotiate task ownership via IPC before parallel agents begin overlapping work
- Quote IPC message bodies with `printf %q` or heredocs — backticks and special characters are consumed by the shell and produce zero-byte messages

## Things to avoid
- Don't use `rg -rn` expecting recursive+line-numbers — `-r` is `--replace`; use `rg -n` for line numbers
- Don't treat send-success as delivery-confirmed; a successful enqueue proves nothing about the peer reading the message
- Don't synthesize a plausible default (zero, false, ALLOW) when a lookup returns empty — emit UNCERTAIN or DENY and surface the gap
- Don't leave unanswered peer queries at session end; stop hooks fire repeatedly for each unreplied IPC message

## Open questions / known gaps
- Multi-agent parallel edits to shared state (task lists, branch state) consistently go stale under burst conditions — no coordination protocol yet enforced at the harness level
- The line between "implementation detail" and "product decision" gets drawn too broadly; naming and behavioral choices need an upstream authority check before being resolved as code conventions
