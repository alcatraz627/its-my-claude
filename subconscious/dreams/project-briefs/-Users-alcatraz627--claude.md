<!-- i-dream project brief · 2026-07-27T20:03:44.725231+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the user's global Claude configuration and tooling repo (`~/.claude`) — behavioral rules, scripts, hooks, skills, and agent-facing conventions. Work here directly shapes every future Claude session; changes have machine-wide blast radius.

## Things to do (or keep doing)
- **Always consult the canonical source before claiming anything**: design mocks for UI labels, source code for gap assessments, running app for bug verification — never derive from memory or internal naming.
- **Enumerate all consumers before fixing a pattern instance**: one callsite, one page, one rule file is never the full surface — grep and fix the class, not the example.
- **Batch sequential work autonomously**; halt only at genuine decision forks with full prior context + concrete options included in the question.
- **Verify round-trip, not send-side**: IPC delivery is proven by the peer's ack, not the sender's log; a fix is proven by exercising the running path, not by it compiling.

## Things to avoid
- **Don't treat absence of signal as a definite value**: missing data → emit UNCERTAIN/DENY, never fabricate a zero-default or plausible positive.
- **Don't patch one instance when the class is broken**: after any correction that a component must be global or shared, search and fix ALL instances in the same response.
- **Don't commit or push for protected repos** — prepare the diff, show it, hand the commit to the user explicitly.
- **Don't use `rg -r`** for recursive search — `-r` is `--replace` in ripgrep; use `rg -n` for line numbers.

## Open questions / known gaps
- Multi-agent parallel sessions consistently degrade state bookkeeping (task lists, branch state, ownership) — no reliable sync protocol established yet.
- IPC reply discipline (unreplied peer queries at session end) fires stop hooks repeatedly; a clean shutdown contract is still unresolved.
