---
brief: Cross-platform visual-design reference — color harmony (perceptual OKLCH tiers + the de-chaos rule), layout/hierarchy/type/spacing/truncation principles, and curated links for designing Apple (HIG/SwiftUI/menu-bar/widget), web, and CLI/TUI UIs. Read when building or restyling any visual surface.
triggers:
  - topic:visual-design
  - topic:color
  - topic:palette
  - topic:ui-design
  - topic:design-system
  - phrase:"color palette"
  - phrase:"design system"
  - phrase:"make it look good"
  - phrase:"ui redesign"
  - topic:severity
  - phrase:"status color"
  - phrase:"traffic light"
related:
  - features/hook-design.md
  - conventions/tui-design.md
  - conventions/cli-help-design.md
  - conventions/html-output.md
  - conventions/dashboard-tools.md
  - conventions/ui-charter.md
tier: 2
category: conventions
updated: 2026-09-30
stale_after_days: 365
---

# Visual design — color, hierarchy, and where to read more

How to make a UI surface (native app, web page, widget, CLI/TUI) read as designed
rather than assembled. The worked example to copy is Switchboard's kit,
`~/Code/Claude/switchboard-mac/docs/design-kit.md`. The claude-instances dropdown
redesign these principles were first drawn from is not an exemplar; the owner
judged it a failure (see Provenance).

## Color: harmony beats count

A scene reads as chaotic not because it has many colors but because the colors sit
at **unequal perceptual weight**. In sRGB, green at "full saturation" is far louder
than blue at the same nominal saturation, so colors picked by eye fight each other.
Keep the colors — they aid identification — and make them one system:

1. **Lay every color on a perceptual grid (OKLCH).** Pick lightness (L) and chroma
   (C) per *emphasis tier*; vary only **hue** within a tier. Then "same tier" looks
   like "same weight," and nothing out-shouts its neighbors. This single move is
   what turns N independent picks into a palette.
2. **Three emphasis tiers, separated by chroma not hue.**
   - **Loud** (high C) — identity + danger. The things that should grab the eye
     (brand/model identity, the severity scale).
   - **Medium** — a glance-color or two worth noticing (e.g. money).
   - **Quiet** (low C) — ambient data kept on recognizable hues so it's still
     spottable, but de-chromaed so it recedes.
3. **Close the severity set.** Green→amber→red is a *shared, closed* three-color
   scale; nothing ambient may borrow those three hues at high chroma. One red
   always means one thing (the IBM Carbon "status colors are a closed set" rule).
4. **Restore 60-30-10.** ~60% neutral/calm, ~30% ambient color, ~10% loud accent.
   The common failure is inverting it — every datum saturated, so the real signals
   have no calm field to pop against. Demote the ambient band's *weight*, not its
   hue.
5. **Dark mode = same hue, +L −C.** Each dark value is the same OKLCH hue, lighter
   and less saturated. On translucent/blurred material keep chroma moderate and
   lightness mid-band, or saturated colors vibrate and near-background colors wash
   out. Never use pure primaries (`#00FF00`/`#FF0000`/`#0000FF`) on blur.
6. **Glass needs a legibility floor.** Blur does not stop what sits behind it
   from showing through: a terminal's red and green bands read straight through
   a menu material and cut text contrast. Put text rows on a backing opaque
   enough that contrast holds over any window behind, and check it over a busy
   window, not an empty desktop.

The de-chaos lever, in one line: **collapse the competing ambient colors to one low
chroma at one lightness; reserve high chroma for identity and severity.**

## Severity: what makes a light worth lighting

The rules above govern what severity *looks* like. This one governs when it fires,
which is the half that decides whether anyone still reads it in a month.

**A severity indicator fires on evidence of a real problem, not on a metric crossing
a threshold.** Its job is to call for attention, or to confirm something the reader
already suspects. A light that is academically accurate but corresponds to nothing
they feel is worse than no light, because it teaches them to discount every light
including the true ones. Owner ruling 2026-09-06, on a system monitor whose lights
tracked utilization percentages: *"the lights exist to call for attention or confirm
my laggy felt experience, so it should match up with that instead of being only
academically accurate."*

Three consequences worth designing to:

1. **Pick the trigger metric by correlation with the felt symptom, not by which
   number is easiest to read.** Utilization crosses lines constantly without anything
   being wrong. Saturation, queue depth, and stall time are what a person actually
   experiences as slowness. A CPU pinned at 100% with an empty run queue feels fine;
   the same 100% behind a deep queue is the thing they came to look at.
2. **A steady-state amber is a bug.** If an indicator sits warm during normal
   operation, its threshold is describing the machine's ordinary condition rather than
   a problem. Either re-baseline it or remove it.
3. **Prefer a rate, a duration, or a deviation from this machine's own baseline over
   an absolute level.** Sustained-for-N-intervals and unusual-for-this-hour both track
   felt experience far better than a fixed percentage, and neither needs the user to
   tune a number they have no way to choose well.

The hook analogue is the same idea costed differently: `features/hook-design.md`
weighs a false fire by what it costs to dismiss. A severity light and a warning hook
are both attention claims, and both are spent by firing when nothing was wrong.

## Layout and hierarchy

- **Weight and spacing carry hierarchy; color is third.** An identity row reads as a
  header because it is heavier and has air above it, not because it is loud.
- **One type scale (≈3 tiers).** Title / body / caption by size+weight. Mono only
  for columnar or numeric content; system font for prose.
- **One spacing rhythm.** A single vertical-rhythm constant applied as both row
  spacing and section padding beats per-section guesses. Group; don't over-separate.
- **Text wraps; it is never cut with an ellipsis.** Owner's standing rule: "text
  wraps, never an ellipsis cut". Prose, prompts and messages wrap to as many
  lines as they need. Where space truly cannot grow (a single-line path in a
  fixed column), show the whole value on hover or click, and say so. Pick the
  rule by field kind, not per call site.
