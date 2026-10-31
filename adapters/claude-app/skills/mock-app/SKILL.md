---
name: mock-app
description: Builds a clickable HTML mock of an app as an artifact before production work, or renders 3 to 6 variants of one visual choice side by side. Use when a screen or a taste call needs the user's eye.
---

# Mock app

Give the user something to look at instead of something to read. Prose is a
poor surface for taste: nobody can judge "11px uppercase tracked" from a
sentence, but six rendered cards decide it at once.

Two modes:

- **Mock**: a clickable HTML model of a whole app or flow, every screen drawn
  by one shared kit, so the user can walk it before any production code exists.
- **Variants**: three to six candidate looks for one visual call, rendered
  side by side, so the user picks or composes by looking.

A whole app or a flow with several screens is a mock. One element, one screen
or one style question is a variants run. A taste question that comes up
inside a mock round becomes a variants run, and its ruling goes back into the
mock.

Not for a page that already exists and works. Critique that one instead.

## Step 1: Find the direction before drawing

Skip this when the user has already said what it should look like.

1. **Read the rejection record first.** Collect what the user has already
   turned down: in this conversation, in notes or screenshots they shared, in
   the project's design docs. Quote it. Proposing something already rejected
   makes the user repeat feedback they have given.
2. **Read the canon.** The project's tokens, sibling screens and shipped
   values. A dark, dense, terminal-style look is the user's default for
   developer tools unless the canon says otherwise.
3. **Look outward, bounded.** At most three web searches for reference
   products, each with a URL and a one-line takeaway. Outside references never
   outrank the canon or the rejection record.
4. **"No direction" is a real answer.** When the canon already settles a
   question, say what settled it and do not re-solve it.
5. **No invented numbers.** A size, ratio or color claim either comes from a
   measurement you ran or is marked as a prediction to check at build time.

## Building the mock

Build it as one HTML artifact. Reproduce this contract:

1. **A place map.** One data structure lists every place in the app. Every
   breadcrumb, Back target and nav highlight is derived from it, never typed on
   a screen.
2. **One kit.** Screens call kit functions (button, row, card, sheet) and
   carry no tags, classes or inline styles of their own. A change to the kit
   changes every screen at once, which is the point.
3. **A review shell around the device frame.** A rail listing every place,
   toggles for states (empty, loading, error, long text), the sheets each
   screen opens, a wall showing every screen at once, and a design-system view
   drawn by the kit itself.
4. **Checks that run in the page.** A `runChecks()` pass over every frame in
   both themes and at three text sizes: tap targets under 44 px, text that
   overflows its box, taps that lead nowhere, more than one filled button per
   screen. Show the results in the shell.
5. **Prove each check by mutation.** Plant the defect, watch the check go
   red, restore it, watch it go green. A check you never saw fail proves
   nothing.
6. **A tap crawl.** A breadth-first walk over every tappable element from
   each state finds the dead ends the checks miss.
7. **Look at it.** Ask the user for screenshots of the wall in dark and light,
   or rasterize the HTML in the sandbox if a headless browser is installable,
   and view the images. Describe what is on screen before judging it. A
   passing check is not a look.

Keep a short decisions list in the artifact (a panel or comment block), so
the next round extends the same system instead of starting over.

## Rendering variants

1. **Name the channels.** Write down what the call can vary: size, weight,
   case, color, position, marker, density. Each variant changes a stated set of
   channels and its card says which. Two elements read as the same kind of
   thing when they differ on one channel, and as different kinds at three or
   more. Choose variants to land on the side the user intends.
2. **Draw a reference card first.** It reproduces the current look with
   measured values: computed styles the user pastes from devtools, or values
   read from their source. Never remembered ones. Every variant is judged
   against what exists.
3. **Render three to six variants** in one artifact as a gallery, each card
   labelled with a number and its changed channels, with a dark and light
   toggle for the whole page.
4. **Mark one recommendation** and say why in one sentence. Include a "none of
   these" option.
5. **Look before showing.** Rasterize or get a screenshot in both themes and
   check each card renders as intended.
6. **Let the user compose.** The user may combine parts ("4's marker with 2's
   rail"). Treat that as a ruling, render the combination as one more card,
   and confirm it before building.
7. **Record the ruling** in the mock's decisions list or the plan it governs,
   not only in chat.

## Boundaries

- Plain HTML, CSS and JavaScript the user can open. No build pipeline, no
  generator for the mock.
- Variants that differ on every channel at once teach the user nothing. Vary
  named channels.
- No production code before the user rules on the direction or the variant.

## Done means

- The user decided by looking, and the decision is written where the build
  will read it.
- For variants: every card was seen rendered in both themes, and the reference
  card shows measured values.
- For a mock: each in-page check has been seen to fail on a planted defect,
  and the wall was looked at in dark and light.
