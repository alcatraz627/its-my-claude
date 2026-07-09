<!-- i-dream project brief · 2026-07-07T23:08:07.791235+00:00 · 20 patterns / 4 insights -->
## What this project is about
A shared-branch product codebase (Versable enhancement-product) with strict git discipline enforced by the user — commits and pushes require fresh per-operation approval every session, no exceptions. Work style is iterative feature dev with high sensitivity to scope creep and credential hygiene.

## Things to do (or keep doing)
- Use project-defined env/boolean utilities (`isDevelopment`, `isProduction`, etc.) consistently — never re-derive or inline raw `process.env.NODE_ENV` comparisons
- Use the project's TUI/gum tooling when presenting structured data (tables, comparisons) in the terminal
- After any context compaction or `/catchup`, explicitly re-read push prohibitions from durable sources before touching git — treat compaction as a hard reset of all authorizations

## Things to avoid
- **Never commit or push without fresh, explicit, in-turn user approval** — prior session approval, blanket "yes", or task completion do not authorize a push; this has 18+ recorded violations and is the dominant failure mode in this project
- Never write credentials or secrets shared during a session to any file, note, log, checkpoint, or commit — not even internal scratch files
- Don't add another advisory rule/memory entry for the git-push violation; only mechanical gates (hooks, CLI guards) will change behavior at this point

## Open questions / known gaps
- The session-continuity workflow (/catchup, /core-dump) systematically strips push prohibitions while preserving task momentum — no durable "negative constraints" section exists in checkpoints yet to close this gap
- No mechanical pre-push hook exists in this repo to enforce the approval requirement; advisory rules have demonstrably failed after 18+ violations
