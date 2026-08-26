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
updated: 2026-08-27
stale_after_days: 180
---

# UI is verified by reading the render, not by any check that passes without eyes

For UI or frontend changes, start the dev server and use the feature in a browser. Test golden path AND edge cases. Type checking and test suites verify code correctness, not feature correctness — if you can't test the UI, say so explicitly rather than claim success. For a *verified* UI claim, **read the screenshot back and judge it visually** — drive headless Chrome (puppeteer / Chrome-for-Testing) and inspect the rendered image, not just the assertion count. A green test run with a zero exit code is not the same as having seen the pixels.

**[design-mocks] Before implementing any user-facing UI feature** (labels, creation flows, module structure, form layouts), grep for design mocks or Figma specs for the surface. If they exist, consult them before writing a line of UI code. Shipped UI that ignores existing mocks is a known S3 recurrence.

**Multi-state surfaces: one state is not verification.** If the surface has theme/appearance states (dark AND light), open/closed variants, or responsive breakpoints, exercise the changed surface in EACH state before claiming verified — or scope the claim to what you actually saw ("verified in dark only"). Dark-only sign-offs that shipped a broken light theme are a recurring S3 (`declared-ready-without-runtime-exercise`, 2026-07-02 and 2026-07-07). Cheap second reader: run `lm see` on the screenshot alongside your own judgment.


## What 2026-08-26 added (three misses on one board in one evening)

- **Describe the frame before the question.** The two agents who verified the decisions
  view each rendered it and read the image, then answered one prepared question ("are the
  rows clickable?") and missed that the rows had no card background, no pointer, and a
  hover that made them flatter. A prepared question turns looking into a slower DOM
  assertion. Write what is on screen first, then ask.
- **Compare siblings.** A recorded row beside a page-backed row: one had a surface, one
  did not. When rows should match, say which differ and how.
- **The tree is not the render.** An accessibility snapshot proves structure. "Opened and
  read" means a rendered image was read; otherwise say "structure checked".
- **The set, not the row.** Six rows for one decision set were each correct and the
  surface was still wrong. Ask what the owner will meet, not whether each element works.

## Diagnostic signal

You are about to write "verified", "renders", or "looks right" about a surface and the
last thing you read was a snapshot, a curl, or a test line rather than pixels.
