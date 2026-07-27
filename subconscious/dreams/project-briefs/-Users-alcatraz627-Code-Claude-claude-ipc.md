<!-- i-dream project brief · 2026-07-27T20:02:45.091416+00:00 · 20 patterns / 10 insights -->
## What this project is about
Cross-session IPC broker for Claude Code: agents communicate via message-passing, coordinate task ownership, and relay state across concurrent sessions. Dominant style is multi-agent coordination with shell-based tooling.

## Things to do (or keep doing)
- **Verify delivery via round-trip ack**, not send-side telemetry — a successful send does not prove the peer received; wait for an explicit reply or poll the peer's inbox
- **Default-DENY on unrecognized commands** in any access-gate — a default-allow fallback for unknown CLIs renders the gate bypassable
- **Pre-negotiate task ownership via IPC** before parallel agents start work — overlapping edits without coordination produces conflicts that are expensive to untangle
- **Quote all IPC message bodies with printf/heredoc**, never bare backticks — special characters get shell-consumed and produce zero-byte or corrupted messages

## Things to avoid
- **Don't treat send-success as delivery proof** — locally-produced artifacts (send logs, telemetry) are not ground truth about remote state; the peer's ack is
- **Don't leave peer queries unanswered at session end** — stop hooks fire repeatedly for each unreplied message; reply before exiting
- **Don't use `rg -rn`** — `-r` is `--replace`, not recursive; use `rg -n` for line numbers in recursive searches
- **Don't halt for sequential go-aheads** — batch autonomous progress and interrupt only at genuine decision points that require user-held information

## Open questions / known gaps
- After parallel bursts, task lists and branch state go stale simultaneously — no single sync point owns the reconciliation step; this is a recurring coordination gap
- Absence-of-signal is sometimes emitted as a definite result (zero, false, ALLOW) rather than UNCERTAIN/DENY — fabricated defaults have caused gate bypasses in this codebase
