<!-- i-dream project brief · 2026-06-19T01:41:41.599805+00:00 · 9 patterns / 0 insights -->
## What this project is about
A product enhancement layer (likely a browser extension or frontend add-on) built around Anthropic model integrations. Work is iterative UI/UX development with tight documentation and code-quality standards.

## Things to do (or keep doing)
- **Plan before implementing** any non-trivial hand-rolled UI component; review existing similar implementations in the codebase first, then write code — never one-shot complex custom UI
- **Write technical docs in a formal, direct voice** — neutral, confident, no hedging, no marketing framing; treat every doc as if it will be read by a skeptical senior engineer
- **Verify toolchain/environment state before referencing it** — if the user has done a migration (version manager, Node, Python), re-probe the actual state rather than assuming prior knowledge is current

## Things to avoid
- **Don't cache externally-mutable status with a TTL** — availability/warm-cold state toggled by an out-of-band tool will produce stale UI; read live or invalidate on the actual event
- **Don't place scratch or checkpoint files in the project root** — loaded artifacts (extensions, npm packages) will fail if they pick up unexpected files at package root
- **Don't let investigation uncertainty or agent-analysis caveats appear in user-facing docs** — internal doubt belongs in the WAL, not the output

## Open questions / known gaps
- Recurring tension between one-shotting a component to save time and the user's explicit preference for plan-first; the pull toward speed keeps triggering corrections
