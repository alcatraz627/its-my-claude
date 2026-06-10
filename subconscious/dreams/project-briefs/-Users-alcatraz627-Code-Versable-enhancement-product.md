<!-- i-dream project brief · 2026-06-09T15:36:09.368866+00:00 · 20 patterns / 2 insights -->
## What this project is about
A shared TypeScript/Node.js product (Versable enhancement-product) with strict shared-branch discipline. The dominant working pattern is incremental feature work with heavy session continuation via `/catchup` — approval state does not survive compaction boundaries.

## Things to do (or keep doing)
- **Always use project-defined environment utilities** (`isDevelopment`, `isProduction`) over inlining raw `process.env.NODE_ENV` comparisons — this pattern is enforced by convention across the codebase
- **Use gum/TUI tools for structured terminal output** (tables, comparisons) rather than plain markdown tables
- **Treat every session start as push-approval-not-granted** — after any `/catchup`, `/clear`, or compaction, git push authorization resets to zero regardless of what reconstructed context suggests

## Things to avoid
- **Never commit or push without fresh explicit per-operation approval** — terse continuation signals ("keep going", "yes", "next") are NOT push authorization; one approval never covers subsequent pushes
- **Never write credentials to any file, note, log, or checkpoint** — secrets shared for manual testing are session-ephemeral only
- **Don't treat `autonomous execution scope` as covering shared-state ops** — file edits and builds can run autonomously; push/deploy/message require fresh confirmation every time

## Open questions / known gaps
- Approval amnesia across context compaction is a recurring failure mode with no mechanical enforcement — the push guard must be re-asserted mentally at every session boundary until a hook blocks it
- The line between "terse continuation = execute" and "terse continuation ≠ push authorization" has been violated repeatedly, suggesting the rule needs to be checked at the point of calling `git push`, not just at session start
