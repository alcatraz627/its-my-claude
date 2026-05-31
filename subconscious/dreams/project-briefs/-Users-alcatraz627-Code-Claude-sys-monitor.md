<!-- i-dream project brief · 2026-05-31T12:58:34.739682+00:00 · 20 patterns / 0 insights -->
## What this project is about
A system monitor / pipeline project in Python with a Node/TUI frontend layer, working style is terminal-first with gum/TUI formatted output and disciplined git hygiene.

## Things to do (or keep doing)
- **Always use gum TUI tools** for tabular output in chat — never raw markdown tables; this is a persistent compliance gap with strong user frustration
- **State commit scope directly** — if the answer is "all of `backend/`", say that; never give a partial file list that forces follow-up questions
- **Define constants inline** when first introduced in any doc or report — name + explanation, never just the name
- **Consolidate imports at file top** — inline/function-level imports are a repeated violation that draws strong pushback

## Things to avoid
- **Don't present markdown tables** in session output when gum tools are available — this is a 6th-recurrence violation, treat it as a hard rule
- **Don't assume git push permission is global** — user grants push access repo-by-repo; always confirm for each new repo
- **Don't name-drop config values without defining them** — `WORKER_MAX_DEFER_COUNT` without "what it does" is insufficient; always explain inline

## Open questions / known gaps
- Gum/TUI tool usage keeps recurring as a compliance failure — may need a project-level hook or CLAUDE.md reminder to enforce it mechanically rather than relying on agent memory
