<!-- i-dream project brief · 2026-07-12T04:39:28.616347+00:00 · 3 patterns / 0 insights -->
## What this project is about
Backend service with adjacent tooling for GitHub PR workflows and documentation scaffolding. Working style is precision-first: explicit user actions over convenience automation, real rendering over inferred output.

## Things to do (or keep doing)
- In any picker or selection UI, selecting an option **previews only** — always require a distinct save/apply action to commit the change
- In GitHub PR comments, use fenced ` ```diff ``` ` blocks to produce colored output — ANSI escape codes do not render there
- When generating stub docs, write only the goal statement and `TODO(human)` placeholders per section; never fabricate body content for structural completeness

## Things to avoid
- Don't auto-apply or commit a selection on click/enter — treat selection and confirmation as two separate events
- Don't write populated placeholder content in stub documentation to make it "look complete" — fabricated content is harder to audit than an honest TODO
- Don't use ANSI color codes in PR comment bodies expecting them to render

## Open questions / known gaps
- Only one occurrence per pattern — confidence is early; these may not yet reflect deep project-wide conventions vs. one-off corrections
_(no further signal)_
