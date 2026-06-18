---
name: web-design
description: Reviews, generates, and systematizes web UI designs — screenshot-based critique with actionable CSS fixes, design token extraction, and page layout generation with experienced defaults.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebFetch, mcp__plugin_chrome-devtools-mcp_chrome-devtools__*
user-invokable: true
argument-hint: "<review | system | page <type>> [options]"
---

## Brief

Professional web UI design skill with three modes: `review` (screenshot-based critique with
actionable fixes), `system` (extract and consolidate design tokens from existing code), and
`page` (generate page layouts with proven patterns and experienced defaults). Separates visual
regression testing into `/visual-regression` for Playwright-specific work.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without
> holding its lock.

---

## Usage

```
/web-design review <screenshot-path | url>
/web-design system [--output <path>]
/web-design page <landing | dashboard | form | settings | auth | pricing> [--stack <tailwind | css>]
```

| Subcommand | Description |
| ---------- | ----------- |
| `review` | Critique a UI from a screenshot or live URL |
| `system` | Extract and consolidate design tokens from existing code |
| `page <type>` | Generate a page layout with proven patterns |

| Option | Applies to | Description |
| ------ | ---------- | ----------- |
| `--output <path>` | `system` | Where to write the token file (default: `src/styles/tokens.css`) |
| `--stack <name>` | `page` | CSS approach: `tailwind` (default) or plain `css` |

---

## Experienced Defaults

These are the fallback choices for generated UI — sensible starting points that prevent the
most common "it looks weird" complaints. Apply them **unless the project's own design tokens or
stack already specify otherwise.** A project with its own font stack, spacing scale, or component
library wins: read its tokens first (the `system` subcommand does this) and follow them. These
defaults fill the gaps the project leaves open; they do not override decisions the project has
already made. When in doubt about whether something is a project decision or an accident, match
the surrounding code rather than reaching for the default here.

### Typography
- **Font stack:** `Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif`
- **Code font:** `'JetBrains Mono', 'SF Mono', 'Fira Code', Consolas, monospace`
- **Scale:** Use a consistent type scale. Recommended: 12 / 14 / 16 / 18 / 20 / 24 / 30 / 36 / 48px
- **Body text:** 16px, line-height 1.5-1.6 for reading content; 14px, 1.4 for dense UI
- **Heading hierarchy:** Give each page exactly one visual H1, with H2-H4 differentiated by size and weight (not size alone)
- **Font loading:** Always include `font-display: swap` to prevent FOIT

### Spacing
- **Base unit:** 4px. All spacing must be multiples: 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 / 96px
- **Component padding:** minimum 12px (never less than 8px for interactive elements)
- **Section gaps:** 32-48px between major sections
- **Card padding:** 16-24px internal padding
- **Never:** arbitrary values like 13px, 17px, 37px — they signal an unplanned layout

### Color
- **Contrast:** Text should meet WCAG AA (4.5:1 for body text, 3:1 for large text / UI components). Don't assert this from looking at the colors — measure it. When a live page is available, drive the `chrome-devtools` MCP to read computed contrast ratios from the rendered DOM (it surfaces the same AA/AAA pass/fail Chrome DevTools' contrast picker shows), or run a Lighthouse accessibility audit through it. A measured ratio is a fact; an eyeballed one is a guess that ships inaccessible text.
- **Gray scale:** Use a consistent neutral palette (slate, zinc, or gray — pick one, never mix)
- **Semantic colors:** success (green), warning (amber), error (red), info (blue) — with matching lighter tints for backgrounds
- **Dark mode:** If requested, use CSS custom properties from the start. Never hardcode colors on elements.

### Interactive Elements
- **Focus states:** Give every button, link, and input a visible focus indicator (outline or ring, not color change alone)
- **Hover states:** Buttons need hover. Links need hover. Don't add hover to everything (no hover on static text or labels).
- **Click targets:** Minimum 44x44px for touch, 32x32px for mouse-only
- **Disabled states:** Reduced opacity (0.5-0.6) + `cursor: not-allowed` + `pointer-events: none`
- **Loading states:** Every button that triggers an async action should show a loading state

