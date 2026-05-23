---
brief: JS inside server-side backtick template literals needs DOUBLE escapes; `node --check` won't catch it; verify in a real browser
triggers:
  - topic:template-literals
  - topic:server-side-rendering
  - phrase:"renderPage"
  - phrase:"backtick"
  - phrase:"inline script"
related:
  - rules/testing.md
tier: 2
category: rules
updated: 2026-05-15
stale_after_days: 90
---

# JS escape sequences inside server-side template literals

When emitting JavaScript from inside a backtick template literal (e.g. a Node `renderPage()` returning HTML with an inline `<script>`), every escape sequence in the JS source is consumed by the **server-side template** before the browser ever sees it.

Graduated from atone slug `js-escape-sequences-inside-server-side-template-literals` (S3, broke pm2-manage page interactions 2026-05-01, recurred minutes later same session).

## What happens

```javascript
// In Node:
function renderPage() {
  return `
    <script>
      const k = '\n';            // ← server-side template consumes the \n
      el.value = 'Enter';        // ← server-side template consumes the \'
    </script>
  `;
}
```

After server-side template substitution, the browser sees:
```javascript
const k = '         <-- literal newline, unterminated string → SyntaxError
';
el.value = 'Enter';   <-- the quotes don't match anymore
```

One SyntaxError kills **every** interactive control on the page — theme toggle, navbar, buttons. Catastrophic from a single line.

## Why `node --check` doesn't catch it

The server-side JS (the template literal *containing* the inline script) is syntactically valid Node — the template is just a string. Only after template substitution does the browser-bound JS become broken. `node --check` never sees the substituted output.

`curl /` + grep also misses this — the HTML looks fine; the bug only surfaces when the JS executes in a browser.

## The rule

When writing JS code that lives inside a backtick template literal:

1. **Double every escape:**
   - `\\n` (renders as `\n` for the browser)
   - `\\'` (renders as `\'`)
   - `\\\\` (renders as `\\`)
   - `\\${` (renders as `\${`)

2. **Better:** extract the emitted JS to a static `.js` file served via `<script src="...">`. Then `node --check` covers it.

3. **Mandatory:** before declaring the page ready, open it in a real browser and click a button. Not curl, not test runner — actual browser interaction.

## Diagnostic signal that this pattern is firing

A user reports "page buttons stopped working" or "console shows SyntaxError on line N" — and the file most recently edited is a renderer with a backtick-string-wrapped `<script>` block.

## Related

- `rules/testing.md` § "UI/frontend verification" — start dev server, exercise in browser
- Atone event: `bash ~/.claude/scripts/atone.sh search js-escape`
