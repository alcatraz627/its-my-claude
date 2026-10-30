# Defaults for fixes when the project sets none

Starting points that prevent the common "it looks weird" complaints. The
project's own tokens, font stack, spacing scale or component library win
wherever they exist. When unsure whether a value is a project decision or an
accident, match the surrounding code.

## Typography

- Sans: `Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif`
- Mono: `'JetBrains Mono', 'SF Mono', 'Fira Code', Consolas, monospace`
- Scale: 12, 14, 16, 18, 20, 24, 30, 36, 48 px
- Body: 16 px at line-height 1.5 for reading, 14 px at 1.4 for dense UI
- One visual H1 per page. Separate H2 to H4 by size and weight, not size alone.
- `font-display: swap` on loaded fonts

## Spacing

- 4 px base: 4, 8, 12, 16, 24, 32, 48, 64, 96
- Interactive padding at least 8 px, usually 12
- Card padding 16 to 24 px, section gaps 32 to 48 px
- Values like 13, 17 or 37 px signal an unplanned layout

## Color

- WCAG AA: 4.5:1 for body text, 3:1 for large text and UI parts. Measure it.
- One neutral family (slate, zinc or gray), never mixed
- Semantic: green success, amber warning, red error, blue info, each with a
  lighter tint for backgrounds
- Dark mode through CSS custom properties from the start, never hardcoded
  colors on elements

## Interactive states

- Every button, link and input has a visible focus ring, not a color change
  alone
- Hover on things that act, never on static text
- Click targets at least 44 by 44 px for touch, 32 by 32 for mouse only
- Disabled: opacity 0.5 to 0.6, `cursor: not-allowed`
- Every button that starts async work shows a loading state

## Layout

- Max width 1200 to 1280 px for full layouts, 720 to 800 px for reading
- Breakpoints 640, 768, 1024, 1280 px
- Left-align body text. Center only headings and hero sections.
- Grid for page layout, flexbox inside components
