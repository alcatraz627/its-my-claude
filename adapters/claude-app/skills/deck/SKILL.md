---
name: deck
description: Builds one self-contained HTML slide deck with presenter notes from a source or the conversation, checks every slide for overflow, and traces each claim to a source before hand-off.
---

# Deck

One HTML file that opens on a double-click: no library, no build, no network.
Presenter notes never show in the room. Every slide is checked for overflow,
because overflow is the first failure real decks hit. Every claim is traced to
a source line, because a deck its author believes is clean still carries
contradictions and overstatements.

Your job is content and structure. The look, keyboard, notes window, print
layout and overflow measurement are already in `references/deck-shell.html`.
Do not redesign them.

## Step 1: Gather and write the claim ledger

Read the sources: files the user attached, links, or this conversation. Write
a claim ledger in your reply, about ten lines: every number, decision and
quote you intend to use, each with where it comes from (file and line, URL,
or "user, this conversation"). A claim with no source does not go on a slide.

## Step 2: Outline

Start from this skeleton and edit it to the argument:

```
1      title and one-line sub      what this is
2      the problem                 one claim
3      (optional) second problem   keep only if there really are two
4      one picture                 a diagram slide
5..n   one claim per slide         each with its number
n+1    honest numbers              a table with a caveat column, including what is NOT proven
n+2    the ask, what is next       a numbered list and a Show row of links
```

Reorder, drop or add. Say in the hand-off where you left the skeleton and why.
If the user asked for an outline only, stop here.

## Step 3: Author

Copy `references/deck-shell.html` and replace the example slides. Its comments
show every component: kicker, headline, lede, lists, callouts (note, tip,
info, ok, warn, bad, aside, quote, term, ask, stat), stats grid, toned table,
diagram, cards, columns, Show row and the closing `leave` line.

- **One claim per slide.** The headline states it as a sentence.
- **Notes** go in `<aside class="notes">`, as full sentences the speaker
  reads. Never a bullet list.
- **Colour only through the tokens** (`var(--ok)`, `--warn`, `--bad`,
  `--dim`, `--accent`). A hex or `rgb()` value inside a slide is an error. The
  tokens carry dark and light, and a literal breaks one of them.
- **Wide slides.** Add `wide` to `.slide-inner` for tables, diagrams, cards,
  columns and code. Diagrams stay within 113 columns.
- **Budget.** Keep each slide at or under 18 estimated lines: headline 2,
  kicker 1, lede 1, a paragraph 1 per 95 characters, a bullet 1 per 90
  characters, a table its rows plus 1, a diagram or code its lines, a stat 4,
  a callout 1 plus its text. Over 18, split the slide or cut.
- **Links** in the Show row are `https` URLs the room can open.
- Put the deck title in `<title>`. Saved theme and position are keyed on it.

## Step 4: Check for overflow

Pick one, and say plainly in the hand-off which one you did:

1. **Measured in the sandbox.** If a headless browser installs (for example
   `pip install playwright` and `playwright install chromium`), load the deck
   at 1440 by 900 and again at 1920 by 1080. Read the JSON in
   `<pre id="deck-check">`: it lists every slide with `over`, `scroll` and
   `client`. Confirm it measured as many slides as the file has. A report of
   zero slides measured nothing and is not a pass. Then screenshot each slide
   in both themes (`?s=N` and `?s=N&light=1`) and view the images.
2. **Estimated, then shown to the user.** If no browser installs, apply the
   18-line budget slide by slide, and list each slide's estimate. Then ask the
   user to page through the artifact and screenshot any slide whose counter
   shows "overflow" or that carries a red OVERFLOW badge. The deck measures
   itself on load in their browser, so the badge is a real measurement.

Fix every slide that overflows and check again. An estimate is not a
measurement, so do not call an estimated deck verified.

## Step 5: Prose gate

Check each slide and its notes for these, and count instead of eyeballing.
When the sandbox is available, a short script does the counting.

| Check | Fires when |
|---|---|
| em-dash | any em-dash on a slide or in notes |
| claims | two paragraphs, or a paragraph and a list over 60 words, on a slide with no table, diagram or cards |
| bullets | more than 6 bullets, or a bullet over 140 characters |
| words | more than 90 words of body prose on one slide |
| adjectives | a size word where a number belongs: `many`, `significant`, `huge`, `dramatic`, `massive`, `robust`, `seamless`, `numerous`, `substantial`, `countless` |
| triad | a rule-of-three list such as "fast, simple, and reliable" |
| sentence | a sentence over 25 words |
| notes voice | a note that is a fragment or a bullet list |
| unsourced | a percentage or large number with no source word (per, from, measured, n=, test) on the slide or in its notes |

Zero to two findings: fix each or justify it in one line. Three or more: fix,
check again, and fix again until it is clean or every remaining finding has a
one-line justification in the hand-off.

## Step 6: Trace every claim

After the deck is written, re-read the sources themselves, not your memory of
them, and build one row per claim, number, quote and decision on every slide:

`slide N · "claim, short" · source location or "none" · SUPPORTED | OVERSTATED | CONTRADICTED | UNSOURCED`

- **OVERSTATED**: the source says something weaker or conditional. Quote
  both. Watch for "try to keep X" hardened into "X stays".
- **CONTRADICTED**: the source says otherwise, including a later decision in
  the conversation that reversed an earlier one.
- **UNSOURCED**: nothing the audience can open backs it.

Also check: quotes on slides are verbatim, slide 1 names the source of record,
the honest-numbers slide names what is not proven, and no note contradicts its
slide. Any CONTRADICTED or UNSOURCED row blocks hand-off until fixed. Put the
counts by status in your reply, not only in a file.

For a deck that will be quoted back, shown to a board, or replace a source of
record, offer a deeper pass in one line: a second trace with a different lens
and screenshots of every slide in both themes. Do not run it unasked.

## Step 7: Deliver

- Publish the deck as an HTML artifact so the user can page through it, and
  offer `deck.html` as a download for presenting.
- **Presenting:** arrow keys, space, Page Up and Page Down, Home and End move
  between slides. `n` toggles a notes strip, `t` toggles the theme. The
  "notes" button opens a synced presenter window for a second screen. That
  window needs the file opened in a browser, because previews often block
  pop-ups, and then the button opens the notes strip instead. `?s=N` links to
  a slide. Printing gives one slide per page.

End with: the file name, the overflow line (measured at which sizes, or
estimated and waiting on screenshots), the prose gate result with any
justifications, the trace counts, and where the outline left the skeleton.

## Related skills

- `plain-writing` for slide and notes prose.
- `diagrams` or `svg` for the picture slide.
- `house-rules` before calling the deck done.
