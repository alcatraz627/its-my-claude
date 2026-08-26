<!-- i-dream project brief · 2026-08-21T23:38:56.788118+00:00 · 20 patterns / 2 insights -->
## What this project is about
A runner/orchestration service (likely part of the Versable product) with a strong emphasis on API contracts, deployment coordination, and technical planning docs. Work style is high-autonomy, low-interruption — the user's attention is scarce and interruptions are expensive.

## Things to do (or keep doing)
- **Show the actual data** when the user says "show me" — never substitute a summary or curated subset for the full result the agent already holds
- **Use decision wizard** (`/decision-wizard`) whenever more than one owner judgment is needed; never ask via numbered chat list
- **Reconcile the task list every few turns** — don't let it drift while edits accumulate; mark completed, add newly-discovered work
- **Technical planning docs need structure**: ASCII diagrams, tables, JSON payload shape examples — prose-only docs are rejected

## Things to avoid
- **Don't halt without a genuine blocker** — the threshold for pausing is high (only when the user must do something the agent truly cannot); re-raising a soft blocker after "keep going" is a recurrence failure
- **Don't count same-session regression fixes as forward progress** — UI changes that only undo the agent's own mistakes are net-zero recovery
- **No literary or narrative phrasing** in technical output, commit messages, or status reports — plain register only
- **Don't conflate "project status" with "planning/contracts doc"** — when the user asks for a plan or contract, deliver architecture + API shape, not deployment state

## Open questions / known gaps
- Behavioral corrections (prose register, task reconciliation) degrade within the same session; re-check adherence to mid-session corrections every 3–5 turns rather than assuming they persist
- Deferral patterns lose context by resumption time — persist decision options and blocking question at the moment of deferral, not at resumption
