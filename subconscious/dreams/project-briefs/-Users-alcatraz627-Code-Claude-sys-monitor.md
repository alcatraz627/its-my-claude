<!-- i-dream project brief · 2026-06-15T12:56:54.584872+00:00 · 20 patterns / 0 insights -->
## What this project is about
A system monitoring tool with a CLI/TUI interface; sessions involve backend service work, documentation, and git operations — with strong conventions around terminal output rendering and commit hygiene.

## Things to do (or keep doing)
- **Always use gum/TUI tools for tabular output** — raw markdown tables are a persistent violation; use configured gum tools every time, no exceptions
- **Give complete commit answers** — when the answer is "all of a directory", say that directly; never give a partial file list that forces a follow-up
- **Define constants inline** — any doc or report that names a config value must explain what it does right there, not just where it appears
- **Formal, direct prose in docs** — match tone to the audience; no promotional or flowery language

## Things to avoid
- **Don't use inline imports** — consolidate all imports at the top of the file; this causes strong user frustration and has recurred multiple times
- **Don't assume global git push permission** — push access is granted repo-by-repo; confirm for each new repo before auto-pushing
- **Don't let secondary work displace the primary deliverable** — finish what was stated at session start before expanding scope or adding enhancements
- **Don't omit YAML frontmatter from RCA files** — atone RCAs must start with `---` on line 1 or the lint gate rejects them silently

## Open questions / known gaps
- Gum tool compliance is a 6×-recurrence gap — something about how the project surfaces its TUI tooling makes the agent revert to markdown; worth checking if there's a `CLAUDE.md` or skill that should be making this automatic