- **Detail stays; interaction shrinks.** Density is fine; never bury a *common*
  action behind a submenu/extra click.
- **Reusable row/column primitives.** When several sections hand-roll alignment
  (manual padding, ad-hoc stacks), build one composer they all feed. Inconsistent
  spacing is usually the absence of a shared primitive, not a tuning problem.
- **Every surface ships three sizes over one token set: sm, md, lg.** sm is a
  laptop screen, md is comfortable on a wide monitor at arm's length, lg reads
  in a screen share without looking huge. One setting moves every surface of the
  product together. Text steps most; icons follow most of the way (so a glyph
  stays level with its word); inputs, padding and gaps step least, so a control
  grows without looking swollen beside its label. No literal size outside the
  tokens: a hard-coded font size or width is a surface that will not scale.
  Render-check md and lg, not only sm. Reference build: switchboard-mac
  `Sources/Scale.swift` (text 1 / 1.18 / 1.36, icons 85% of the text step,
  controls 60%), proposal prop-20261002-205759-bc.

## One product, one system


- **Sibling surfaces share one token source.** A menu, a window and two web
  pages of the same product draw colour, type and spacing from one set of
  tokens. Solving consistency one surface at a time produces surfaces that are
  each tidy and never agree (claude-instances: a palette for the menu only, a
  separate rainbow in its window, and two web pages in two visual languages).
- **Themes and styles sit on top of data, never inside it.** A theme is colour;
  a style is a reading mode (terminal, chat, printed essay). Both are swappable
  presentation over one data model, so adding one never touches parsing.
- **Every variant must be good on its own.** A theme or style that ships is
  judged by its weakest reading, not rescued by one strong feature. Fewer
  finished variants beat many half-finished ones.
- **The theme follows the OS until the person chooses.** Store only an explicit
  choice. Saving the OS-resolved value at load pins whatever the OS was on the
  first visit, and the page never follows the OS again.
- **Say a machine-wide fact once.** A condition true for the whole machine (a
  service down, a shared counter) appears once, at the top, not on every row. A
  warning lit on every row is not a warning; see Severity above.
- **Words on screen are for people.** No em dashes in UI text. No raw machine
  tokens (`06-01:21:34` elapsed times, unlabelled `1187t`, bare arrows for
  tokens); translate them or label them. Monospace only for code, paths and
  aligned numbers. See `rules/machine-token-where-human-words-belong.md`.
- **Judge by use, in the state and on the device that matter.** A screenshot of
  a surface looking right is not evidence it works. The claude-instances
  redesign was declared converged twice by audits of screenshots, then found
  "great looking but still pretty fucking useless" on the phone it was for.

## Where to read more (per surface)

### Apple (macOS/iOS apps, menu-bar, SwiftUI)
- House kit to copy for any new Swift menu-bar app: `~/Code/Claude/switchboard-mac/docs/design-kit.md`, with the build and packaging steps in `features/macos-menubar-widget.md` §0.
- Human Interface Guidelines — https://developer.apple.com/design/human-interface-guidelines
- HIG · The menu bar / menus — https://developer.apple.com/design/human-interface-guidelines/the-menu-bar
- HIG · Color — https://developer.apple.com/design/human-interface-guidelines/color
- SF Symbols (icon system) — https://developer.apple.com/sf-symbols/
- SwiftUI docs — https://developer.apple.com/documentation/swiftui
- AppKit `NSMenu`/`NSStatusItem` (menu-bar apps) — https://developer.apple.com/documentation/appkit/nsstatusitem

### Apple widgets
- HIG · Widgets — https://developer.apple.com/design/human-interface-guidelines/widgets
- WidgetKit — https://developer.apple.com/documentation/widgetkit

### Web pages and web UI
- Refactoring UI (the highest-leverage practical primer on hierarchy/spacing/color) — https://www.refactoringui.com
- Radix Colors (perceptual 12-step scales; the model for "same step = same job") — https://www.radix-ui.com/colors
- Tailwind color system — https://tailwindcss.com/docs/customizing-colors
- Material 3 · Color — https://m3.material.io/styles/color/system/overview
- IBM Carbon (status-color discipline, dark themes) — https://carbondesignsystem.com/elements/color/overview/
- OKLCH picker + explainer — https://oklch.com · https://bottosson.github.io/posts/oklab/

### CLI / TUI
- Command Line Interface Guidelines (clig.dev) — https://clig.dev
- In-house: [`conventions/cli-help-design.md`](cli-help-design.md) (help text, color, columns)
- In-house: [`conventions/tui-design.md`](tui-design.md) (fzf/gum, interactive launchers)

## Related in-house

- [`conventions/html-output.md`](html-output.md) — HTML rules (mandatory dark/light toggle, CSS vars)
- [`conventions/dashboard-tools.md`](dashboard-tools.md) — single-user dashboard build template
- Skills: `/web-design` (screenshot critique + tokens), `/designer-reviewer` (scores a
  UI screenshot against the dark/dense terminal-dashboard aesthetic), `/create-report`
  (styled HTML from markdown)

## Provenance

Distilled 2026-06-21 from the claude-instances menu-bar dropdown redesign. The
color study (perceptual tiers, a 17-token palette) is in that repo at
`docs/dropdown-redesign.md`; read it for the reasoning, not as a model, since
its dark column was never built and the owner judged the result a failure.
Corrected 2026-09-30 after a deep dive of that tool
(`~/.claude/widgets/claude-instances/.claude/output/20260930-deep-dive/map.md`):
wrap instead of ellipsis, the glass legibility floor, the exemplar moved to
Switchboard's kit, and the "One product, one system" section.
