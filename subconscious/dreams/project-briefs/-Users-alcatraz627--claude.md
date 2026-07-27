<!-- i-dream project brief · 2026-07-27T00:44:37.967809+00:00 · 20 patterns / 10 insights -->
## What this project is about
The `~/.claude` meta-configuration project: behavioral rules, scripts, hooks, and tooling that govern every Claude Code session on this machine. Work is often multi-agent (IPC-coordinated parallel sessions) and involves both the config infrastructure itself and downstream product sessions it governs.

## Things to do (or keep doing)
- **Require a round-trip reply, not a send-success log, to confirm IPC message delivery** — successful send is not successful receipt.
- **Audit every page/surface that could trigger a shared UI component before writing any code** — per-page variants are the recurring failure mode.
- **Include full context in every handoff artifact** (deferred decision, citation, checkpoint) so the receiver can act without a follow-up question.
- **Prefer breadth-first v1 passes** — sweep all surfaces before polishing any one item.

## Things to avoid
- **Don't claim a UI or runtime fix is done without exercising it on the actual running dev server** — "looks right" is not verification; false assurance here is a trust-damaging anti-pattern.
- **Don't use `rg -rn`** — `-r` means `--replace`, silently mangling output; use `rg -n` for line numbers in recursive searches.
- **Don't route low-value traffic through the user** (rubber-stamp go-aheads, underspecified decision questions) — batch sequential autonomous work and halt only at genuine forks.
- **Don't emit zero-defaults when source data is missing** — fabricated numeric values produce plausible-looking but wrong downstream results.

## Open questions / known gaps
- **Partial-observation verification is a persistent blind spot**: single visual mode, single code path, or proxy evidence (compile pass, send-success) is treated as full verification — multi-state enumeration before claiming done is not yet habitual.
- **State-sync degrades exactly when parallelism is highest**: task lists, git state, and peer ownership all drift during bursts of parallel work — the sync rules are known but deprioritized under velocity.
