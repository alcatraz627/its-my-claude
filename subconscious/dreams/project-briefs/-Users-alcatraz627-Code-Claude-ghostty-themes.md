<!-- i-dream project brief · 2026-05-01T11:10:28.691217+00:00 · 15 patterns / 10 insights -->
## What this project is about
Ghostty terminal emulator theme management — likely a tool for browsing, applying, or generating Ghostty color schemes. Work style is terse-iterative with frequent session continuations across context boundaries.

## Things to do (or keep doing)
- Always checkpoint proactively before session end using `/core-dump`; this project sees frequent context boundary crossings
- On terse continuation commands ("keep going", "next", "more"), reconstruct intent from WAL/checkpoint state and resume autonomously — no clarifying questions
- Keep tool-call responses ≤15 words when session exceeds 40 tools; unnecessary prose accelerates compaction
- Commit to version control regularly as part of the workflow, not just at milestones

## Things to avoid
- Don't expand scope on terse continuation signals — "keep going" means continue exact current direction, not permission to add adjacent improvements
- Don't ask clarifying questions after single-word directives; consult WAL/checkpoint for last `current`/`next` fields instead
- Don't batch-verify changes; verify each change independently before moving to the next

## Open questions / known gaps
- Session pattern data is from a different project (geopolitical simulation); ghostty-themes-specific patterns are not yet established — treat these as defaults until corrected
- Unclear whether this project has an existing CLAUDE.md or runtime-notes with project-specific conventions
