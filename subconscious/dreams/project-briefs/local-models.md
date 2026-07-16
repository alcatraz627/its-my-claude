<!-- i-dream project brief · 2026-07-16T07:36:43.098341+00:00 · 20 patterns / 2 insights -->
## What this project is about
Local model orchestration suite (`~/Code/local-models`) with multi-agent IPC coordination as a central working pattern. Sessions frequently involve parallel agents, shell tooling, and CLI wrappers for local LLMs.

## Things to do (or keep doing)
- **Pre-negotiate task ownership via IPC before parallel agents start** — overlapping claims without coordination produces duplicate work and merge conflicts.
- **Treat state-ledger writes (TaskUpdate, IPC replies, commits) as blocking obligations** — execute them immediately after completing each unit of work, not batched at milestones.
- **Breadth-first v1 pass before polishing** — sweep all surfaces first; pausing to perfect one area while others are untouched wastes parallel opportunity.
- **Verify IPC delivery via round-trip reply**, not send-side logs — a successful send is not evidence of delivery.

## Things to avoid
- **Don't use `rg -rn`** — `-r` is `--replace`, not recursive; use `rg -n` for line numbers in recursive searches.
- **Don't default access gates to ALLOW for unrecognized input** — unknown commands must DENY; patching one specific CLI to a fallback list without fixing the structural default leaves the bypass open.
- **Don't pass backtick-containing strings in shell IPC sends** — shell consumes them and produces zero-byte or corrupted messages; use heredoc or file-based body.
- **Don't touch or drop guard mute files from sub-agents** — a dropped mute disables the guard machine-wide across all concurrent sessions.

## Open questions / known gaps
- Task list drift under parallel load is a recurring failure — the stop hook catches it after the fact, but no pre-emptive coordination pattern has been locked in yet.
- macOS `timeout` workaround (process-group kill via Perl) is documented but not consistently applied in new scripts.
