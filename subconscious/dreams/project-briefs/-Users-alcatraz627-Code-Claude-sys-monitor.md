<!-- i-dream project brief · 2026-06-18T00:43:52.270086+00:00 · 20 patterns / 0 insights -->
## What this project is about
A system monitor tool (likely a dashboard or CLI) in a Claude Code workspace, developed with a TUI-heavy workflow where gum tools are the designated display surface for structured output.

## Things to do (or keep doing)
- **Always use gum/TUI tools for tabular or structured output** — raw markdown tables are a persistent compliance failure here (6+ recurrences); never substitute them
- **Answer "what files to commit?" completely and directly** — if the answer is effectively an entire directory, say `all of backend/` rather than listing individual files
- **Define constants and config values inline** when first named in any report or doc — naming a value without explaining what it does forces a follow-up question
- **Consolidate imports at the top of every file** — inline imports inside functions are a strong frustration trigger in this project

## Things to avoid
- **Don't push to a new repo without an explicit per-repo grant** — git push permission is repo-scoped here, not session-global
- **Don't use promotional or "flowery" tone in technical docs** — formal, direct, simple prose only; match the tone to the content's seriousness
- **Don't let secondary work displace the primary deliverable** — deliver what was committed at session start before expanding scope or adding bonus features
- **Don't write S3 atone RCA files without `---` YAML frontmatter on line 1** — the `atone.sh` lint gate exits non-zero and leaves the event unrecorded

## Open questions / known gaps
- The gum-table compliance gap has recurred 6+ times without resolution — a hook or pre-render check may be needed to enforce it mechanically
