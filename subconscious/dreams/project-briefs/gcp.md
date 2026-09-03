<!-- i-dream project brief · 2026-09-02T05:47:00.502356+00:00 · 20 patterns / 4 insights -->
## What this project is about
GCP is a multi-agent, multi-session engineering project with heavy use of fan-out research, UI iteration, and cross-agent synthesis. The dominant working style is autonomous execution with owner-gated confirmations only for irreversible or identity-establishing decisions.

## Things to do (or keep doing)
- **Verify at the destination, not the source**: confirm file existence with `fd`/`rg --no-ignore`, IPC delivery by reading the inbox, and process output by reading the output path — never infer from own logs.
- **Re-ground synthesis agents against human-authored upstream docs** before writing any final report; agent-generated docs silently contaminate downstream audits.
- **Proceed autonomously on terse continuations and reversible steps**; pause only for decisions that establish identity, scope, or external visibility.
- **Always use absolute paths in user-facing replies** — bare basenames and repo-relative paths break terminal hyperlinking and force follow-up questions.

## Things to avoid
- **Don't claim done/works/fixed without executing the changed code path** — the declared-ready gate fires on this and correctly blocks; citing compile success or lint pass is not execution.
- **Don't gate sub-items after broad authorization is already granted** — when the user says "proceed with all," inventing new blocking prompts per sub-item ignores explicit authority.
- **Don't iterate on UI changes without a visual verification mechanism** — token-spend on UI with no screenshot read is waste; acknowledge when you can't verify rather than asserting success.
- **Don't assert absence of a module or file from a narrow-scoped search** — run `rg --no-ignore` or `fd` over the full relevant tree before claiming something doesn't exist.

## Open questions / known gaps
- Recurring tension between multi-clause goal conditions and partial completion: the agent repeatedly reports progress when only some conjunction clauses are satisfied; no mechanical gate catches this.
- Prose drift reasserts within a session even after mid-session correction — the periodic re-check pattern (every 10-15 tool calls) is documented but not mechanically enforced here.
