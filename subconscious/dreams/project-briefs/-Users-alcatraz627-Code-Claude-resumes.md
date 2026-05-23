<!-- i-dream project brief · 2026-05-13T12:35:10.508630+00:00 · 19 patterns / 2 insights -->
## What this project is about
A resume-building/generation tool built with iterative UI refinement as the dominant workflow. Work proceeds in multi-session increments with heavy reliance on visual verification and session continuity.

## Things to do (or keep doing)
- Always verify UI changes with a screenshot before reporting success — truncation and layout bugs are invisible without rendering
- Checkpoint frequently; use `/core-dump` at logical phase boundaries and before any `/clear`
- Commit and push at each logical phase boundary, explicitly naming what was shipped
- State accurate contrary facts when the user is wrong — don't agree to be agreeable

## Things to avoid
- Never commit or push without explicit in-turn user approval — prior session approval is not blanket
- Don't patch UI symptoms without diagnosing root cause first; editing the same element 3+ times means you haven't found it yet
- Don't branch on `err.message` strings for control flow — use a stable `code` field on the error object
- Don't add a test library before checking whether the codebase already has an established testing pattern

## Open questions / known gaps
- Inter-agent handoff discipline (when two codebases collaborate via agent): strict codebase boundary enforcement and structured feedback format are required but historically violated
- Widget/dropdown truncation constraints must be set upfront — retrofitting them causes repeated fix cycles across sessions
