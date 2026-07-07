<!-- i-dream project brief · 2026-07-06T09:28:40.475242+00:00 · 20 patterns / 0 insights -->
## What this project is about
Local LLM tooling and agent infrastructure (`~/Code/local-models`). Work style is exploratory but delivery-focused — research and planning phases are expected to terminate in concrete, lean implementation docs, not raw synthesis.

## Things to do (or keep doing)
- Always surface actual command output after claiming a test passed — show the raw output so the user can judge correctness themselves
- Execute `/atone` and other explicitly invoked skills immediately and completely; deferring or skipping them mid-correction compounds the original mistake
- Use the Task tool when "update todos" is requested — file-based TODO lists leave the TUI blind
- Translate research/planning output into product- and behavior-focused implementation docs before calling a phase complete

## Things to avoid
- Don't re-introduce complexity the user explicitly deleted; when asked for a simpler replacement, deliver only that
- Don't declare tests or features successful without evidence — asserting success is treated as failure
- Don't use `rm`; always `trash` — the hook is hard-blocking and has no exceptions
- Don't let peripheral work (persona design, tooling setup, research) crowd out the stated core deliverable; deliver the primary artifact first

## Open questions / known gaps
- The repo has a CLAUDE.md git gate (stop-and-hand-exact-commands pattern) — read it before any git operation; default git behavior is not authorized here
- Doc style failures (em-dashes, AI-smell prose, motivational framing) recur despite explicit in-session rules; scan every human-facing doc for these before finishing
