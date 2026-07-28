<!-- i-dream project brief · 2026-07-28T01:06:28.160876+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the user's global Claude Code configuration repo (`~/.claude`) — skills, rules, hooks, atone ledger, memory system, and agent tooling. Work here shapes the behavior of every future Claude session machine-wide.

## Things to do (or keep doing)
- Always use full absolute/relative paths in output — basenames alone aren't clickable in Ghostty
- Batch sequential low-stakes work autonomously; halt only at genuine branch points or irreversible ops
- Embed full context (options, rationale, prior decision) when creating deferred items — never make the user ask a follow-up to act on a question you raised
- Verify claims against the canonical source: running process, file on disk, actual output — not send-side logs, test-pass counts, or derivative artifacts

## Things to avoid
- Don't treat `rg -rn` as "recursive + line-numbers" — `-r` is `--replace` and silently mangles output; use `rg -n` only
- Don't claim a fix works without exercising it on the running system — false assurance cycles damage trust fast here
- Don't route low-value traffic through the user (polling proxies, rubber-stamp go-aheads, underspecified decision questions)
- Don't skip mandatory skill gate phases (adversarial validation, etc.) and mark tasks complete — this project enforces its own rules on itself

## Open questions / known gaps
- Multi-agent IPC sessions leave unreplied peer queries at session end; stop hooks fire repeatedly until cleared — ownership discipline under parallelism is still fragile
- Design-mock consultation before UI work is a recurring S3 blind spot even after explicit rules; needs a pre-implementation checklist step, not just a reminder
