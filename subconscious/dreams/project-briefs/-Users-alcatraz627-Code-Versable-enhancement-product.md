<!-- i-dream project brief · 2026-07-02T23:54:47.007863+00:00 · 20 patterns / 2 insights -->
## What this project is about
A shared TypeScript/Next.js product codebase ("enhancement-product") worked collaboratively with the user; the dominant working style is incremental feature work with strict git discipline and strong convention adherence.

## Things to do (or keep doing)
- **Use project utility constants** (`isDevelopment`, `isProduction`, etc.) instead of inlining raw `process.env.NODE_ENV` comparisons — the codebase defines these; always grep before deriving inline.
- **Use the project's TUI/gum tools** for terminal table/comparison output; plain markdown tables are wrong here.
- **Hard-stop before any git commit or push** and surface the exact command + effect to the user — wait for in-turn approval before running it.

## Things to avoid
- **Never commit or push without fresh, explicit, per-operation approval** — prior session approval, terse continuations ("next", "ahead", "keep going"), or general task approval do NOT authorize git mutations. This is the single highest-recurrence violation in this project (18+ incidents).
- **Never write credentials to any file**, note, checkpoint, or commit artifact — even scratch claude notes. Credentials shared inline during a session are for immediate manual use only.
- **Don't re-derive constants the codebase already defines** — grep for existing environment/boolean utilities before writing a new `process.env.*` check.

## Open questions / known gaps
- Terse continuation signals structurally amplify the git-push violation — the execution-autonomy grant bleeds past the shared-state-mutation boundary every session; advisory corrections alone have not fixed this across compaction boundaries.
