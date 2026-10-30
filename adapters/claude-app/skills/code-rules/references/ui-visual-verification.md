# UI is verified by reading the render

A UI change is verified only when someone has looked at a rendered image the
way a person would. Type checks and test suites verify code, not the feature.
An accessibility tree, a DOM assertion, a 200 response or a click handler
firing is not the render.

For a UI change, run it and use the feature: golden path and edge cases. If
you cannot, say so rather than claim success. A verified claim cites the
screenshot it rests on.

## Before building

Look for design mocks or specs for the surface (Figma, a design doc, an
attached image) and read them before writing UI code. Shipped UI that ignores
existing mocks is a common, avoidable miss.

## How to read a render

- **Describe the frame before answering your question.** Write what is on
  screen first, then check the thing you set out to check. A prepared
  question turns looking into a slow DOM assertion.
- **Compare siblings.** When rows or cards should match, say which differ and
  how.
- **Every state.** Dark and light, open and closed, each breakpoint. Or scope
  the claim: "verified in dark mode only".
- **The tree is not the render.** An accessibility snapshot proves structure.
  If that is all you read, say "structure checked", not "verified".
- **The set, not the row.** Each element can be correct and the surface still
  wrong. Ask what the user will meet on the page.

## Example

Two reviewers each rendered a list view and read the screenshot. Each answered
the one question they came with, "are the rows clickable?", and said yes. Both
missed that the rows had no card background, no pointer cursor, and a hover
state that made them look flatter. The answer to the prepared question was
right, and the page was still wrong.

## In chat

You have vision. Ask the user for a screenshot of each state that changed, or
render the component in an artifact and read it back. If neither is possible,
mark the claim `UNCONFIRMED` and list the states nobody has seen.

## Diagnostic

You are about to write "verified", "renders" or "looks right", and the last
thing you read was a snapshot, a fetch or a test line rather than pixels.
