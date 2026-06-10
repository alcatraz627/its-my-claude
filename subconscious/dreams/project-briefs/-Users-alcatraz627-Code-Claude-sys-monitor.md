<!-- i-dream project brief · 2026-05-31T19:29:34.935797+00:00 · 20 patterns / 0 insights -->
## What this project is about
A system monitoring tool (likely CLI/TUI-based) built with Python and Node, emphasizing structured output via gum/TUI tools and disciplined git practices.

## Things to do (or keep doing)
- Always use gum/TUI tools for tabular or structured output in chat — never raw markdown tables; this is a persistent compliance requirement with strong user frustration history
- When asked what files to commit, answer completely and directly — if the answer is "all of `backend/`", say that plainly instead of listing individual files
- Always define new constants, flags, or config values inline at first mention in any doc or report — naming without explaining forces re-reads

## Things to avoid
- Don't write inline imports (inside functions); always consolidate at the top of the file — this is a repeated frustration trigger
- Don't assume git push permission from one repo generalizes to others — each repo requires explicit per-repo user grant before auto-pushing
- Don't reference a named constant or config key in a doc without an inline definition of what it does

## Open questions / known gaps
- Persistent pattern of agent defaulting to raw markdown tables despite 6+ correction cycles — may need a hook or settings-level enforcement rather than relying on model compliance