### Layout
- **Max content width:** 1200-1280px for full-width layouts, 720-800px for reading content
- **Responsive breakpoints:** 640 / 768 / 1024 / 1280px (Tailwind defaults)
- **Don't center everything.** Left-align body text. Center only headings and hero sections.
- **Grid preference:** CSS Grid for page layouts, Flexbox for component internals

---

## Subcommand: `review`

### Phase 1 — Capture

**If screenshot path provided:**
- Read the screenshot image using the Read tool
- Analyze the visual content

**If URL provided:**
- Use Playwright MCP tools to navigate and screenshot:
  ```
  browser_navigate(url) → browser_take_screenshot()
  ```
- Also capture at mobile width (375px) if responsive review is relevant

### Phase 2 — Analyze

Score the UI on 6 dimensions (1-10 each):

| Dimension | What to evaluate |
| --------- | --------------- |
| **Visual Hierarchy** | Is there a clear reading order? Does the eye know where to go first? |
| **Spacing Consistency** | Are margins/paddings from a consistent scale? Any cramped or floaty areas? |
| **Typography** | Is the type scale logical? Are weights used meaningfully? Is body text readable? |
| **Color & Contrast** | Does it meet WCAG AA? Are semantic colors used correctly? Is the palette cohesive? |
| **Interactive States** | Do buttons have hover/focus? Are disabled states clear? Are click targets adequate? |
| **Responsive Readiness** | Does the layout adapt or will it break on mobile? Are images/tables handled? |

For a live URL (not a static screenshot), measure the Color & Contrast score rather than
estimating it: drive the `chrome-devtools` MCP against the rendered page to read computed
contrast ratios, or run its Lighthouse accessibility audit. Report measured ratios with the
elements that fail. From a flat screenshot you can only flag *suspected* contrast problems —
say so, and don't claim AA compliance you didn't measure.

### Phase 3 — Report

