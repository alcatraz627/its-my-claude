<!-- i-dream project brief · 2026-08-06T03:57:22.421908+00:00 · 20 patterns / 5 insights -->
## What this project is about
i-dream is a dream-tracking/memory-consolidation system with a multi-widget dashboard UI, background agents, and IPC-coordinated peer-review workflows. Work is predominantly UI-heavy with concurrent sub-agent sessions operating in parallel.

## Things to do (or keep doing)
- Prefer the two-agent mutual peer-review pattern: each agent produces an independent plan, then grades the other's — never collapse outputs into a merged recommendation without explicit instruction
- Always enumerate ALL instances of a class (all pages using a component, all list pages needing pagination) before marking a fix done — one-instance fixes are incomplete by default
- Always update the task list after each logical unit; never batch updates at session end, especially under parallelism when drift is most costly
- When a lookup or probe returns empty/unknown, emit UNCERTAIN or propagate absence — never synthesize a plausible default (zero, false, ALLOW) from silence

## Things to avoid
- Don't skip mandatory skill gate phases (adversarial validation, checklist passes) silently and mark tasks complete — if a gate is documented, run it or surface the skip explicitly
- Don't ship UI copy in formal agent-style language; UI banner text must read as human-written ("Set it up first" not "This job has not started — it needs its setup")
- Don't treat agent-generated documents, naming conventions, or default values as authoritative upstream sources — always trace provenance before citing something as canonical
- Don't add warm-up jobs, infra, or automation without explicit user request; scope creep is a confirmed recurring pattern here

## Open questions / known gaps
- IPC peer-alias resolution is fragile: aliases don't reliably map to live peer IDs without a live lookup — no stable mechanism yet
- UI verification discipline under velocity degrades: visual regression catches are deprioritized exactly when parallelism is highest, which is when they matter most
