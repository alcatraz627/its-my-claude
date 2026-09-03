<!-- i-dream project brief · 2026-08-31T05:39:42.880320+00:00 · 20 patterns / 3 insights -->
## What this project is about
A kanban/dashboard tooling layer inside `~/.claude/scripts/kanban` — shell scripts, HTML artifacts, and scraping/data pipelines that Claude Code sessions consume directly. Work style is iterative UI fixes, multi-agent coordination, and data verification loops.

## Things to do (or keep doing)
- **Consult design mocks before writing any UI element** — labels, page names, creation flows must match mocks; skipping causes full reworks.
- **Exercise every decision surface before directing the owner to it** — curl or screenshot to confirm it works, not just that the code compiles.
- **Surface exact blockers with the recovery command** whenever an external boundary (auth, limit, guard) stalls progress; never stall silently.
- **Scan sibling pages for existing patterns** before implementing any UI element — adopt the established pattern or cite why not.

## Things to avoid
- **Don't declare a fix resolved without mechanical verification** — same failure recurring across sessions means the prior "resolved" claim was unverified.
- **Don't treat an a11y snapshot or DOM structure as a render** — "opened and read" requires a screenshot read at the element the complaint named, not a nearby panel.
- **Don't halt mid-task on soft blockers** — if the user has said "keep going" or invoked `/atone` for stubbornness, re-raising the same non-blocker is the failure.
- **Don't post GitHub comments without the owner's agent attribution marker** (blockquote format, random phrase from fixed list) — no exceptions.

## Open questions / known gaps
- **Prose smell recurs even after the stop-hook fires** — em-dashes and bold-spam survive multiple correction cycles; treat any hook warning as a hard block, not a nudge.
- **CI vs local test divergence is unresolved** — local green ≠ CI green; always check CI job results before claiming a PR is clean.
