<!-- i-dream project brief · 2026-07-16T07:38:01.487001+00:00 · 20 patterns / 2 insights -->
## What this project is about
A multi-agent IPC broker for Claude Code sessions — cross-session messaging, peer registration, and delivery guarantees. Dominant style: infrastructure-first, parallel agent coordination, live-exercise verification over test-coverage claims.

## Things to do (or keep doing)
- **Breadth-first before polish**: sweep all surfaces on a v1 pass; pausing mid-sweep to perfect one item breaks coherence.
- **Batch sequential steps autonomously**: halt only at genuine decision points or critical reviews — never for lightweight go-aheads.
- **Confirm IPC delivery via round-trip reply**, not log inspection; a successful send is not a successful delivery.
- **Treat state-ledger writes as blocking obligations**: IPC replies, task updates, and commit steps execute immediately after completing a unit of work — deferring them as bookkeeping compounds under parallelism.

## Things to avoid
- **Don't default-allow for unrecognized input**: access gates, CLI fallbacks, and data extractors must emit DENY/error on unknown input, never a plausible-looking default that suppresses investigation.
- **Don't use `rg -rn`**: `-r` is `--replace`, not recursive+line-numbers; use `rg -n` for line numbers.
- **Don't pass IPC message bodies through unquoted shell**: backticks and special characters corrupt or zero the payload — quote or heredoc the body.
- **Don't patch a specific instance without fixing the structural default**: one-off CLI additions to a fallback list leave the same class of gap open for the next caller.

## Open questions / known gaps
- Pre-negotiation protocol for parallel agents claiming overlapping task ownership is referenced but not formalized — coordination races have caused muddy diffs.
- CLI auth steps (cloud logins) require an interactive terminal; no automated fallback path exists yet.
