<!-- i-dream project brief · 2026-08-06T03:34:29.434080+00:00 · 20 patterns / 10 insights -->
## What this project is about
The user's personal `~/.claude` configuration repository — behavioral rules, skills, hooks, memory systems, and agent tooling. Work here is meta: changes affect every Claude session on the machine.

## Things to do (or keep doing)
- **Prefer direct evidence over proxy signals** — verify at the consumer end (message received, code path exercised, file exists) before claiming success; send-success / test-pass / compile-clean are not verification.
- **Always enumerate the full instance set** after finding or fixing one case — one page, one hook, one rule is never the whole class.
- **Execute terse continuations immediately** — "proceed", "keep going", "yes" means continue the current task without clarifying questions when context pressure is below 70%.
- **Strip all internal banter before writing any externally-shared document** — docs that leave this session may go directly to stakeholders.

## Things to avoid
- **Don't treat absence of data as a definite answer** — zero-defaults, ALLOW-on-empty, and fabricated plausible values all share the same failure shape; emit UNCERTAIN or DENY instead.
- **Don't generalize from one instance without auditing the full class** — UI components, skill phases, rule enforcement, and IPC patterns all require a full-set sweep before declaring done.
- **Don't defer items to a backlog without including decision context** — stripped-context deferrals force the user to reconstruct what was being decided before they can act.
- **Don't claim a UI or runtime fix is done without exercising it on the running app** — repeated false-assurance cycles on dev-server behavior are an established trust-damaging pattern here.

## Open questions / known gaps
- **IPC coordination under parallelism** — multi-agent sessions routinely clobber state (task lists, edits, ownership) when throughput is high; a pre-negotiation protocol exists but isn't consistently enforced.
- **Two-agent peer-review workflow** — user deliberately runs independent plan → grade cycles; the agent repeatedly collapses outputs into merged synthesis rather than maintaining the side-by-side contrast the workflow requires.
