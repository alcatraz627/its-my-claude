# kanban board: hazard ledger

Append-only. Facts that reading the code does not recover. Written by whoever
got bitten. Started 2026-08-09 during the UI pilot, which found the file
missing (research-sheet.md row 1.18).

## Concurrency

- **board.html and server.ts are edited by more than one session at a time.**
  On 2026-08-09 a colour-grammar conversion and a doc-preview feature were
  in flight in the same two files within the same hour, by different sessions,
  neither holding a lock. Nothing broke, because both used targeted Edits.
  A whole-file Write by either one would have destroyed the other's work: that
  exact loss happened elsewhere in this account on 2026-08-01, 30 appended
  lines gone. Before touching these files: `git diff --stat scripts/kanban/`,
  and if the diff holds work you do not recognise, use targeted Edits only and
  never a whole-file Write.
- The server serves both pages fresh per request, so a reload is enough to see
  an edit. There is no build step and no cache to bust.

## Colour and theme

- **A tinted attention well cannot carry hierarchy in light theme.** Before the
  2026-08-09 conversion, `--well-attn` and `--card` were both `#ffffff`: a
  contrast ratio of exactly 1.000, an invisible cue that read as present in
  code review. Attention now rides column width and border weight instead.
- **sRGB gamut clipping moves hue, not just chroma.** Six label colours were
  specified in OKLCH at fixed lightness and chroma. Two of them clipped on
  conversion and landed 24.7 and 20.2 degrees from a semantic hue, under the
  25 degree separation rule, while the specification said they were compliant.
  Verify hue distance on the POST-CLIP hex, never on the OKLCH input.
- **Raising one text tier for contrast can collapse the hierarchy it lives in.**
  The 2026-07-28 indictment recorded `--faint` raised past its bar, leaving
  1.18:1 dark and 1.13:1 light separation between two tiers, below the just
  noticeable difference. Any contrast fix re-measures the neighbours.
- Theme values must never be baked into inline styles at render time. A
  payload-dedup guard means a theme toggle does not re-render, so a baked
  value survives the toggle and shows the wrong theme's colour.
- A hardcoded colour inside a `[data-theme="light"]` rule is the same bug one
  level down: `.card:focus-visible` carried the old blue at `rgb(11 107 203)`
  and silently stopped tracking `--ring` when the token changed. Derive with
  `color-mix(in srgb, var(--ring) N%, transparent)`.

## Verification

- A green code review is not a look. Three defects in this surface's history
  passed code review and were caught only by rendering: the 1.000 attention
  well, the clipped label hues, and the stale focus-ring colour.
- The fixture board's own data contains oddities that look like render bugs.
  One card's note is literally `!now !now`, which reads as a double-rendered
  tag chip and is not. Probe the DOM before fixing what looks wrong.
- Some capabilities cannot be exercised on the fixture as seeded. The
  since-your-last-visit dot needs a delta against the localStorage read
  cursor; clearing the cursor produces a first visit, where nothing is new.
  Mark that capability UNCONFIRMED rather than claiming it verified.
