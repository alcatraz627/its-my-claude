<!-- i-dream project brief · 2026-05-23T23:31:37.919052+00:00 · 20 patterns / 10 insights -->
## What this project is about
Frontend of a multi-session SaaS product (Versable enhancement-product); dominant working style is long autonomous implementation runs across many context compaction boundaries, with heavy reliance on `/core-dump` and `/catchup` for state continuity.

## Things to do (or keep doing)
- **Checkpoint proactively**: run `/core-dump` at milestones and near 70% context — don't wait to be asked; `/catchup` is the primary recovery path after compaction
- **Confirm task boundary at session start**: within it, execute autonomously and aggressively; outside it, do nothing without explicit approval
- **Treat all state as ephemeral**: re-read WAL/checkpoint state before any side-effecting operation rather than relying on earlier-in-session assumptions

## Things to avoid
- **Never commit or push without fresh, per-operation approval** — prior approval anywhere in the session, even seconds ago, does not carry forward; this is the single most frequently triggered violation in this project
- **Don't expand scope opportunistically** — "while I'm here" improvements, cleanup, or extra commits beyond what was explicitly requested have been corrected repeatedly
- **Don't summarize or narrate** between tool calls; user sends terse continuations ("keep going", "move") expecting immediate execution, not acknowledgment

## Open questions / known gaps
- Session continuity is entirely manual (core-dump → catchup cycle); recurring friction suggests the handoff artifact quality matters as much as frequency — unclear what level of detail is sufficient after compaction
- Pattern extraction for this project over-indexes on git-push violations (12 of top 20 patterns are the same event); real architectural patterns may be underrepresented in memory
