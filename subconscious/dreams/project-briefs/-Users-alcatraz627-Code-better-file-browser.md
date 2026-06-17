<!-- i-dream project brief · 2026-06-15T12:56:32.980147+00:00 · 11 patterns / 0 insights -->
## What this project is about
A file browser tool project (`better-file-browser`) with active session tooling integration (atone, WAL, RCA rituals). Dominant working style: correction-heavy sessions with formal documentation outputs and strict deliverable sequencing.

## Things to do (or keep doing)
- Always execute `/atone` immediately and in full when invoked — no deferral, no partial runs; user notices every skip
- Begin every RCA file with `---` YAML frontmatter on line 1 or the atone gate rejects it silently
- Render-check all markdown tables before presenting to user — agent-generated tables frequently misformat
- Write any mid-session guideline updates back to the project's canonical file, not just into conversation

## Things to avoid
- Don't use promotional, flowery, or "why this matters" framing in technical or product documentation — plain, formal, direct only
- Don't expand scope or pursue secondary features before the primary session deliverable is done
- Don't leave an atone RCA in a failed state (exit code 2) without immediately diagnosing and re-running with corrected frontmatter

## Open questions / known gaps
- RCA frontmatter failures have recurred multiple times — consider adding a pre-write lint step or template to prevent the pattern from firing again
- Documentation tone corrections appear 4× across variants; may indicate the default model voice doesn't match this user's house style — load tone guidance early in docs sessions
