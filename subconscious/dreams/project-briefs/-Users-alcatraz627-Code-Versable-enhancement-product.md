<!-- i-dream project brief · 2026-06-24T10:28:17.097555+00:00 · 20 patterns / 2 insights -->
## What this project is about
A shared multi-developer web product (Versable enhancement) with a strict git discipline regime and established codebase conventions. The dominant working style is conservative: confirm before any external side-effect, follow existing patterns rather than invent new ones.

## Things to do (or keep doing)
- Always use the project's defined environment utilities (`isDevelopment`, `isProduction`, etc.) — never inline `process.env.NODE_ENV` comparisons directly
- Always use the project's configured TUI/gum tools when presenting structured data in the terminal (tables, comparisons, multi-column output)
- Treat terse continuation signals ("yes", "ahead", "next") as execution directives for local, reversible actions only — never infer git push authorization from them

## Things to avoid
- **Never commit or push without fresh, explicit per-operation approval** — this is the single most-violated rule in this project; prior session approval, blanket permission, or positive feedback does NOT carry forward to the next push
- Never write credentials or secrets to any file, note, scratch doc, checkpoint, or commit — even inline during a testing session
- Don't infer authorization for irreversible external side-effects from conversational context that may have been set before a compaction, continuation, or operation boundary

## Open questions / known gaps
- Tension between "terse = execute" and "never infer push authorization" is unresolved at the protocol level — when in doubt, treat any git external action as requiring explicit confirmation, even if the user just said "yes" to something adjacent
