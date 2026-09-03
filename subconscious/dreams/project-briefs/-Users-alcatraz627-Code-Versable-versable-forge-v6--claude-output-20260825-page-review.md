<!-- i-dream project brief · 2026-08-28T01:27:44.903784+00:00 · 10 patterns / 0 insights -->
## What this project is about
A UI review and iteration project on versable-forge-v6 page outputs, focused on evaluating rendered surfaces, catching layout regressions, and verifying changes against legibility and parity goals. Dominant style: browser-verified, screenshot-read, table/layout-heavy front-end work.

## Things to do (or keep doing)
- Always open the page in a browser at desktop width before claiming any table or wide-content layout change is done; screenshot + describe the full frame before answering any specific question
- Run `rg --no-ignore` (or `fd --no-ignore`) before asserting a file or module does not exist; default searches miss hidden/gitignored paths
- Verify sub-agent output files exist on disk before treating the idle/completion signal as done; the notification alone is not the artifact

## Things to avoid
- Don't claim done/works/fixed after editing source without executing the changed code path — the declared-ready gate will fire, and rightfully so
- Don't implement a UI element (footer text, chip row, layout detail) exactly as written in a plan without checking whether it serves the plan's legibility goal; literal wording is a sample, not a spec
- Don't cite file paths with an immediately trailing period in user-facing output; period is swallowed into the terminal auto-link

## Open questions / known gaps
- The declared-ready gate fires on docs-only edits (false positive); surfacing this clearly rather than silently absorbing it is the correct response but not yet habitual
- Task-store session identity checks during wake cycles are unreliable — always verify the store header matches the expected session ID before acting on its contents
