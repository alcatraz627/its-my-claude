---
brief: A UI claim is verified only by a rendered image read as a person would: describe the whole frame before answering any prepared question, compare each row with its sibling, exercise both themes, and cite the screenshot. An accessibility tree, a DOM assertion, a 200, or a click handler firing is not the render. S3 at 10x; three instances on one board in one evening.
triggers:
  - topic:ui
  - topic:frontend
  - topic:screenshot
  - tool:browser_take_screenshot
  - tool:take_screenshot
  - phrase:"looks right"
related:
  - rules/exercise-based-verification.md
  - rules/testing.md
  - skills/ui-categorical-check/SKILL.md
  - personas/ui-reviewer.md
tier: 1
category: rules
updated: 2026-09-18
stale_after_days: 180
---
# UI is verified by reading the render, not by a check that passes without eyes

For a UI change: start the dev server, use the feature in a browser, golden path and edge cases. Type checks and suites verify code, not the feature. A verified claim means you drove headless Chrome, read the screenshot back, and judged it; cite the screenshot path.

- **[design-mocks]** Before implementing any user-facing UI, grep for mocks or Figma specs for the surface and consult them.
- **Every state:** dark AND light, open and closed, each breakpoint, or scope the claim ("verified in dark only"). `lm see` is a cheap second reader.
- **Describe the frame before the question.** Write what is on screen first, then answer your prepared question; a prepared question turns looking into a slow DOM assertion.
- **Compare siblings**; say which rows differ and how.
- **The tree is not the render.** An accessibility snapshot proves structure; say "structure checked".
- **The set, not the row.** Ask what the owner will meet, not whether each element works.

Diagnostic: about to write "verified" or "looks right" and the last thing you read was a snapshot, a curl or a test line.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/ui-visual-verification.md`
