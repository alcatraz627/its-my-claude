<!-- i-dream project brief · 2026-07-24T10:14:45.324764+00:00 · 20 patterns / 10 insights -->
## What this project is about
A multi-instance Claude widget dashboard with IPC coordination, live runtime state, and UI components — worked in parallel sub-agent bursts with frequent scope and verification failures.

## Things to do (or keep doing)
- **Always exercise the live running app** before claiming a fix works — test coverage alone is insufficient; runtime dogfooding catches what 99+ tests miss
- **Audit every page** before writing a new UI drawer, sidebar, or shell component — build one globally-shared component, not per-page variants
- **Emit DENY/UNCERTAIN** when a gate or probe returns empty/unknown — never synthesize a zero-default or ALLOW from absent data
- **Update TaskUpdate at each state change** — after parallel work bursts, treat all cached state (task lists, branch state, file contents) as stale and re-verify before acting

## Things to avoid
- **Don't patch one instance of a structural violation** — fixing one CLI in a fallback list while the default-ALLOW bypass remains open leaves the gate broken; fix the class
- **Don't present deferred decisions without prior context and concrete options** — forcing the user to ask a follow-up to reconstruct what was already decided wastes a round-trip
- **Don't claim UI verified if only one visual mode was tested** — annotate findings with which mode was observed; dark-only sign-offs that miss light-mode are invalid
- **Don't treat a directional correction as an absolute** — "too noisy" means tune down, not off; "only for X" means scope it, not add self-gating flexibility

## Open questions / known gaps
- **Parallel sub-agent coordination is brittle** — agents must pre-negotiate task ownership via IPC before starting; no enforcement mechanism is in place yet
- **Derived artifacts displace upstream authority** — agent-authored formalizations and instance-level patches silently become the working spec; the user's product spec must stay the authority
