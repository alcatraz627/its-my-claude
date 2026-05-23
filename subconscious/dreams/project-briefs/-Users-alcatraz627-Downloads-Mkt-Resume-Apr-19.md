<!-- i-dream project brief · 2026-05-13T12:18:00.114205+00:00 · 5 patterns / 10 insights -->
## What this project is about
Resume/document project in a Downloads directory — likely a one-off or occasional document editing context. Dominant working style is iterative refinement with tight feedback loops.

## Things to do (or keep doing)
- Take a screenshot after every visual change before reporting done — never claim a fix works without observing the output
- Match response length to input: terse user message = terse reply, no padding
- Use `/catchup` and checkpoints aggressively; this user runs multiple long-lived sessions and context loss is costly

## Things to avoid
- Don't claim visual or UI changes are complete without a fresh screenshot — the user will ask for one anyway
- Don't expand scope beyond what was asked; treat requests as a ceiling, not a floor
- Don't interpret terse continuation commands ("keep going", "more") after compaction without first reconstructing intent from WAL or checkpoint

## Open questions / known gaps
- No project-specific signal yet — this path appears to be a Downloads folder, not a persistent codebase; verify whether there's an actual project structure before assuming
