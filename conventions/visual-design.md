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
related:
  - conventions/tui-design.md
  - conventions/cli-help-design.md
  - conventions/html-output.md
  - conventions/dashboard-tools.md
tier: 2
category: conventions
updated: 2026-06-21
stale_after_days: 365
---

# Visual design — color, hierarchy, and where to read more

How to make a UI surface (native app, web page, widget, CLI/TUI) read as designed
rather than assembled. Distilled from the claude-instances menu-bar redesign; the
worked example with hex values lives in that project's
`docs/dropdown-redesign.md`.

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

The de-chaos lever, in one line: **collapse the competing ambient colors to one low
chroma at one lightness; reserve high chroma for identity and severity.**

## Layout and hierarchy

- **Weight and spacing carry hierarchy; color is third.** An identity row reads as a
  header because it is heavier and has air above it, not because it is loud.
- **One type scale (≈3 tiers).** Title / body / caption by size+weight. Mono only
  for columnar or numeric content; system font for prose.
- **One spacing rhythm.** A single vertical-rhythm constant applied as both row
  spacing and section padding beats per-section guesses. Group; don't over-separate.
- **One truncation rule per field kind.** Prose clamps by line count with a tail `…`;
  paths middle-truncate to one line with the full value on hover; identifiers
  tail-truncate. Pick the rule by field kind, not per call site.
- **Detail stays; interaction shrinks.** Density is fine; never bury a *common*
  action behind a submenu/extra click.
- **Reusable row/column primitives.** When several sections hand-roll alignment
  (manual padding, ad-hoc stacks), build one composer they all feed. Inconsistent
  spacing is usually the absence of a shared primitive, not a tuning problem.

## Where to read more (per surface)

### Apple (macOS/iOS apps, menu-bar, SwiftUI)
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
full color study (perceptual tiers, the 17-token light/dark palette, sources) is in
that repo at `docs/dropdown-redesign.md` and `.claude/output/20260620-color-palette-research/palette.md`.
