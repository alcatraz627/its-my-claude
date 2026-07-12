<!-- i-dream project brief · 2026-07-12T04:21:42.359441+00:00 · 3 patterns / 0 insights -->
## What this project is about
Frontend development work with emphasis on UI interaction design and documentation scaffolding. Working style is pattern-conscious and preference-driven.

## Things to do (or keep doing)
- Always separate preview from commit in picker/selection UIs — selecting an option previews it; only an explicit save/apply button persists the choice
- Use fenced `diff` blocks for any colored output in GitHub PR comments — ANSI escape codes do not render there
- When scaffolding stub docs, write only the goal statement and `TODO(human)` placeholders per section — structure without fabricated content

## Things to avoid
- Don't auto-apply a selection on click; treat selection as ephemeral preview until the user explicitly confirms
- Don't write invented body content to fill documentation structure — incomplete stubs with honest placeholders are preferred over plausible-but-wrong prose
- Don't use ANSI codes in PR comment text expecting color — they render as literal escape sequences

## Open questions / known gaps
- Only 3 patterns recorded; confidence in domain conventions (component library, state management, test patterns) is low — grep the codebase before asserting conventions
