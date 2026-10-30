# HTML pages: theme toggle, tokens, complexity tiers

Rules for any HTML page or artifact built for the user: reports, matrices,
previews, dashboards, mocks.

## Mandatory: a dark and light toggle

Every HTML page carries a visible dark and light toggle in the top-right
corner. No exceptions for "just a quick report". Three parts make it work:

1. **Every color is a CSS custom property.** At minimum `--bg`, `--surface`,
   `--text`, `--dim` and `--border`. Elements never carry a hex value, or the
   other theme has a hole in it.
2. **Dark is the designed-first palette.** The tokens on `:root` are the dark
   set, and a `[data-theme="light"]` block (or `body.light`) overrides them.
3. **With no stored choice, follow the OS.** Read `prefers-color-scheme` on
   load and when it changes. Store only an explicit click on the toggle.
   Storing the resolved value at load pins the page to the OS setting of the
   first visit.

### The five-token floor

```css
:root {
  --bg: #0a0a0a; --surface: #141414; --text: #e8e8e8;
  --dim: #888; --border: #2a2a2a;
  color-scheme: dark;
}
:root[data-theme="light"] {
  --bg: #fafafa; --surface: #ffffff; --text: #141414;
  --dim: #666; --border: #e0e0e0;
  color-scheme: light;
}
body { background: var(--bg); color: var(--text); }
```

Those five greys carry a report. They give nothing to build a status pill or a
filled button from. When the page needs real color, use `colors.css` in this
folder instead of extending the block. It defines the same five names, so the
toggle keeps working, and adds ramps, brand and accent, and status pairs.

### The toggle

```html
<button id="theme-toggle" aria-label="Toggle light and dark mode"
  style="position:fixed;top:12px;right:16px;z-index:999;
         background:var(--surface);color:var(--text);
         border:1px solid var(--border);border-radius:6px;
         padding:6px 10px;cursor:pointer;font-size:14px">☀ / ☾</button>
<script>
(function () {
  var root = document.documentElement;
  var mq = matchMedia('(prefers-color-scheme: light)');
  function stored() { try { return localStorage.getItem('theme'); } catch (e) { return null; } }
  function apply() { root.dataset.theme = stored() || (mq.matches ? 'light' : 'dark'); }
  apply();
  mq.addEventListener('change', apply);
  document.getElementById('theme-toggle').onclick = function () {
    var next = root.dataset.theme === 'dark' ? 'light' : 'dark';
    try { localStorage.setItem('theme', next); } catch (e) {}
    root.dataset.theme = next;
  };
})();
</script>
```

Storage can throw in a private window or a sandboxed preview, so every access
sits in `try`. The page must render correctly without it.

## Complexity tiers

Pick the lightest tier that does the job. Escalate only on evidence.

| Tier | Use for | Stack |
|---|---|---|
| Simple (default) | Reports, logs, matrices, index pages, single-column docs | Plain HTML, CSS tokens, the toggle |
| Medium | Multi-column dashboards, interactive tables, tabbed panels | Add vanilla JS, still no framework |
| Complex | Rich dashboards, component-heavy themable pages, prototypes for a designer | Tailwind v4 with DaisyUI v5 |

Escalate to Complex only when:

- the user has said more than once that a Simple or Medium page looks bad or
  unclear,
- the page needs a dozen or more components that would be tedious to style by
  hand, or
- the prototype goes to a designer who expects a utility-class codebase.

DaisyUI publishes an LLM-oriented index of its components and class patterns
at https://daisyui.com/llms.txt. Read it when escalating rather than guessing
class names.

## Reusable starting points in this folder

| File | What it is | Adapt by |
|---|---|---|
| `colors.css` | Two-layer OKLCH theme: seven ramps from 50 to 950, then the semantic slots markup uses. Dark default, light override, status soft and line pairs, shadows, radii. | Changing the hue numbers in Layer 0 and nothing else |
| `data-dashboard.html` | Single-file dashboard: summary cards, a live text filter, rows that expand into sub-entity cards and a detail table. Theme toggle included. | Replacing the JSON in the data script, then the three render functions `cards()`, `row()` and `item()` and the summary grid columns |

The dashboard suits "counts at a glance, then drill into specifics" over any
entity, sub-entity, detail-row dataset. When generating it from code, keep the
template plain and inject data by string replacement at a sentinel, not by a
templating language whose braces collide with CSS and JS.

## Snippets worth keeping

When a snippet proves reusable in real work (used twice, or praised by the
user), keep it with the user's other references rather than rebuilding it.
Criteria: self-contained, copy-pasteable without chasing dependencies, and
working with the toggle because it uses the tokens.

## Checks before handing over a page

- Switch the toggle both ways and look at the result in each theme.
- Search the source for hex values outside the token blocks. Each one is a
  hole in one theme.
- Narrow the window to phone width. Nothing should scroll sideways.
- Text wraps. No ellipsis on prose or labels.
