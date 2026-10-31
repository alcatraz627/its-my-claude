# Visual design: color, hierarchy, and where to read more

How to make a UI surface (native app, web page, widget, CLI or TUI) read as
designed rather than assembled.

## Color: harmony beats count

A scene reads as chaotic not because it has many colors but because the colors
sit at **unequal perceptual weight**. In sRGB, green at "full saturation" is far
louder than blue at the same nominal saturation, so colors picked by eye fight
each other. Keep the colors, because they aid identification, and make them one
system:

1. **Lay every color on a perceptual grid (OKLCH).** Pick lightness (L) and
   chroma (C) per *emphasis tier*, and vary only **hue** within a tier. Then
   "same tier" looks like "same weight", and nothing out-shouts its neighbors.
   This single move is what turns N independent picks into a palette.
2. **Three emphasis tiers, separated by chroma, not hue.**
   - **Loud** (high C): identity and danger. The things that should grab the
     eye, such as brand or product identity and the severity scale.
   - **Medium**: a glance-color or two worth noticing, such as money.
   - **Quiet** (low C): ambient data kept on recognizable hues so it is still
     spottable, but de-chromaed so it recedes.
3. **Close the severity set.** Green, amber, red is a *shared, closed*
   three-color scale. Nothing ambient may borrow those three hues at high
   chroma. One red always means one thing (IBM Carbon's "status colors are a
   closed set" rule).
4. **Restore 60-30-10.** About 60% neutral and calm, 30% ambient color, 10%
   loud accent. The common failure inverts it: every datum saturated, so the
   real signals have no calm field to pop against. Demote the ambient band's
   *weight*, not its hue.
5. **Dark mode is the same hue with more L and less C.** Each dark value is the
   same OKLCH hue, lighter and less saturated. On translucent or blurred
   material keep chroma moderate and lightness mid-band, or saturated colors
   vibrate and near-background colors wash out. Never put pure primaries
   (`#00FF00`, `#FF0000`, `#0000FF`) on blur.
6. **Glass needs a legibility floor.** Blur does not stop what sits behind it
   from showing through. A terminal's red and green bands read straight through
   a menu material and cut text contrast. Put text rows on a backing opaque
   enough that contrast holds over any window behind, and check it over a busy
   window, not an empty desktop.

The de-chaos lever in one line: **collapse the competing ambient colors to one
low chroma at one lightness, and reserve high chroma for identity and
severity.**

`colors.css` in this folder is a ready palette built this way.

## Severity: what makes a light worth lighting

The rules above govern what severity *looks* like. This one governs when it
fires, which decides whether anyone still reads it in a month.

**A severity indicator fires on evidence of a real problem, not on a metric
crossing a threshold.** Its job is to call for attention, or to confirm
something the reader already suspects. A light that is accurate on paper but
matches nothing they feel is worse than no light, because it teaches them to
discount every light, including the true ones. The user's framing, on a system
monitor whose lights tracked utilization: the lights exist to call for
attention or confirm a laggy felt experience, so they should match that rather
than being only academically accurate.

Three consequences to design for:

1. **Pick the trigger metric by how well it tracks the felt symptom**, not by
   which number is easiest to read. Utilization crosses lines constantly with
   nothing wrong. Saturation, queue depth and stall time are what a person
   experiences as slowness. A CPU pinned at 100% with an empty run queue feels
   fine. The same 100% behind a deep queue is the thing they came to look at.
2. **A steady-state amber is a bug.** If an indicator sits warm during normal
   operation, its threshold describes the machine's ordinary condition, not a
   problem. Re-baseline it or remove it.
3. **Prefer a rate, a duration, or a deviation from this machine's own
   baseline** over an absolute level. "Sustained for N intervals" and "unusual
   for this hour" both track felt experience far better than a fixed
   percentage, and neither asks the user to tune a number they cannot choose
   well.

A warning in any form (a light, a banner, a lint) is an attention claim, and
each false fire spends it.

## Layout and hierarchy

- **Weight and spacing carry hierarchy. Color is third.** An identity row reads
  as a header because it is heavier and has air above it, not because it is
  loud.
- **One type scale, about three tiers.** Title, body, caption, by size and
  weight. Mono only for columnar or numeric content, the system font for prose.
- **One spacing rhythm.** A single vertical-rhythm constant used as both row
  spacing and section padding beats per-section guesses. Group, and do not
  over-separate.
- **Text wraps. It is never cut with an ellipsis.** This is the user's standing
  rule. Prose, prompts and messages wrap to as many lines as they need. Where
  space truly cannot grow (a single-line path in a fixed column), show the
  whole value on hover or click, and say so. Pick the rule by field kind, not
  per call site.
- **Detail stays, interaction shrinks.** Density is fine. Never bury a *common*
  action behind a submenu or an extra click.
- **Reusable row and column primitives.** When several sections hand-roll
  alignment (manual padding, ad-hoc stacks), build one composer they all feed.
  Inconsistent spacing is usually a missing shared primitive, not a tuning
  problem.
- **Every surface ships three sizes over one token set: sm, md, lg.** sm fits a
  laptop screen, md is comfortable on a wide monitor at arm's length, lg reads
  in a screen share without looking huge. One setting moves every surface of
  the product together. Text steps most, icons follow most of the way so a
  glyph stays level with its word, and inputs, padding and gaps step least, so
  a control grows without looking swollen beside its label. A build that worked
  used text at 1, 1.18 and 1.36, icons at 85% of the text step and controls at
  60%. No literal size outside the tokens: a hard-coded font size or width is a
  surface that will not scale. Render-check md and lg, not only sm.

## One product, one system

- **Sibling surfaces share one token source.** A menu, a window and two web
  pages of one product draw color, type and spacing from one set of tokens.
  Solving consistency one surface at a time gives surfaces that are each tidy
  and never agree: a palette for the menu only, a separate rainbow in its
  window, two web pages in two visual languages.
- **Themes and styles sit on top of data, never inside it.** A theme is color.
  A style is a reading mode (terminal, chat, printed essay). Both are swappable
  presentation over one data model, so adding one never touches parsing.
- **Every variant must be good on its own.** A shipped theme or style is judged
  by its weakest reading, not rescued by one strong feature. Fewer finished
  variants beat many half-finished ones.
- **The theme follows the OS until the person chooses.** Store only an explicit
  choice. Saving the OS-resolved value at load pins whatever the OS was on the
  first visit, and the page never follows the OS again.
- **Say a machine-wide fact once.** A condition true for the whole system (a
  service down, a shared counter) appears once, at the top, not on every row. A
  warning lit on every row is not a warning.
- **Words on screen are for people.** No em dashes in UI text. No raw machine
  tokens (`06-01:21:34` elapsed times, an unlabelled `1187t`, bare arrows):
  translate or label them. Monospace only for code, paths and aligned numbers.
- **Judge by use, in the state and on the device that matter.** A screenshot of
  a surface looking right is not evidence it works. A redesign once passed two
  screenshot audits and was then found useless on the phone it was built for.

## Where to read more

### Apple (macOS and iOS apps, menu bar, SwiftUI, widgets)

- Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines
- HIG, the menu bar: https://developer.apple.com/design/human-interface-guidelines/the-menu-bar
- HIG, color: https://developer.apple.com/design/human-interface-guidelines/color
- HIG, widgets: https://developer.apple.com/design/human-interface-guidelines/widgets
- SF Symbols: https://developer.apple.com/sf-symbols/
- SwiftUI: https://developer.apple.com/documentation/swiftui
- WidgetKit: https://developer.apple.com/documentation/widgetkit
- AppKit `NSStatusItem` (menu-bar apps): https://developer.apple.com/documentation/appkit/nsstatusitem

### Web pages and web UI

- Refactoring UI, the most practical primer on hierarchy, spacing and color: https://www.refactoringui.com
- Radix Colors, perceptual 12-step scales and the model for "same step, same job": https://www.radix-ui.com/colors
- Tailwind color system: https://tailwindcss.com/docs/customizing-colors
- Material 3 color: https://m3.material.io/styles/color/system/overview
- IBM Carbon, status-color discipline and dark themes: https://carbondesignsystem.com/elements/color/overview/
- OKLCH picker and explainer: https://oklch.com and https://bottosson.github.io/posts/oklab/

### CLI and TUI

- Command Line Interface Guidelines: https://clig.dev
- The `tool-design` skill covers help text, terminal color and interactive
  launchers.
