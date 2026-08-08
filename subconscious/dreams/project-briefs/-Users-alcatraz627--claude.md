<!-- i-dream project brief · 2026-08-06T15:13:39.907538+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the user's global Claude configuration repo (`~/.claude`) — rules, skills, hooks, memory, and tooling that govern all Claude sessions. Work here is meta: writing behavioral rules, maintaining memory systems, building shell utilities, and orchestrating multi-agent workflows.

## Things to do (or keep doing)
- **Always grep the full app/codebase before touching any component** — cross-page consistency is the rule, not the exception; sibling instances exist.
- **Always preserve independently-produced outputs** (plans, reviews) as separate artifacts until the user explicitly requests a merge — two-agent peer-review means side-by-side contrast, never synthesis.
- **Treat terse continuations as standing permission** to proceed; context below 70% pressure means keep working, no clarifying questions.
- **Verify receiver state, not sender state** — for IPC, sub-agent output, or any inter-agent handoff, only end-to-end confirmation counts.

## Things to avoid
- **Don't claim UI/runtime fixes without exercising the running app** — diff-looks-right is not runtime-correct; open the dev server and visually confirm before using any completion word.
- **Don't skip mandatory gate phases** (design mocks, adversarial validation, verification checklists) — completion drive overriding gate discipline is the single most repeated failure here.
- **Don't use agent-authored docs as upstream authority** — trace any spec or assessment back to user-authored source or actual code before citing it as ground truth.
- **Don't present deferred items without their original context** — include the prior reasoning and concrete options or the user must ask a follow-up question to proceed.

## Open questions / known gaps
- Parallel work bursts (multi-agent, concurrent edits) consistently leave task lists, branch state, and ownership ambiguous — no single recovery protocol is reliably followed after parallel bursts complete.
- Mandatory gates exist in docs and skills but are bypassed in-flight by completion momentum; advisory text alone has proven insufficient to hold the gate.
