<!-- i-dream project brief · 2026-08-10T05:20:22.869482+00:00 · 4 patterns / 1 insights -->
## What this project is about
Playwright-MCP integration layer for the Versable builder project; work centers on autonomous browser-driven testing and deploy flows with multi-agent coordination.

## Things to do (or keep doing)
- Run an explicit pre-deploy constraint check against any sub-agent's output before accepting its self-report of correctness — catches style and invariant violations the sub-agent silently skips
- Design multi-agent steps with an explicit "I am blocked" signal and timeout-based fallback so authentication, quota, and liveness failures surface immediately rather than stalling silently
- Pre-establish credentials (tokens, session cookies) before any autonomous sequence that touches an OAuth flow — interactive browser auth cannot be made async after the fact

## Things to avoid
- Don't author a constraint rule in docs and then immediately violate it in the same session's output — apply a self-check pass against any newly stated invariant before finalizing the turn
- Don't treat a sub-agent's self-reported correctness as ground truth — always verify with an independent constraint scan or exercise pass
- Don't assume a stalled autonomous session has hit a logic error; check for silent quota or subscription exhaustion first

## Open questions / known gaps
- No graceful quota-exhaustion notification path exists yet; mid-session stalls leave work state ambiguous and require manual recovery
- Interactive OAuth in deploy flows is structurally incompatible with fully autonomous runs — no resolved pattern for pre-seeding credentials in this project