Format:
```
─────────────────────────────────────────────────────
  Web Design Review
─────────────────────────────────────────────────────

  Overall: 7.2/10

  Visual Hierarchy     8/10  Clear hero → CTA flow
  Spacing              6/10  Mixed 12px and 15px gaps in card grid
  Typography           7/10  Good scale, but H3 and H4 are same weight
  Color & Contrast     8/10  AA compliant, but muted CTA button
  Interactive States   5/10  Missing focus indicators on nav links
  Responsive           8/10  Grid collapses well, table needs scroll

─────────────────────────────────────────────────────

  Top Issues (by impact):

  1. [HIGH] No focus indicators on navigation links
     Fix: `nav a:focus-visible { outline: 2px solid #3b82f6; outline-offset: 2px; }`

  2. [MEDIUM] Card grid has inconsistent gaps (12px vs 15px)
     Fix: Standardize to `gap: 16px` (4px grid)

  3. [MEDIUM] H3 and H4 are visually identical
     Fix: H3: 18px/600, H4: 16px/500 (differentiate by weight)

  4. [LOW] CTA button could be more prominent
     Fix: Increase padding to `12px 24px`, use primary color at full saturation

─────────────────────────────────────────────────────
```

Every issue must include a concrete CSS fix, not just a description.

### Integration with /visual-regression

For automated before/after comparison, use:
```
/visual-regression baseline <url>
# make changes
/visual-regression compare <url>
```

---

## Subcommand: `system`

Extract a consolidated design token set from an existing codebase.

### Phase 1 — Scan

1. **CSS custom properties:** Grep for `--` prefixed variables in all CSS/SCSS files
2. **Tailwind config:** Read `tailwind.config.ts` or `tailwind.config.js` for extended theme values
3. **Styled-components / CSS-in-JS:** Grep for `theme.` references
4. **Inline styles:** Grep for `style={{` or `style=` in component files (flag as tech debt)

### Phase 2 — Analyze

Detect inconsistencies:
- How many distinct font sizes? (flag if >8)
- How many distinct colors? (flag if >12 non-semantic)
- How many distinct spacing values? (flag if they don't follow a scale)
- How many distinct border-radius values? (flag if >3)
- How many distinct shadows? (flag if >4)

### Phase 3 — Generate Token File

Output a consolidated CSS custom properties file:

```css
:root {
  /* Typography */
  --font-sans: Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', 'SF Mono', Consolas, monospace;
  --text-xs: 0.75rem;    /* 12px */
  --text-sm: 0.875rem;   /* 14px */
  --text-base: 1rem;     /* 16px */
  --text-lg: 1.125rem;   /* 18px */
  --text-xl: 1.25rem;    /* 20px */
  --text-2xl: 1.5rem;    /* 24px */

  /* Spacing */
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-3: 0.75rem;  /* 12px */
  --space-4: 1rem;     /* 16px */
  --space-6: 1.5rem;   /* 24px */
  --space-8: 2rem;     /* 32px */
  --space-12: 3rem;    /* 48px */

  /* Colors */
  --color-primary: ...;
  --color-primary-hover: ...;
  /* ... extracted from codebase */

  /* Radii */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0,0,0,0.05);
  --shadow-md: 0 4px 6px rgba(0,0,0,0.1);
  --shadow-lg: 0 10px 15px rgba(0,0,0,0.1);
}
```

Print a migration plan showing which hardcoded values in the codebase should be replaced with which tokens.

---

## Subcommand: `page <type>`

Generate a complete page layout using proven patterns.

### Available Types

| Type | Layout Pattern | Key Components |
| ---- | -------------- | -------------- |
| `landing` | Hero → Features → Social Proof → CTA → Footer | Hero with H1 + subtitle + CTA, 3-column feature grid, testimonial cards |
| `dashboard` | Sidebar nav + Header + Content grid | Stats cards, data table, chart placeholders, activity feed |
| `form` | Centered card with multi-step or single-page form | Input groups, validation messages, submit with loading state |
| `settings` | Two-column: sidebar nav + settings panels | Toggle groups, form fields, danger zone, save button |
| `auth` | Centered card on subtle background | Login/signup form, OAuth buttons, forgot password link |
| `pricing` | Pricing cards with feature comparison | 2-3 tier cards, toggle monthly/yearly, feature checkmark table |

### Phase 1 — Context

1. Detect existing styling approach (Tailwind? CSS Modules? Styled-components?)
2. Read existing components to match patterns (how are buttons styled? what's the nav structure?)
3. If no existing code: ask for preferred stack

### Phase 2 — Generate

Generate the page as a complete component file with:
- All styles following the Experienced Defaults above
- Responsive layout (mobile-first)
- All interactive states (hover, focus, disabled, loading)
- Semantic HTML (proper heading hierarchy, landmark regions, ARIA where needed)
- Placeholder content that looks realistic (not "Lorem ipsum" — use domain-appropriate text)

### Phase 3 — Verify

If a dev server is running:
1. Navigate to the page
2. Take a screenshot
3. Check against the Experienced Defaults checklist
4. Fix any violations found

---

## Notes

- This skill writes CSS and component code but never touches backend logic or routes
- The `review` subcommand is non-destructive — it analyzes and reports, never modifies code unless asked
- The `system` subcommand proposes a token file but does NOT auto-replace values in existing code — it prints a migration plan the user can execute
- For visual regression testing (automated before/after screenshot comparison), use the separate `/visual-regression` skill
- Pairs well with: `/designer-reviewer` (terminal aesthetic), `frontend-design` plugin (general frontend), `/visual-regression` (automated diffing)

### See Also — personas that drive this skill

- `~/.claude/personas/art-director.md` — the visual-direction working mode. Adopt it when the
  task is "make this look right" rather than "review this UI"; it turns a vague aesthetic
  impulse into a concrete brief, then reaches for `web-design page`/`review` to realize it.
- `~/.claude/personas/fullstack-engineer.md` — the app-and-dashboard builder. It calls
  `web-design` for layout generation and review as part of shipping a frontend, alongside
  `/designer-reviewer`, the `chrome-devtools` MCP, and `/skeptical-review` before declaring done.
- The Experienced Defaults section is the baseline for UI generation and review — applied where the project hasn't already chosen, and yielding to the project's own tokens/stack where it has
