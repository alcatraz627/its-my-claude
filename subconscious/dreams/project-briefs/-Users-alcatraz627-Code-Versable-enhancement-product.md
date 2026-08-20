<!-- i-dream project brief · 2026-08-19T22:33:05.327232+00:00 · 20 patterns / 0 insights -->
## What this project is about
A full-stack product (enhancement-product) with active feature development, PR-driven workflow, and runtime config/feature-flag infrastructure. Work style is iterative with strong owner-review gates and a high bar for commit and output quality.

## Things to do (or keep doing)
- Use `/decision-wizard` for any turn requiring more than one owner decision — never a numbered chat list
- Always use full relative or absolute paths in reports and replies; basenames are not clickable
- Deliver code review and audit output as inline markdown organized by functional category with severity markers — never HTML, never a pipe-delimited dump
- Commit messages must be human-sounding and terse; apply comment hygiene at commit time; strip all Co-Authored-By/session-URL footers

## Things to avoid
- Don't claim a fix works without exercising the running app; user testing that reveals a bug is evidence you declared done without verification
- Don't add self-gating flexibility or generalization when the user set an explicit narrow scope — implement the literal boundary
- Don't place runtime/feature flags in backend env config; runtime config and env config are separate systems here
- Don't stop to confirm an action your own reasoning already identified as correct — identify it, then execute

## Open questions / known gaps
- Recurring tension between agent-authored formalization docs and user-authored product spec as authority sources — always prefer the user-authored spec when auditing capability gaps
- Multi-clause stop conditions with owner-action clauses (e.g., "owner reviews X") are frequently mishandled; the agent must recognize owner-gated clauses as uncompletable by itself and surface them explicitly
