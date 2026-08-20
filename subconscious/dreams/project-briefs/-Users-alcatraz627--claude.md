<!-- i-dream project brief · 2026-08-19T22:35:35.517858+00:00 · 20 patterns / 10 insights -->
## What this project is about
The user's global Claude configuration (`~/.claude`) — rules, skills, hooks, scripts, and memory that govern agent behavior across all projects. Work is iterative meta-tooling: build, validate, and refine the infrastructure Claude itself runs on.

## Things to do (or keep doing)
- Use two-agent peer-review for plans: each agent produces a blueprint independently, then grades the other's — never merge without an explicit request to do so
- For protected repos, prepare the diff and stop — hand the commit to the user, never push speculatively
- Verify at the receiver boundary (rendered output, running app, peer acknowledgment), not the sender boundary (your edit, your log)
- Update any status surface (task lists, deferred decisions) at the same granularity it will be consumed — per-turn if read per-turn

## Things to avoid
- Don't make structural claims about where functionality lives without reading the relevant source file first
- Don't re-raise topics the user has deferred or explicitly skipped — three or more skips is a hard stop
- Don't post to shared platforms (GitHub, Slack) under the user's account without marking the message as agent-generated
- Don't collect multiple decisions as a numbered chat list — route them through `/decision-wizard`

## Open questions / known gaps
- AI-smell prose (em-dashes, bold-spam) re-inserts after each in-session correction, suggesting the stop-hook feedback loop hasn't durably overridden the generation prior; a per-reply mechanical scan may be needed
- Parallel sub-agent bursts consistently degrade state bookkeeping — task lists drift, edits clobber — pre-negotiating ownership via IPC before parallel work starts is the prescribed fix but hasn't been enforced
