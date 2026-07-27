---
brief: HTML generation rules: dark/light mode toggle (MANDATORY), CSS custom properties, future rules placeholder
triggers:
  - topic:html-output
  - topic:reports
  - topic:visualizations
  - phrase:"generate HTML"
  - phrase:"HTML report"
related: []
tier: 2
category: conventions
updated: 2026-04-24
stale_after_days: 90
---

# Html Output
Standards for HTML files Claude generates.

## MANDATORY — Dark/light mode toggle

Every HTML file written to disk **must** include a dark/light mode toggle button in the top-right corner. Dark mode is the default. This applies to ALL HTML outputs: reports, matrices, previews, visualizations — no exceptions.

### Implementation pattern

```html
<button
  onclick="document.body.classList.toggle('light')"
  style="position:fixed;top:12px;right:16px;z-index:999;
         background:var(--surface);color:var(--text);
         border:1px solid var(--border);border-radius:6px;
         padding:6px 10px;cursor:pointer;font-size:14px;"
  aria-label="Toggle light/dark mode"
>
  ☀ / ☾
</button>
```

Use CSS custom properties (`--bg`, `--surface`, `--text`, `--dim`, `--border`) with a `body.light { ... }` override block. Never hardcode colors directly on elements — always go through the CSS vars so the toggle works.

### Default dark palette

```css
:root {
  --bg: #0a0a0a;
  --surface: #141414;
  --text: #e8e8e8;
  --dim: #888;
  --border: #2a2a2a;
}
body.light {
  --bg: #fafafa;
  --surface: #ffffff;
  --text: #141414;
  --dim: #666;
  --border: #e0e0e0;
}
```

Those five greys are the floor. They carry a report, but there is nothing here to
build a status pill or a filled button out of. When the page needs real colour, use
[`html-assets/colors.css`](html-assets/colors.css) rather than extending this block.
It defines these same five names, so the toggle above keeps working untouched, and
adds ramps, brand/accent, and status pairs on top. Rebrand it by editing the hues in
its Layer 0. Don't reach past the slots into a ramp from your markup, or the next
theme change stops being one edit.

## Complexity tiers

Pick the lightest tier that does the job. Complexity escalates only on evidence.

| Tier | Use for | Stack |
|------|---------|-------|
| **Simple** (default) | Reports, logs, matrices, index pages, single-column docs | Plain HTML + CSS vars + the toggle button above |
| **Medium** | Multi-column dashboards, interactive tables, tabbed panels | Add vanilla JS; still no framework |
| **Complex** | Rich dashboards, complex layouts, themable component-heavy pages, user-facing UI prototypes | Tailwind v4 + DaisyUI v5 — only if clear signal that simpler didn't suffice |

### When to escalate to Complex

- User has given **repeated** feedback that a Simple/Medium output looks bad or unclear
- The output needs a dozen+ components that would be tedious to hand-style
- A prototype will be handed to a human designer who expects a utility-class codebase

### Complex stack — Tailwind v4 + DaisyUI v5

Primary sources (pull these in when escalating):

- **DaisyUI v5 llms.txt** — [https://daisyui.com/llms.txt](https://daisyui.com/llms.txt) — start here for component names + class patterns
- **DaisyUI MCP** — [https://github.com/birdseyevue/daisyui-mcp](https://github.com/birdseyevue/daisyui-mcp) — install as MCP if repeated use
- **Tailwind v4 Agent Skills** — [https://github.com/Lombiq/Tailwind-Agent-Skills](https://github.com/Lombiq/Tailwind-Agent-Skills) — local skill for tailwind-heavy projects

Only add these to a project's MCP/skill set if the user has asked for repeated HTML work with them — don't burn context on a one-shot.

## Snippet promotion workflow

When generating HTML (via `/create-report`, by hand, or in a skill), if a snippet proves genuinely reusable — not just a one-off — promote it here so future runs start with a battle-tested version instead of reinventing.

**Criteria for promotion:**

- Reused in 2+ sessions OR explicitly praised by the user
- Self-contained (can be copy-pasted without chasing dependencies)
- Works with the dark/light toggle (uses CSS vars)

**Where snippets live:**

- Small snippets (<20 lines): inline in this file, labeled
- Larger snippets or collections: `~/.claude/conventions/html-assets/<name>.{html,css,js}`, indexed in the table below

### Asset index

| Asset | Purpose | Path |
|-------|---------|------|
| Dark/light toggle button | MANDATORY — see top of file | inline above |
| Searchable data dashboard | Summary cards + live text filter + click-to-expand rows with nested sub-entity detail tables; self-contained, dark/light persists. For "counts at a glance + drill into specifics" over entity→sub-entities→detail data. Adapt `cards()`/`row()`/detail render + the summary grid columns. | `conventions/html-assets/data-dashboard.html` |
| Color-palette picker | Per-group color chooser: a full design-system palette in `<optgroup>` dropdowns (header + body per group), live mock preview, auto white/dark header text by WCAG contrast (reddens below 4.5:1), and a copy-paste summary of the picks. For letting a human dial in colors before you hard-code them. `.build.py` regenerates the HTML from a palette dict — edit the `TW` map / `COLS` / `GROUPS` for a different palette or preview shape. | `conventions/html-assets/color-palette-picker.{html,build.py}` |
| Theming system (colors.css) | The palette-variables + scheme-switcher component this file's TODO used to ask for. Two layers: seven OKLCH ramps at full 50→950 (neutral/brand/accent/success/warning/danger/info), then the semantic slots your markup actually uses. It defines the five vars the mandatory toggle above needs (`--bg`, `--surface`, `--text`, `--dim`, `--border`), so dropping it in satisfies the dark/light rule instead of restating it. Dark is default; `body.light` flips it, and `:root[data-theme="light"]` works too. Also ships `--surface-2`, three text tiers, brand/accent with `-content` pairs, status soft/line pairs, shadows and radii. **To rebrand, change the hue numbers in Layer 0 and stop**, since nothing downstream hardcodes a color. Ported from the versable-builder kit's Layer-0/Layer-1 split with brand-neutral placeholder hues. Verified in both modes. | `conventions/html-assets/colors.css` |
| _(add entries as they're promoted)_ | | |

When the index grows past ~8 rows, break snippets out to their own file per category (`buttons.html`, `tables.html`, `modals.html`, etc.) and keep this table as the directory.

## TODO — future component library (for a later session)

Capture this for future reference. Build out when repeated use justifies the context cost:

- Reference navbar + footer (dark-mode aware)
- Button component variants (primary/secondary/danger, sizes)
- JS-embed icon collection (single-file icon set, bundled or CDN) → may branch to sub-doc
- Basic modal + dialog pattern
- Code-block component with syntax coloring for: markdown, JSON, TypeScript, YAML, TOML, `.env`, Python, Rust
- Print stylesheet baseline

File individual components here as they're promoted from real work. Don't scaffold speculatively.

## Reserved for future rules

- Responsive breakpoints / mobile readability
- Accessibility minimums (contrast, `aria-label`, keyboard nav)
- Print stylesheet expectations
- Embedded font handling (self-host vs CDN)
- Table vs card layout decision heuristics
