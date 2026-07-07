<!-- i-dream project brief · 2026-07-06T09:28:23.507596+00:00 · 1 patterns / 0 insights -->
## What this project is about
A CLI exploration tool built around or inspired by fastfetch (system info), likely a wrapper, explorer, or data-pipeline over its output. Work style appears to be iterative CLI tooling with scripted commands.

## Things to do (or keep doing)
- Verify a command or tool exists on disk before referencing it in output or docs — `which <cmd>` or `test -f <path>` first
- Keep scope tight per session; fastfetch tooling tends toward small composable scripts

## Things to avoid
- Don't reference planned commands (e.g. `probe`, `explore`) as if already implemented — if it was only planned, say "we plan to add X", not "run X"
- Don't assume a script installed in a prior session is still on PATH; re-check before invoking

## Open questions / known gaps
- _(no signal yet)_ on testing strategy or how the tool is expected to be distributed/run
