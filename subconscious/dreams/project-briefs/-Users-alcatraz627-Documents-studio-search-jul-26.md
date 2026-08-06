<!-- i-dream project brief · 2026-08-06T03:49:56.998560+00:00 · 11 patterns / 0 insights -->
## What this project is about
A studio search tool (likely Next.js/React) built through a deliberate multi-agent peer-review workflow where independent agents produce and grade each other's plans before implementation begins.

## Things to do (or keep doing)
- **Preserve peer-review fidelity**: when two agents independently produce plans and grade each other, execute both steps faithfully — never collapse into a single merged recommendation
- **Prefer "good enough" baseline over over-engineering**: when the user signals "good enough state," stop at functional and ship it; skip exhaustive edge-case coverage
- **Triage selectively when integrating dead agent's work**: don't wholesale adopt; extract only the parts worth keeping, frame the decision explicitly
- **Design optional local services (Redis, Ollama) as on-demand**: explicit start + auto-off after idle threshold, never always-on background daemons

## Things to avoid
- **Don't merge when asked to compare**: side-by-side contrast is mandatory; merging two plans is a separate operation requiring explicit instruction
- **Don't add scheduled warm-up/pre-load jobs unprompted**: ollama warm-morning or similar infra is scope creep unless explicitly requested
- **Don't use IIFEs or scope-wrapper expressions in JSX**: conform to sibling element patterns (inline props, plain `const` declarations)
- **Don't skip the round-tracking entry**: after completing a multi-round work segment, write the board/tracking entry before moving on — this step is chronically skipped

## Open questions / known gaps
- Multi-round project tracking discipline is a recurring gap: entries get deferred to session end and then missed entirely
