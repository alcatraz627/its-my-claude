<!-- i-dream project brief · 2026-08-11T00:22:57.255952+00:00 · 20 patterns / 3 insights -->
## What this project is about
A Claude Code scripts and kanban tooling project operating in autonomous/multi-agent mode, with scraping pipelines, deploy flows, and a heavy UI component. Work style is agentic and long-running with frequent stop-hook interventions.

## Things to do (or keep doing)
- **Always consult design mocks before writing any UI module** — label names, page structure, and creation flows must trace to the mock, not your mental model
- **Surface blocking events (auth prompts, rate limits) within 30 seconds**, naming the exact command needed; never stall silently
- **Update task status after each logical unit** in autonomous sessions — task list drift is a known failure mode here
- **Validate sub-agent output against standing style rules before shipping** — producing agents violate constraints the dispatching agent already documented

## Things to avoid
- **Don't emit em-dashes or excessive bold spans** — the stop-hook fires on this repeatedly; rewrite before the turn ends, not after the hook catches it
- **Don't treat agent-authored artifacts as upstream authority** — always trace claims to the user spec, design mock, or source code, never to a formalization you derived
- **Don't dispatch a sub-agent to an MCP resource without verifying no other session holds it** — resource conflicts cause silent failures
- **Don't ship UI as done when it reads visually sparse** — verify density and completeness alongside correctness

## Open questions / known gaps
- **Interactive OAuth in deploy pipelines** — the user wants fully async flows, but pre-established credentials aren't always in place; this tension recurs without a durable resolution
- **Model limit handling mid-session** — the agent should switch models on hitting a limit, but the fallback path isn't hardened; autonomous sessions still stall
