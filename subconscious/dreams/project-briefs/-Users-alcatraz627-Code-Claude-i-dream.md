<!-- i-dream project brief · 2026-10-06T10:17:03.265101+00:00 · 20 patterns / 3 insights -->
## What this project is about
`i-dream` is a Rust-based background memory consolidation and pattern extraction layer for Claude Code — dreaming, metacognition, intuition running silently while you work. Work style is iterative, multi-session, heavy checkpoint/resume use with a dashboard UI component.

## Things to do (or keep doing)
- **Read source before making structural claims** — every "this does not exist / this is broken" assertion needs a file:line citation from the actual code, not inference.
- **Exercise the announced thing before ending the turn** — navigate the URL, run the binary, write the file; a status claim is not verification.
- **Use the two-agent peer-review workflow when the user asks for it** — each agent produces a plan independently, then grades the other's blueprint; don't collapse it into one pass.
- **Follow full paths everywhere** — basenames alone are not clickable; use relative or absolute paths in all output and reports.

## Things to avoid
- **Don't substitute a proxy verification for the real one** — a type check is not a runtime check, a DOM snapshot is not a visual render, a collect-only run is not a passing suite.
- **Don't treat declaration as completion** — printing a `/goal` line, listing next steps, or saying "ready to merge" without having exercised the thing is the dominant failure pattern here.
- **Don't publish Claude Artifacts for repo deliverables** — write the file into the repo as markdown or HTML; the user does not want hosted pages unless explicitly asked.

## Open questions / known gaps
- **Declaration-vs-completion loop recurs across sessions** — the promoted insights flag it three separate times; this project's verification bar is higher than the global default.
