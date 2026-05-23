<!-- i-dream project brief · 2026-05-16T20:59:41.029938+00:00 · 12 patterns / 0 insights -->
## What this project is about
Versable landing app — a Next.js web product with strict conventions around auth, env vars, and component architecture. Work style is iterative and convention-compliance-heavy; the user catches abstraction violations quickly.

## Things to do (or keep doing)
- **Use existing abstractions** — always prefer named helpers (`isDevelopment`, `isProduction`) over inlining raw expressions; grep before writing new code
- **Augment before replacing** — when improving existing design, minimize structural change; propose additions not rewrites
- **Write permanent scripts from the start** — if proposing a validation/link-check/lint tool, commit it as a real artifact, not a one-off
- **Scope checkpoints per agent** — when running parallel agents, explicitly scope context files to avoid cross-loading wrong session state

## Things to avoid
- **Don't declare complete without convention-check** — verify all changes conform to project patterns, not just functional correctness
- **Don't infer architecture** — never assert which service owns auth/token/validation without reading the actual code; cite file:line
- **Don't expose client env vars silently** — flag any `NEXT_PUBLIC_` additions and question necessity before adding
- **Don't introduce infra categories without confirmation** — CI pipelines, test harnesses, deployment hooks need explicit approval if no precedent exists

## Open questions / known gaps
- Test setup is ambiguous — always check `package.json` and existing test files before suggesting a framework; one likely already exists
- Component deletion triggers recurring corrections — the "why does this split exist?" question is frequently missed before refactors
